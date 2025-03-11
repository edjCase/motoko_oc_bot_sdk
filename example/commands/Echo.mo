import Sdk "../../src";
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
                    multiLine = false;
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
