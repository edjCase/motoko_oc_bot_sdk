import Types "./Types";
import OpenChatApi "OpenChatApi";
import Principal "mo:base/Principal";

module {

    public class CommandExecutionContext(action_ : Types.BotActionByCommand, jwt_ : Text, apiKey_ : ?Text) {
        public let action = action_;
        public let jwt = jwt_;
        public var apiKey = apiKey_;

        public func getMessageIdOrNull() : ?Types.MessageId {
            switch (action.scope) {
                case (#chat(chatDetails)) ?chatDetails.messageId;
                case (#community(_)) null;
            };
        };

        public func getBotApiActor() : OpenChatApi.BotApiActor = actor (Principal.toText(action.botApiGateway)) : OpenChatApi.BotApiActor;

    };

};
