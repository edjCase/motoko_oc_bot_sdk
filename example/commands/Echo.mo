import Sdk "../../src";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Int "mo:base/Int";

module {

    private type EchoArgs = {
        message : Text;
        repeat : Nat;
    };

    public func execute(messageId : ?Sdk.MessageId, args : [Sdk.CommandArg]) : async* Sdk.CommandResponse {
        let echoArgs = switch (parseMessage(args)) {
            case (#ok(message)) message;
            case (#err(response)) return response;
        };

        let messageOrNull : ?Sdk.Message = switch (messageId) {
            case (?id) {
                // TODO
                var message = echoArgs.message;
                if (echoArgs.repeat > 0) {
                    for (i in Iter.range(1, echoArgs.repeat)) {
                        message #= " " # echoArgs.message;
                    };
                };
                ?{
                    id = id;
                    content = #text({
                        text = "Echo: " # message;
                    });
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
