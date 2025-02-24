import HTTP "./HTTP";
import Types "./Types";

module {
    public type BotSchema = Types.BotSchema;
    public type BotAction = Types.BotAction;
    public type BotActionByCommand = Types.BotActionByCommand;
    public type BotActionByApiKey = Types.BotActionByApiKey;
    public type CommandResponse = Types.CommandResponse;
    public type MessageId = Types.MessageId;
    public type Message = Types.Message;
    public type CommandArg = Types.CommandArg;
    public type SlashCommand = Types.SlashCommand;

    public type HttpHandler = HTTP.HttpHandler;
    public func HttpHandler(
        botSchema : BotSchema,
        execute : BotAction -> async* CommandResponse,
        openChatPublicKey : Blob,
    ) : HttpHandler = HTTP.HttpHandler(
        botSchema,
        execute,
        openChatPublicKey,
    );

};
