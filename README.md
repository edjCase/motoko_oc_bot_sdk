# Overview

This is a library that allows easy development of OpenChat's bot API

NOTE: This is in early development and not all features are supported

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
```

## commands/Echo.mo

```motoko
import Sdk "../../src";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Error "mo:base/Error";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Timer "mo:base/Timer";

module {

    private type EchoArgs = {
        message : Text;
        repeat : Nat;
    };

    public func execute<system>(
        context : Sdk.CommandExecutionContext
    ) : async* Sdk.CommandResponse {
        let echoArgs = switch (parseMessage(context.action.command.args)) {
            case (#ok(message)) message;
            case (#err(response)) return response;
        };

        let ?messageId = context.getMessageIdOrNull() else return #success({
            message = null;
        });
        if (echoArgs.repeat > 0) {
            // Echo X MORE times, once every 10 seconds
            let secondOffset = 10;
            for (i in Iter.range(1, echoArgs.repeat)) {
                ignore Timer.setTimer<system>(
                    #seconds(secondOffset * i),
                    func() : async () {
                        Debug.print("Echoing message: " # Nat.toText(messageId) # ", Text: " # echoArgs.message);
                        let ?apiKey = context.apiKey else {
                            Debug.print("Error: Missing API key, make sure to sync it first");
                            return;
                        };
                        try {
                            let botApiActor = context.getBotApiActor();
                            let result = await botApiActor.bot_send_message({
                                channel_id = null;
                                message_id = ?Nat64.fromNat(messageId);
                                content = #Text({
                                    text = "Echo: " # echoArgs.message # " (" # Nat.toText(i) # ")";
                                });
                                block_level_markdown = false;
                                finalised = i == echoArgs.repeat;
                                auth_token = #ApiKey(apiKey);
                            });
                            Debug.print("Result: " # debug_show (result));
                        } catch (error) {
                            Debug.print("Error: " # Error.message(error));
                        };
                    },
                );
            };
        };
        #success({
            message = ?{
                id = messageId;
                content = #text({
                    text = "Echo: " # echoArgs.message;
                });
                blockLevelMarkdown = false;
                ephemeral = false;
                finalised = false;
            };
        });
    };

    public func getSchema() : Sdk.SlashCommand {
        {
            name = "echo";
            placeholder = null;
            description = "Echo a message";
            params = [
                {
                    name = "message";
                    description = "Message to echo";
                    placeholder = null;
                    required = true;
                    paramType = #stringParam({
                        choices = [];
                        minLength = 1;
                        maxLength = 100;
                        multiLine = true;
                    });
                },
                {
                    name = "repeat";
                    description = "Echo X MORE times, once every 10 seconds";
                    placeholder = null;
                    required = false;
                    paramType = #integerParam({
                        choices = [];
                        minValue = 0;
                        maxValue = 20;
                    });
                },
            ];
            permissions = {
                community = [];
                chat = [];
                message = [#text];
            };
        };
    };

    private func parseMessage(args : [Sdk.CommandArg]) : Result.Result<EchoArgs, Sdk.CommandResponse> {
        if (args.size() < 1 or args.size() > 2) {
            Debug.print("Invalid request: Wrong number of arguments");
            return #err(#badRequest(#argsInvalid));
        };
        let ?messageArg = getArgOrNull(args, "message") else {
            Debug.print("Invalid request: Missing message argument");
            return #err(#badRequest(#argsInvalid));
        };

        let #string(message) = messageArg.value else {
            Debug.print("Invalid request: Message argument must be a string");
            return #err(#badRequest(#argsInvalid));
        };

        let repeatArgs = switch (getArgOrNull(args, "repeat")) {
            case (?arg) {
                let #integer(repeat) = arg.value else {
                    Debug.print("Invalid request: Repeat argument must be a integer");
                    return #err(#badRequest(#argsInvalid));
                };
                Int.abs(repeat);
            };
            case (_) 0;
        };
        #ok({
            message = message;
            repeat = repeatArgs;
        });
    };

    private func getArgOrNull(args : [Sdk.CommandArg], name : Text) : ?Sdk.CommandArg {
        Array.find(args, func(arg : Sdk.CommandArg) : Bool = arg.name == name);
    };
};


```

# Testing

```
mops test
```
