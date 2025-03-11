import Types "./Types";
import Principal "mo:base/Principal";

module {
    public class Client(botApiGateway : Principal, authToken : Types.AuthToken) {
        let botApiActor = actor (Principal.toText(botApiGateway)) : Types.BotApiGatewayActor;

        public func sendMessage(message : Types.MessageContent) : async* Types.SendMessageResponse {
            // TODO
            await botApiActor.bot_send_message({
                channelId = null;
                messageId = null;
                content = message;
                blockLevelMarkdown = false;
                finalized = true;
                authToken = authToken;
            });
        };
    };
};
