import HttpTypes "mo:http-types";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Json "mo:json";
import Base64 "mo:base64";
import SdkTypes "./types";
import SdkSerializer "./serializer";

module {

    public class HttpHandler(
        botSchema : SdkTypes.BotSchema,
        execute : SdkTypes.BotAction -> async* SdkTypes.CommandResponse,
    ) {

        public func http_request(request : HttpTypes.Request) : HttpTypes.Response {
            if (request.method == "GET") {
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
            // Not found catch all
            getNotFoundResponse();
        };

        public func http_request_update(request : HttpTypes.UpdateRequest) : async* HttpTypes.UpdateResponse {

            if (request.method == "POST") {
                // TODO query string (use path not url)
                if (request.url == "/execute_command") {

                    let commandResponse = await* parseAndExecuteAction(request.body);

                    let (statusCode, response) : (Nat16, Json.Json) = switch (commandResponse) {
                        case (#success(success)) (200, SdkSerializer.serializeSuccess(success));
                        case (#badRequest(badRequest)) (400, SdkSerializer.serializeBadRequest(badRequest));
                        case (#internalError(error)) (500, SdkSerializer.serializeInternalError(error));
                    };
                    Debug.print("Response: " # debug_show (response));
                    let jsonBytes = Text.encodeUtf8(Json.stringify(response, null));
                    return {
                        status_code = statusCode;
                        headers = [("Content-Type", "application/json")];
                        body = jsonBytes;
                        streaming_strategy = null;
                        upgrade = null;
                    };
                };
            };

            // Not found catch all
            getNotFoundResponse();
        };

        private func parseAndExecuteAction(body : Blob) : async* SdkTypes.CommandResponse {
            let jwtData : JwtData = switch (verifyJwt(body)) {
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

        private func verifyJwt(body : Blob) : Result.Result<JwtData, VerifyJwtError> {

            let ?jwt = Text.decodeUtf8(body) else return #err(#parseError("Unable to decode body as UTF-8"));

            // Split JWT into parts
            let parts = Text.split(jwt, #char('.')) |> Iter.toArray(_);

            if (parts.size() != 3) {
                return #err(#jwtNotFound);
            };

            // TODO
            // let headerJson = parts[0];
            let claimsJson = parts[1];
            // let signatureStr = parts[2];

            // // Decode base64url signature to bytes
            let base64UrlEngine = Base64.Base64(#v(Base64.V2), ?true);
            // let signatureBytes = base64UrlEngine.decode(signatureStr); // TODO handle error

            // // Create message to verify (header + "." + claims)
            // let message = Text.concat(headerJson, Text.concat(".", claimsJson));
            // let messageBytes = Blob.toArray(Text.encodeUtf8(message));

            // // Parse PEM public key and verify signature
            // let #ok = await* ECDSA.verify({
            //     publicKey = publicKeyPem;
            //     message = messageBytes;
            //     signature = signatureBytes;
            //     algorithm = #P256;
            // }) else return return #err("Signature verification failed");

            // Decode and parse claims
            let claimsBytes = base64UrlEngine.decode(claimsJson); // TODO handle error
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
