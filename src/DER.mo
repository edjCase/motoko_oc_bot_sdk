import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Base64 "mo:base64";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";

module {

    public type AlgorithmIdentifier = {
        oid : Text; // Main algorithm OID (e.g. "1.3.132.0.10")
        parameters : ?Text; // Optional parameters OID
    };

    public type DerPublicKey = {
        key : [Nat8]; // The actual public key bytes
        algorithm : AlgorithmIdentifier;
    };

    public func parsePublicKey(key : Text) : ?DerPublicKey {
        Debug.print("Processing PEM format");

        // First normalize line endings
        let normalizedKey = Text.replace(key, #text("\r\n"), "\n");

        // Split and clean more carefully
        let lines = Iter.toArray(
            Iter.filter(
                Text.split(normalizedKey, #text("\n")),
                func(line : Text) : Bool {
                    let trimmed = Text.trim(line, #char(' '));
                    trimmed.size() > 0 and not Text.startsWith(trimmed, #text("-----"));
                },
            )
        );

        let derText = Text.join("", lines.vals());
        Debug.print("Extracted DER text length: " # Nat.toText(derText.size()));

        // Add debug output to check base64 content
        if (derText.size() == 0) {
            Debug.print("❌ Error: Empty DER text after processing");
            return null;
        };

        // Continue with DER parsing...
        parseDERPublicKey(derText);
    };

    /// Parse DER length field, returns (length, number of bytes used)
    private func parseDerLength(bytes : Iter.Iter<Nat8>) : ?Nat {

        let ?first = bytes.next() else {
            Debug.print("❌ Error: Failed to read first byte");
            return null;
        };
        Debug.print("First byte: " # Nat8.toText(first));

        if (first < 0x80) {
            // Short form
            Debug.print("✓ Short form length: " # Nat8.toText(first));
            return ?Nat8.toNat(first);
        };

        // Long form
        let numBytes = Nat8.toNat(first & 0x7F);
        Debug.print("Long form, number of length bytes: " # Nat.toText(numBytes));

        var length = 0;
        for (i in Iter.range(0, numBytes - 1)) {
            let ?byte = bytes.next() else {
                Debug.print("❌ Error: Failed to read length byte");
                return null;
            };
            length := length * 256 + Nat8.toNat(byte);
        };
        Debug.print("✓ Parsed long form length: " # Nat.toText(length));

        ?length;
    };

    private func decodeOid(bytes : Iter.Iter<Nat8>, checkType : Bool) : ?Text {
        if (checkType) {
            // Parse algorithm OID
            let ?oidTag = bytes.next() else return null;
            if (oidTag != 0x06) {
                // Changed from 0x30 to 0x06 for OID tag
                Debug.print("❌ Error: Invalid OID tag: " # debug_show (oidTag));
                return null;
            };
        };

        let ?oidLength = parseDerLength(bytes) else {
            Debug.print("❌ Error: Failed to parse algorithm OID length");
            return null;
        };

        let ?first = bytes.next() else return null;
        let components = Buffer.Buffer<Text>(6);
        // First two components are derived from the first byte
        components.add(Nat.toText(Nat8.toNat(first) / 40));
        components.add(Nat.toText(Nat8.toNat(first) % 40));

        var value : Nat = 0;
        var bytesRead = 1;

        while (bytesRead < oidLength) {
            let ?byte = bytes.next() else {
                Debug.print("❌ Error: Unexpected end of OID data");
                return null;
            };
            bytesRead += 1;

            if (byte >= 0x80) {
                // This is a continuation byte
                value := value * 128 + Nat8.toNat(byte & 0x7F);
            } else {
                // This is the last byte of this component
                value := value * 128 + Nat8.toNat(byte);
                components.add(Nat.toText(value));
                value := 0;
            };
        };

        ?Text.join(".", components.vals());
    };

    /// Helper function to parse DER encoded public key
    private func parseDERPublicKey(derText : Text) : ?DerPublicKey {
        Debug.print("Parsing DER encoded public key: " # derText);

        let base64Engine = Base64.Base64(#v(Base64.V2), ?true);
        let bytesArray = base64Engine.decode(derText);
        let bytes = bytesArray.vals();

        // Parse outer SEQUENCE
        let ?outerSeqTag = bytes.next() else return null;
        if (outerSeqTag != 0x30) {
            Debug.print("❌ Error: Invalid outer SEQUENCE tag: " # Nat8.toText(outerSeqTag));
            return null;
        };
        let ?_outerSeqLength = parseDerLength(bytes) else {
            Debug.print("❌ Error: Failed to parse outer SEQUENCE");
            return null;
        };
        let ?innerSeqTag = bytes.next() else return null;
        if (innerSeqTag != 0x30) {
            Debug.print("❌ Error: Invalid inner SEQUENCE tag: " # Nat8.toText(innerSeqTag));
            return null;
        };
        let ?_innerSeqLength = parseDerLength(bytes) else {
            Debug.print("❌ Error: Failed to parse inner SEQUENCE");
            return null;
        };
        let ?oid = decodeOid(bytes, true) else return null;
        let ?nextType = bytes.next() else return null;
        let (parametersOid, nextTypeOrNull) = switch (nextType) {
            case (0x06) {
                Debug.print("Found optional parameters OID");
                let ?pOid = decodeOid(bytes, false) else return null;
                (?pOid, bytes.next());
            };
            case (_) (null, ?nextType);
        };
        Debug.print("OID: " # oid);
        Debug.print("Parameters OID: " # Option.get(parametersOid, ""));
        Debug.print("✓ Parsed outer SEQUENCE");
        // Parse BIT STRING
        let ?pkTag = nextTypeOrNull else return null;
        if (pkTag != 0x03) {
            Debug.print("❌ Error: Invalid BIT STRING tag:" # debug_show (pkTag));
            return null;
        };
        let ?_pkLength = parseDerLength(bytes) else {
            Debug.print("❌ Error: Failed to parse BIT STRING");
            return null;
        };

        let keyBytes = bytes |> Iter.toArray(_); // Get rest of the bytes
        Debug.print("✓ Parsed key bytes, length: " # Nat.toText(keyBytes.size()));

        ?{
            key = keyBytes;
            algorithm = {
                oid = oid;
                parameters = parametersOid;
            };
        };
    };
};
