import HttpTypes "mo:http-types";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Option "mo:base/Option";
import Json "mo:json";
import Base64 "mo:base64";
import SdkTypes "./Types";
import SdkSerializer "./Serializer";
import SdkDER "./DER";
import ECDSA "mo:ecdsa";
import Curve "mo:ecdsa/curve";

module {

    public class HttpHandler(
        botSchema : SdkTypes.BotSchema,
        execute : SdkTypes.BotAction -> async* SdkTypes.CommandResponse,
        // getBotMetrics : () -> [(Text, Json.Json)],
        // getBlobData : Text -> ?BlobData.BlobData,
        openChatPublicKey : Blob,
    ) {
        let base64Engine = Base64.Base64(#v(Base64.V2), ?true);

        public func http_request(request : HttpTypes.Request) : HttpTypes.Response {

            if (request.method == "POST") {
                // Upgrade request on POST
                return {
                    status_code = 200;
                    headers = [];
                    body = Blob.fromArray([]);
                    streaming_strategy = null;
                    upgrade = ?true;
                };
            };

            if (request.method == "GET") {
                if (request.url == "/metrics") return getMetrics();
                let blobIdOrNull = Text.stripStart(request.url, #text("/blobs/"));
                switch (blobIdOrNull) {
                    case (?blobId) return getBlob(blobId);
                    case (_) ();
                };
                let webhookIdOrNull = Text.stripStart(request.url, #text("/webhook/"));
                switch (webhookIdOrNull) {
                    case (?webhookId) return executeWebhook(webhookId);
                    case (_) ();
                };
                return getDescription();
            };
            // Not found catch all
            getNotFoundResponse();
        };

        public func http_request_update(request : HttpTypes.UpdateRequest) : async* HttpTypes.UpdateResponse {

            if (request.method == "POST") {
                // TODO query string (use path not url)
                if (request.url == "/execute_command") {
                    return await* executeCommand(request);
                };
            };

            // Not found catch all
            getNotFoundResponse();
        };

        private func executeWebhook(_webhookId : Text) : HttpTypes.Response {
            Debug.trap("Webhooks are not implemented yet");
        };

        private func executeCommand(request : HttpTypes.UpdateRequest) : async* HttpTypes.UpdateResponse {
            let (statusCode, response) : (Nat16, Json.Json) = try {
                let commandResponse = await* parseAndExecuteAction(request.body);
                switch (commandResponse) {
                    case (#success(success)) (200, SdkSerializer.serializeSuccess(success));
                    case (#badRequest(badRequest)) (400, SdkSerializer.serializeBadRequest(badRequest));
                    case (#internalError(error)) (500, SdkSerializer.serializeInternalError(error));
                };
            } catch (e) {
                (500, SdkSerializer.serializeInternalError(#invalid("Internal error: " # Error.message(e))));
            };

            let jsonBytes = Text.encodeUtf8(Json.stringify(response, null));
            return {
                status_code = statusCode;
                headers = [("Content-Type", "application/json")];
                body = jsonBytes;
                streaming_strategy = null;
                upgrade = null;
            };
        };

        private func getMetrics() : HttpTypes.Response {
            Debug.trap("Get metrics is not implemented yet");
            // let metrics = getBotMetrics();
            // let jsonBytes = Text.encodeUtf8(Json.stringify(#object_(metrics), null));
            // return {
            //     status_code = 200;
            //     headers = [("Content-Type", "application/json")];
            //     body = jsonBytes;
            //     streaming_strategy = null;
            //     upgrade = null;
            // };

        };

        private func getBlob(_blobId : Text) : HttpTypes.Response {
            Debug.trap("Get blob is not implemented yet");
            // let ?blob = getBlobData(blobId) else return getNotFoundResponse();
            // return {
            //     status_code = 200;
            //     headers = [("Content-Type", blob.mimeType)];
            //     body = blob.data;
            //     streaming_strategy = null;
            //     upgrade = null;
            // };
        };

        private func getDescription() : HttpTypes.Response {
            let jsonObj = SdkSerializer.serializeBotSchema(botSchema);
            let jsonBytes = Text.encodeUtf8(Json.stringify(jsonObj, null));
            return {
                status_code = 200;
                headers = [("Content-Type", "application/json")];
                body = jsonBytes;
                streaming_strategy = null;
                upgrade = null;
            };
        };

        private func parseAndExecuteAction(body : Blob) : async* SdkTypes.CommandResponse {
            let jwtData : JwtData = switch (verifyJwt(body, openChatPublicKey)) {
                case (#ok(result)) result;
                case (#err(#expired(_))) return #badRequest(#accessTokenExpired);
                case (#err(#invalidSignature)) return #badRequest(#accessTokenInvalid);
                case (#err(#jwtNotFound)) return #badRequest(#accessTokenNotFound);
                case (#err(#parseError(parseError))) {
                    Debug.print("Failed to parse JWT: " # parseError);
                    return #badRequest(#accessTokenInvalid);
                };
            };
            let action : SdkTypes.BotAction = switch (jwtData.claimType) {
                case ("BotActionByCommand") switch (SdkSerializer.deserializeBotActionByCommand(jwtData.data)) {
                    case (#ok(action)) #command(action);
                    case (#err(e)) return #internalError(#invalid("Failed to deserialize BotActionByCommand: " # e));
                };
                case ("BotActionByApiKey") switch (SdkSerializer.deserializeBotActionByApiKey(jwtData.data)) {
                    case (#ok(action)) #apiKey(action);
                    case (#err(e)) return #internalError(#invalid("Failed to deserialize BotActionByApiKey: " # e));
                };
                case (c) return #internalError(#invalid("Invalid 'claim_type' field in claims: " # c));
            };
            await* execute(action);
        };

        private type JwtData = {
            claimType : Text;
            expiry : Time.Time;
            data : Json.Json;
        };

        private type VerifyJwtError = {
            #parseError : Text;
            #expired : Time.Time;
            #invalidSignature;
            #jwtNotFound;
        };

        private func verifyJwt(body : Blob, publicKeyBytes : Blob) : Result.Result<JwtData, VerifyJwtError> {

            let ?jwt = Text.decodeUtf8(body) else return #err(#parseError("Unable to decode body as UTF-8"));

            // Split JWT into parts
            let parts = Text.split(jwt, #char('.')) |> Iter.toArray(_);

            if (parts.size() != 3) {
                return #err(#jwtNotFound);
            };

            let headerJson = parts[0];
            let claimsJson = parts[1];
            let signatureStr = parts[2];

            // Decode base64url signature to bytes
            let signatureBytes = Blob.fromArray(base64Engine.decode(signatureStr)); // TODO handle error

            // Create message to verify (header + "." + claims)
            let message = Text.concat(headerJson, Text.concat(".", claimsJson));
            let messageBytes = Blob.toArray(Text.encodeUtf8(message));

            let ?publicKeyText = Text.decodeUtf8(publicKeyBytes) else return #err(#parseError("Unable to decode public key as UTF-8"));
            let ?derPublicKey = SdkDER.parsePublicKey(publicKeyText) else return #err(#parseError("Failed to parse public key"));
            if (derPublicKey.algorithm.oid != "1.2.840.10045.2.1") {
                return #err(#parseError("Invalid public key algorithm OID: " # derPublicKey.algorithm.oid));
            };
            if (derPublicKey.algorithm.parameters != ?"1.2.840.10045.3.1.7") {
                return #err(#parseError("Invalid public key algorithm parameters OID: " # Option.get(derPublicKey.algorithm.parameters, "")));
            };

            let curve = Curve.Curve(#prime256v1);
            let ?publicKey = ECDSA.deserializePublicKeyUncompressed(curve, Blob.fromArray(derPublicKey.key)) else {
                Debug.print("Failed to deserialize public key: " # debug_show (derPublicKey.key));
                Debug.trap("Failed to deserialize public key");
            };
            let ?signature = ECDSA.deserializeSignatureRaw(signatureBytes) else return #err(#invalidSignature);
            let normalizedSig = ECDSA.normalizeSignature(curve, signature);
            Debug.print("Normalized signature: " # debug_show (normalizedSig));
            let true = ECDSA.verify(curve, publicKey, messageBytes.vals(), normalizedSig) else return #err(#invalidSignature);
            Debug.print("Signature verified");

            // Decode and parse claims
            let claimsBytes = base64Engine.decode(claimsJson); // TODO handle error
            let ?claimsText = Text.decodeUtf8(Blob.fromArray(claimsBytes)) else return #err(#parseError("Unable to parse claims"));
            switch (Json.parse(claimsText)) {
                case (#err(e)) return #err(#parseError("Invalid claims JSON: " # debug_show (e)));
                case (#ok(claims)) {
                    let expiryTimestamp = switch (Json.getAsInt(claims, "exp")) {
                        case (#ok(expInt)) expInt * 1_000_000_000; // seconds to nanoseconds
                        case (#err(e)) return #err(#parseError("Invalid 'exp' field in claims: " # debug_show (e)));
                    };
                    if (expiryTimestamp < Time.now()) {
                        return #err(#expired(expiryTimestamp));
                    };

                    let claimType = switch (Json.getAsText(claims, "claim_type")) {
                        case (#ok(claimTypeText)) claimTypeText;
                        case (#err(e)) return #err(#parseError("Invalid 'claim_type' field in claims: " # debug_show (e)));
                    };
                    #ok({
                        claimType = claimType;
                        expiry = expiryTimestamp;
                        data = claims;
                    })

                };
            };
        };

        private func getNotFoundResponse() : HttpTypes.Response {
            {
                status_code = 404;
                headers = [];
                body = Blob.fromArray([]);
                streaming_strategy = null;
                upgrade = null;
            };
        };
    };

};
