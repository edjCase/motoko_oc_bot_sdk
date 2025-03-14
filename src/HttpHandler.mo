import HttpTypes "mo:http-types";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Iter "mo:new-base/Iter";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Option "mo:base/Option";
import Array "mo:base/Array";
import List "mo:new-base/List";
import Json "mo:json";
import Base64 "mo:base64";
import SdkTypes "./Types";
import SdkSerializer "./Serializer";
import SdkDER "./DER";
import ECDSA "mo:ecdsa";
import Curve "mo:ecdsa/curve";
import ExecutionContext "./ExecutionContext";

module {

    public type Events = {
        onCommandAction : ?(ExecutionContext.CommandExecutionContext -> async* SdkTypes.CommandResponse);
        onApiKeyAction : ?(ExecutionContext.ApiKeyExecutionContext -> async* SdkTypes.CommandResponse);
    };

    public type StableData = {
        apiKeys : [Text];
    };

    public class HttpHandler(
        apiKeys_ : [Text],
        botSchema : SdkTypes.BotSchema,
        openChatPublicKey : Blob,
        events : Events,
    ) {
        let base64Engine = Base64.Base64(#v(Base64.V2), ?true);

        private func parseApiKeyContext(value : Text) : Result.Result<SdkTypes.ApiKeyContext, Text> {
            let apiKeyBytes = base64Engine.decode(value);
            let ?apiKeyText = Text.decodeUtf8(Blob.fromArray(apiKeyBytes)) else return #err("Failed to decode api key as UTF-8");
            let apiKeyJson = switch (Json.parse(apiKeyText)) {
                case (#ok(json)) json;
                case (#err(e)) return #err("Failed to parse api key json: " # debug_show (e));
            };
            SdkSerializer.deserializeRawApiKey(apiKeyJson, value);
        };

        let apiKeys = apiKeys_.values()
        |> Iter.map(
            _,
            func(apiKey : Text) : SdkTypes.ApiKeyContext = switch (parseApiKeyContext(apiKey)) {
                case (#ok(apiKeyContext)) apiKeyContext;
                case (#err(e)) Debug.trap("Failed to parse api key: " # e);
            },
        )
        |> List.fromIter<SdkTypes.ApiKeyContext>(_);

        public func toStableData() : StableData {
            {
                apiKeys = apiKeys
                |> List.filterMap<SdkTypes.ApiKeyContext, Text>(
                    _,
                    func(apiKey : SdkTypes.ApiKeyContext) : ?Text = switch (apiKey.token) {
                        case (#jwt(_)) null;
                        case (#apiKey(apiKey)) ?apiKey;
                    },
                )
                |> List.toArray(_);
            };
        };

        public func http_request(_ : HttpTypes.Request) : HttpTypes.Response {
            // TODO cache certified description
            return {
                status_code = 200;
                headers = [];
                body = Blob.fromArray([]);
                streaming_strategy = null;
                upgrade = ?true;
            };
        };

        public func http_request_update(request : HttpTypes.UpdateRequest) : async* HttpTypes.UpdateResponse {

            // TODO query string (use path not url)
            if (request.url == "/execute_command") {
                return await* executeCommand(request);
            };

            getDescription();
        };

        private func executeCommand(request : HttpTypes.UpdateRequest) : async* HttpTypes.UpdateResponse {
            let (statusCode, response) : (Nat16, Json.Json) = try {
                let commandResponse = await* parseAndExecuteAction(request);
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

        private func parseAndExecuteAction(request : HttpTypes.UpdateRequest) : async* SdkTypes.CommandResponse {
            let ?(_, jwt) = Array.find(request.headers, func(header : (Text, Text)) : Bool = "x-oc-jwt" == header.0) else return #badRequest(#accessTokenNotFound);
            let jwtData : JwtData = switch (verifyJwt(jwt, openChatPublicKey)) {
                case (#ok(result)) result;
                case (#err(#expired(_))) return #badRequest(#accessTokenExpired);
                case (#err(#invalidSignature)) {
                    Debug.print("Invalid signature in JWT");
                    return #badRequest(#accessTokenInvalid);
                };
                case (#err(#jwtNotFound)) return #badRequest(#accessTokenNotFound);
                case (#err(#parseError(parseError))) {
                    Debug.print("Failed to parse JWT: " # parseError);
                    return #badRequest(#accessTokenInvalid);
                };
            };
            switch (jwtData.claimType) {
                case ("BotActionByCommand") switch (SdkSerializer.deserializeJwtCommand(jwtData.data, jwt)) {
                    case (#ok(context)) {
                        // Handle sync API key command, if event handler is set, otherwise let it call onCommandAction
                        if (context.command.name == "sync_api_key") {
                            if (context.command.args.size() < 1) return #badRequest(#argsInvalid);
                            let #string(value) = context.command.args[0].value else return #badRequest(#argsInvalid);

                            let apiKeyContext = switch (parseApiKeyContext(value)) {
                                case (#ok(apiKeyContext)) apiKeyContext;
                                case (#err(e)) {
                                    Debug.print("Failed to parse api key: " # e);
                                    return #badRequest(#argsInvalid);
                                };
                            };
                            addOrUpdateApiKey(apiKeyContext);
                            return #success({ message = null });
                        };
                        let ?handler = events.onCommandAction else return #badRequest(#commandNotFound);
                        let executionContext = ExecutionContext.CommandExecutionContext(context, getApiKeyByScope);
                        await* handler(executionContext);
                    };
                    case (#err(e)) return #internalError(#invalid("Failed to deserialize BotActionByCommand: " # e));
                };
                case ("BotActionByApiKey") switch (SdkSerializer.deserializeJwtApiKey(jwtData.data, jwt)) {
                    case (#ok(context)) {
                        let ?handler = events.onApiKeyAction else return #badRequest(#commandNotFound);
                        let executionContext = ExecutionContext.ApiKeyExecutionContext(context);
                        await* handler(executionContext);
                    };
                    case (#err(e)) return #internalError(#invalid("Failed to deserialize BotActionByApiKey: " # e));
                };
                case (c) return #internalError(#invalid("Invalid 'claim_type' field in claims: " # c));
            };
        };

        private func getApiKeyIndexByScope(scope : SdkTypes.ApiKeyScope) : ?Nat {
            List.firstIndexWhere(
                apiKeys,
                func(apiKey : SdkTypes.ApiKeyContext) : Bool = apiKey.scope == scope,
            );
        };

        private func getApiKeyByScope(scope : SdkTypes.ApiKeyScope) : ?SdkTypes.ApiKeyContext {
            let ?currentScopeIndex = getApiKeyIndexByScope(scope) else return null;
            List.getOpt(apiKeys, currentScopeIndex);
        };

        private func addOrUpdateApiKey(apiKeyContext : SdkTypes.ApiKeyContext) {
            let currentScopeIndex = getApiKeyIndexByScope(apiKeyContext.scope);
            switch (currentScopeIndex) {
                case (?i) List.put(apiKeys, i, apiKeyContext);
                case (null) List.add(apiKeys, apiKeyContext);
            };
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

        private func verifyJwt(jwt : Text, publicKeyBytes : Blob) : Result.Result<JwtData, VerifyJwtError> {

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
            let true = ECDSA.verify(curve, publicKey, messageBytes.vals(), normalizedSig) else return #err(#invalidSignature);

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
    };

};
