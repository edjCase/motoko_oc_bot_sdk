# Overview

This is a library that allows easy development of OpenChat's bot API

NOTE: This is in early development and only supports commands, not api key calls yet

# Package

### MOPS

```
mops install openchat-bot-sdk
```

To setup MOPS package manage, follow the instructions from the [MOPS Site](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/)

# Example - Echo

Simple example that prompts for some text, then the bot returns that same text

## main.mo

```motoko
import Echo "./commands/Echo";
import Sdk "mo:openchat-bot-sdk";
import Text "mo:base/Text";

actor {
    // Update this based on your open chat instance public key
    let openChatPublicKey = Text.encodeUtf8("MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE5GaOVUjuWn59a8Bp79694D5KClL77iirARZNAzxLY2U4HYcEbU+PtOfM8/00Ovo+2uSbFhsCQPw+ijM3pf6OOQ==");

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
```

## commands/Echo.mo

```motoko
import Sdk "mo:openchat-bot-sdk";
import Debug "mo:base/Debug";
import Result "mo:base/Result";

module {

    public func execute(messageId : ?Sdk.MessageId, args : [Sdk.CommandArg]) : async* Sdk.CommandResponse {
        let message = switch (parseMessage(args)) {
            case (#ok(message)) message;
            case (#err(response)) return response;
        };

        let messageOrNull : ?Sdk.Message = switch (messageId) {
            case (?id) ?{
                id = id;
                content = #text({
                    text = "Echo: " # message;
                });
                finalised = true;
            };
            case (_) null;
        };
        #success({
            message = messageOrNull;
        });
    };

    public func getSchema() : Sdk.SlashCommand {
        {
            name = "echo";
            placeholder = null;
            description = "Echo a message";
            params = [{
                name = "message";
                description = "Message to echo";
                placeholder = null;
                required = true;
                paramType = #stringParam({
                    choices = [];
                    minLength = 1;
                    maxLength = 100;
                });
            }];
            permissions = {
                community = [];
                chat = [];
                message = [#text];
            };
        };
    };

    private func parseMessage(args : [Sdk.CommandArg]) : Result.Result<Text, Sdk.CommandResponse> {
        if (args.size() != 1) {
            Debug.print("Invalid request: Only one argument is allowed");
            return #err(#badRequest(#argsInvalid));
        };
        let messageArg = args[0];
        if (messageArg.name != "message") {
            Debug.print("Invalid request: Only message argument is allowed");
            return #err(#badRequest(#argsInvalid));
        };

        let #string(message) = messageArg.value else {
            Debug.print("Invalid request: Message argument must be a string");
            return #err(#badRequest(#argsInvalid));
        };
        #ok(message);
    };
};

```

# Testing

```
mops test
```
