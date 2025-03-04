import Echo "./commands/Echo";
import Sdk "../src";
import Text "mo:base/Text";

actor {
    let openChatPublicKey = Text.encodeUtf8("MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEda9kd+GvW92seQZxd93XhxiRh5/kaBfoMLj92ycLFzaUkbe/RuhKmruuXZgy4GnWb5SACVYT8M4fNG2VMMrcXw==");

    let botSchema : Sdk.BotSchema = {
        description = "Echo Bot";
        commands = [Echo.getSchema()];
        autonomousConfig = ?{
            permissions = ?{
                community = [];
                chat = [];
                message = [#text];
            };
            syncApiKey = false;
        };
    };

    private func execute(action : Sdk.BotAction) : async* Sdk.CommandResponse {
        switch (action) {
            case (#command(commandAction)) await* executeCommandAction(commandAction);
            case (#apiKey(apiKeyAction)) await* executeApiKeyAction(apiKeyAction);
        };
    };

    private func executeCommandAction(action : Sdk.BotActionByCommand) : async* Sdk.CommandResponse {
        let messageId = switch (action.scope) {
            case (#chat(chatDetails)) ?chatDetails.messageId;
            case (#community(_)) null;
        };
        switch (action.command.name) {
            case ("echo") await* Echo.execute(messageId, action.command.args);
            case (_) #badRequest(#commandNotFound);
        };
    };

    private func executeApiKeyAction(action : Sdk.BotActionByApiKey) : async* Sdk.CommandResponse {
        switch (action.scope) {
            case (_) #badRequest(#commandNotFound);
        };
    };

    let handler = Sdk.HttpHandler(botSchema, execute, openChatPublicKey);

    public query func http_request(request : Sdk.HttpRequest) : async Sdk.HttpResponse {
        handler.http_request(request);
    };

    public func http_request_update(request : Sdk.UpdateHttpRequest) : async Sdk.UpdateHttpResponse {
        await* handler.http_request_update(request);
    };
};
