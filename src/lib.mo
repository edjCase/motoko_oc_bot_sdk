import HTTP "./HTTP";
import Types "./Types";
import HttpTypes "mo:http-types";
import ClientModule "./Client";

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
    public type ExecuteContext = Types.ExecuteContext;
    public type AuthToken = Types.AuthToken;

    public type Client = ClientModule.Client;
    public func Client(
        botApiGateway : Principal,
        authToken : AuthToken,
    ) : Client = ClientModule.Client(
        botApiGateway,
        authToken,
    );

    public type HttpHandler = HTTP.HttpHandler;
    public func HttpHandler(
        botSchema : BotSchema,
        execute : ExecuteContext -> async* CommandResponse,
        openChatPublicKey : Blob,
    ) : HttpHandler = HTTP.HttpHandler(
        botSchema,
        execute,
        openChatPublicKey,
    );

};
