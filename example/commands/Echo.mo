import Sdk "../../src";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Timer "mo:base/Timer";
import Nat64 "mo:base/Nat64";

module {

    private type EchoArgs = {
        message : Text;
        repeat : Nat;
    };

    public func execute<system>(
        context : Sdk.CommandExecutionContext
    ) : async* Sdk.CommandResponse {
        let echoArgs = switch (parseMessage(context.command.args)) {
            case (#ok(message)) message;
            case (#err(response)) return response;
        };

        let ?messageId = context.getMessageIdOrNull() else return #internalError(#invalid("Message ID not found in context"));
        // Echo X times, once every 3 seconds
        let secondOffset = 3;
        let apiKeyScope : Sdk.ApiKeyScope = switch (context.scope) {
            case (#chat(chatDetails)) #chat(chatDetails.chat);
            case (#community(community)) #community(community.communityId);
        };

        let ?apiKeyContext = context.getApiKeyByScope(apiKeyScope) else return #badRequest(#accessTokenNotFound); // TODO correct error?
        let authToken = switch (apiKeyContext.token) {
            case (#jwt(jwt)) #Jwt(jwt);
            case (#apiKey(apiKey)) #ApiKey(apiKey);
        };

        for (i in Iter.range(0, echoArgs.repeat - 1)) {
            ignore Timer.setTimer<system>(
                #seconds(secondOffset * i),
                func() : async () {
                    let botApiActor = context.getBotApiActor();
                    await* echoMessage(botApiActor, echoArgs.message, authToken, null);
                    if (i == ((echoArgs.repeat - 1) : Nat)) {
                        await* echoMessage(botApiActor, "Echoing Complete!", authToken, ?messageId);
                    };
                },
            );
        };
        #success({
            message = ?{
                id = messageId;
                content = #text({
                    text = "Echoing " # Nat.toText(echoArgs.repeat) # " times...";
                });
                blockLevelMarkdown = false;
                ephemeral = false;
                finalised = false;
            };
        });
    };

    private func echoMessage(
        botApiActor : Sdk.BotApiActor,
        message : Text,
        authToken : { #Jwt : Text; #ApiKey : Text },
        messageId : ?Sdk.MessageId,
    ) : async* () {
        let error : ?Text = try {
            let result = await botApiActor.bot_send_message({
                channel_id = null;
                message_id = switch (messageId) {
                    case (?id) ?Nat64.fromNat(id);
                    case (_) null;
                };
                content = #Text({
                    text = message;
                });
                block_level_markdown = false;
                finalised = true;
                auth_token = authToken;
            });
            switch (result) {
                case (#Success(_)) null;
                case (error) ?debug_show (error);
            };
        } catch (error) {
            ?Error.message(error);
        };
        switch (error) {
            case (?error) Debug.trap("Error echoing message: " #error);
            case (_) ();
        };
    };

    public func getSchema() : Sdk.SlashCommand {
        {
            name = "echo";
            placeholder = null;
            description = "Echo a message every 3 seconds";
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
                    description = "How many times to echo the message";
                    placeholder = ?"X";
                    required = false;
                    paramType = #integerParam({
                        choices = [];
                        minValue = 1;
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
