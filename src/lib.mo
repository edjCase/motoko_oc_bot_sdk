import HttpHandlerModule "./HttpHandler";
import Types "./Types";
import HttpTypes "mo:http-types";
import OpenChatApi "./OpenChatApi";
import ExecutionContext "ExecutionContext";

module {
    public type HttpRequest = HttpTypes.Request;
    public type HttpResponse = HttpTypes.Response;
    public type UpdateHttpRequest = HttpTypes.UpdateRequest;
    public type UpdateHttpResponse = HttpTypes.UpdateResponse;
    public type BotSchema = Types.BotSchema;
    public type BotAction = Types.BotAction;
    public type BotActionByCommand = Types.BotActionByCommand;
    public type BotActionByApiKey = Types.BotActionByApiKey;
    public type CommandResponse = Types.CommandResponse;
    public type MessageId = Types.MessageId;
    public type Message = Types.Message;
    public type CommandArg = Types.CommandArg;
    public type SlashCommand = Types.SlashCommand;
    public type CommandExecutionContext = ExecutionContext.CommandExecutionContext;
    public type Events = HttpHandlerModule.Events;

    public type BotApiActor = OpenChatApi.BotApiActor;

    public type HttpHandler = HttpHandlerModule.HttpHandler;
    public func HttpHandler(
        botSchema : BotSchema,
        openChatPublicKey : Blob,
        apiKey : ?Text,
        events : HttpHandlerModule.Events,
    ) : HttpHandler = HttpHandlerModule.HttpHandler(
        botSchema,
        openChatPublicKey,
        apiKey,
        events,
    );

};
