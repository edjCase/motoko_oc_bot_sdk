import Types "./Types";
import OpenChatApi "OpenChatApi";
import Principal "mo:base/Principal";

module {

    public class CommandExecutionContext(
        commandContext_ : Types.CommandContext,
        getApiKeyByScope_ : (Types.ApiKeyScope) -> ?Types.ApiKeyContext,
    ) {
        public let token = commandContext_.token;
        public let apiGateway = commandContext_.apiGateway;
        public let botId = commandContext_.botId;
        public let scope = commandContext_.scope;
        public let grantedPermissions = commandContext_.grantedPermissions;
        public let command = commandContext_.command;

        public func getApiKeyByScope(scope : Types.ApiKeyScope) : ?Types.ApiKeyContext = getApiKeyByScope_(scope);

        public func getMessageIdOrNull() : ?Types.MessageId {
            switch (scope) {
                case (#chat(chatDetails)) ?chatDetails.messageId;
                case (#community(_)) null;
            };
        };

        public func getBotApiActor() : OpenChatApi.BotApiActor = getBotApiActorInternal(apiGateway);

    };

    public class ApiKeyExecutionContext(apiKeyContext_ : Types.ApiKeyContext) {
        public let token = apiKeyContext_.token;
        public let apiGateway = apiKeyContext_.apiGateway;
        public let botId = apiKeyContext_.botId;
        public let scope = apiKeyContext_.scope;
        public let grantedPermissions = apiKeyContext_.grantedPermissions;

        public func getBotApiActor() : OpenChatApi.BotApiActor = getBotApiActorInternal(apiGateway);

    };

    private func getBotApiActorInternal(apiGateway : Principal) : OpenChatApi.BotApiActor = actor (Principal.toText(apiGateway)) : OpenChatApi.BotApiActor;

};
