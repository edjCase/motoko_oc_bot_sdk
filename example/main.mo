import Echo "./commands/Echo";
import Sdk "../src";
import Text "mo:base/Text";
import Timer "mo:base/Timer";
import TimerHandler "./TimerHandler";

actor Actor {
    let openChatPublicKey = Text.encodeUtf8("MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE5nMJ1Anpc2OrU6yhIYb0pacJuCAMC6CZVvFrkbc+JRplyWNfYSPWZ2EzdEEWdz9irZWhq0Pn4iG4Jhl8+I2rfA==");

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

    stable let timerIds : [Timer.TimerId] = [];

    let timerHandler = TimerHandler.TimerHandler(timerIds);

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
            case ("echo") await* Echo.execute(messageId, action.command.args, timerHandler);
            case ("sync_api_key") {
                if (action.command.args.size() < 1) return #badRequest(#argsInvalid);
                let #string(value) = action.command.args[0].value else return #badRequest(#argsInvalid);
                apiKey := ?value;
                #success({ message = null });
            };
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
