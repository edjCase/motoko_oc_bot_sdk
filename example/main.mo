import Echo "./commands/Echo";
import Sdk "mo:openchat-bot-sdk";
import Text "mo:base/Text";
import { OPEN_CHAT_PUBLIC_KEY } "mo:env";

actor Actor {

    let botSchema = {
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
    let openChatPublicKey = Text.encodeUtf8(OPEN_CHAT_PUBLIC_KEY);

    stable var apiKeys : [Text] = [];

    private func executeCommandAction(context : Sdk.CommandExecutionContext) : async* Sdk.CommandResponse {
        switch (context.command.name) {
            case ("echo") await* Echo.execute(context);
            case (_) #badRequest(#commandNotFound);
        };
    };

    let events : Sdk.Events = {
        onCommandAction = ?executeCommandAction;
        onApiKeyAction = null;
    };

    var handler = Sdk.HttpHandler(apiKeys, botSchema, openChatPublicKey, events);

    system func preupgrade() {
        let handlerStableData = handler.toStableData();
        apiKeys := handlerStableData.apiKeys;
    };

    system func postupgrade() {
        handler := Sdk.HttpHandler(apiKeys, botSchema, openChatPublicKey, events);
    };

    public query func http_request(request : Sdk.HttpRequest) : async Sdk.HttpResponse {
        handler.http_request(request);
    };

    public func http_request_update(request : Sdk.UpdateHttpRequest) : async Sdk.UpdateHttpResponse {
        await* handler.http_request_update(request);
    };

};
