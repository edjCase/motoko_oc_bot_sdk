import Echo "./commands/Echo";
import Sdk "../src";
import Text "mo:base/Text";

actor Actor {
    let openChatPublicKey = Text.encodeUtf8("MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEVbUGV60FvFD/lHH9bIfvqXUo7fBqDqKmt/mG64jNpOmVjH/rDn92G2tBrFOpQRIuFeFXZTFWSUIfAeBhyqTmXw==");

    let botSchema : Sdk.BotSchema = {
        description = "Echo Bot";
        commands = [Echo.getSchema()];
        autonomousConfig = ?{
            permissions = ?{
                community = [];
                chat = [];
                message = [#text];
            };
            syncApiKey = true;
        };
    };
    stable var apiKey : ?Text = null;

    private func executeCommandAction(context : Sdk.CommandExecutionContext) : async* Sdk.CommandResponse {
        switch (context.action.command.name) {
            case ("echo") await* Echo.execute(context);
            case (_) #badRequest(#commandNotFound);
        };
    };

    private func syncApiKey(key : Text) {
        apiKey := ?key;
    };

    let events : Sdk.Events = {
        onCommandAction = ?executeCommandAction;
        onSyncApiKey = ?syncApiKey;
    };

    let handler = Sdk.HttpHandler(botSchema, openChatPublicKey, apiKey, events);

    public query func http_request(request : Sdk.HttpRequest) : async Sdk.HttpResponse {
        handler.http_request(request);
    };

    public func http_request_update(request : Sdk.UpdateHttpRequest) : async Sdk.UpdateHttpResponse {
        await* handler.http_request_update(request);
    };
};
