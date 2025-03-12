import Sdk "../../src";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Error "mo:base/Error";
import TimerHandler "../TimerHandler";

module {

    private type EchoArgs = {
        message : Text;
        repeat : Nat;
    };

    public func execute<system>(
        messageId : ?Sdk.MessageId,
        args : [Sdk.CommandArg],
        timerHandler : TimerHandler.TimerHandler,
        ocClient : Sdk.Client,
    ) : async* Sdk.CommandResponse {
        let echoArgs = switch (parseMessage(args)) {
            case (#ok(message)) message;
            case (#err(response)) return response;
        };

        let messageOrNull : ?Sdk.Message = switch (messageId) {
            case (?id) {
                if (echoArgs.repeat > 0) {
                    // Echo X MORE times, once every 10 seconds
                    let secondOffset = 10;
                    for (i in Iter.range(1, echoArgs.repeat)) {
                        timerHandler.addTimer<system>(
                            #seconds(secondOffset * i),
                            func() : async () {
                                Debug.print("Echoing message: " # id # ", Text: " # echoArgs.message);
                                try {
                                    let result = await* ocClient.sendMessage(1, #text({ text = "Echo: " # echoArgs.message }));
                                    Debug.print("Result: " # debug_show (result));
                                } catch (error) {
                                    Debug.print("Error: " # Error.message(error));
                                };
                            },
                        );
                    };
                };
                ?{
                    id = id;
                    content = #text({
                        text = "Echo: " # echoArgs.message;
                    });
                    blockLevelMarkdown = false;
                    ephemeral = false;
                    finalised = true;
                };
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
