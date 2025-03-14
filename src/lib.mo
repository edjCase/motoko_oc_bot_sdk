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
    public type CommandContext = Types.CommandContext;
    public type ApiKeyContext = Types.ApiKeyContext;
    public type CommandResponse = Types.CommandResponse;
    public type MessageId = Types.MessageId;
    public type Message = Types.Message;
    public type CommandArg = Types.CommandArg;
    public type SlashCommand = Types.SlashCommand;
    public type CommandExecutionContext = ExecutionContext.CommandExecutionContext;
    public type Events = HttpHandlerModule.Events;
    public type ApiKeyScope = Types.ApiKeyScope;

    public type BotApiActor = OpenChatApi.BotApiActor;

    public type HttpHandler = HttpHandlerModule.HttpHandler;
    public func HttpHandler(
        apiKeys : [Text],
        botSchema : BotSchema,
        openChatPublicKey : Blob,
        events : HttpHandlerModule.Events,
    ) : HttpHandler = HttpHandlerModule.HttpHandler(
        apiKeys,
        botSchema,
        openChatPublicKey,
        events,
    );

};
