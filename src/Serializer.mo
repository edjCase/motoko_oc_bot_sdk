import Json "mo:json";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Nat32 "mo:base/Nat32";
import SdkTypes "./Types";
import IterTools "mo:itertools/Iter";
import Base64 "mo:base64";

module {

    public func serializeBotSchema(botSchema : SdkTypes.BotSchema) : Json.Json {
        var fields = [
            ("description", #string(botSchema.description)),
            ("commands", serializeArrayOfValues(botSchema.commands, serializeSlashCommand)),
        ];
        switch (botSchema.autonomousConfig) {
            case (null) ();
            case (?config) fields := Array.append(fields, [("autonomous_config", serializeAutonomousConfig(config))]);
        };

        #object_(fields);
    };

    private func serializeAutonomousConfig(config : SdkTypes.AutonomousConfig) : Json.Json {
        var fields : [(Text, Json.Json)] = [
            ("sync_api_key", #bool(config.syncApiKey)),
        ];
        switch (config.permissions) {
            case (null) ();
            case (?permissions) fields := Array.append(fields, [("permissions", serializeBotPermissions(permissions))]);
        };

        #object_(fields);
    };

    private func serializeSlashCommand(command : SdkTypes.SlashCommand) : Json.Json {
        var fields : [(Text, Json.Json)] = [
            ("name", #string(command.name)),
            ("description", #string(command.description)),
            ("params", serializeArrayOfValues(command.params, serializeSlashCommandParam)),
            ("permissions", serializeBotPermissions(command.permissions)),
        ];
        switch (command.placeholder) {
            case (null) ();
            case (?placeholder) fields := Array.append(fields, [("placeholder", #string(placeholder))]);
        };

        #object_(fields);
    };

    private func serializeSlashCommandParam(param : SdkTypes.SlashCommandParam) : Json.Json {
        var fields : [(Text, Json.Json)] = [
            ("name", #string(param.name)),
            ("description", #string(param.description)),
            ("required", #bool(param.required)),
            ("param_type", serializeParamType(param.paramType)),
        ];
        switch (param.placeholder) {
            case (null) ();
            case (?placeholder) fields := Array.append(fields, [("placeholder", #string(placeholder))]);
        };

        #object_(fields);
    };

    private func serializeParamType(paramType : SdkTypes.SlashCommandParamType) : Json.Json {
        switch (paramType) {
            case (#userParam) #string("UserParam");
            case (#booleanParam) #string("BooleanParam");
            case (#stringParam(strParam)) #object_([("StringParam", serializeStringParam(strParam))]);
            case (#integerParam(numParam)) #object_([("IntegerParam", serializeIntegerParam(numParam))]);
            case (#decimalParam(decParam)) #object_([("DecimalParam", serializeDecimalParam(decParam))]);
            case (#dateTimeParam(dateTimeParam)) #object_([("DateTimeParam", serializeDateTimeParam(dateTimeParam))]);
        };
    };

    private func serializeStringParam(param : SdkTypes.StringParam) : Json.Json {
        let choiceSerializer = func(choice : SdkTypes.BotCommandOptionChoice<Text>) : Json.Json = serializeChoice<Text>(choice.name, #string(choice.value));
        #object_([
            ("min_length", #number(#int(param.minLength))),
            ("max_length", #number(#int(param.maxLength))),
            ("choices", serializeArrayOfValues(param.choices, choiceSerializer)),
            ("multi_line", #bool(param.multiLine)),
        ]);
    };

    private func serializeIntegerParam(param : SdkTypes.IntegerParam) : Json.Json {
        let choiceSerializer = func(choice : SdkTypes.BotCommandOptionChoice<Int>) : Json.Json = serializeChoice<Int>(choice.name, #number(#int(choice.value)));
        #object_([
            ("min_value", #number(#int(param.minValue))),
            ("max_value", #number(#int(param.maxValue))),
            ("choices", serializeArrayOfValues(param.choices, choiceSerializer)),
        ]);
    };

    private func serializeDecimalParam(param : SdkTypes.DecimalParam) : Json.Json {
        let choiceSerializer = func(choice : SdkTypes.BotCommandOptionChoice<Float>) : Json.Json = serializeChoice<Float>(choice.name, #number(#float(choice.value)));
        #object_([
            ("min_value", #number(#float(param.minValue))),
            ("max_value", #number(#float(param.maxValue))),
            ("choices", serializeArrayOfValues(param.choices, choiceSerializer)),
        ]);
    };

    private func serializeDateTimeParam(param : SdkTypes.DateTimeParam) : Json.Json {
        #object_([
            ("future_only", #bool(param.futureOnly)),
        ]);
    };

    private func serializeChoice<T>(name : Text, value : Json.Json) : Json.Json {
        #object_([
            ("name", #string(name)),
            ("value", value),
        ]);
    };

    private func serializeBotPermissions(permissions : SdkTypes.BotPermissions) : Json.Json {
        let encodedCommunityPermissions = encodePermissions(
            permissions.community,
            encodeCommunityPermission,
        );

        let encodedChatPermissions = encodePermissions(
            permissions.chat,
            encodeGroupPermission,
        );

        let encodedMessagePermissions = encodePermissions(
            permissions.message,
            encodeMessagePermission,
        );

        #object_([
            ("community", encodedCommunityPermissions),
            ("chat", encodedChatPermissions),
            ("message", encodedMessagePermissions),
        ]);
    };

    private func encodePermissions<T>(permissions : [T], getEncodedValue : T -> Nat) : Json.Json {
        var encoded : Nat32 = 0;

        for (permission in permissions.vals()) {
            let encodedValue = getEncodedValue(permission);
            encoded := encoded | Nat32.pow(2, Nat32.fromNat(encodedValue));
        };
        if (encoded == 0) {
            return #null_;
        };

        #number(#int(Int.abs(Nat32.toNat(encoded))));
    };

    private func encodeCommunityPermission(permission : SdkTypes.CommunityPermission) : Nat {
        switch (permission) {
            case (#changeRoles) 0;
            case (#updateDetails) 1;
            case (#inviteUsers) 2;
            case (#removeMembers) 3;
            case (#createPublicChannel) 4;
            case (#createPrivateChannel) 5;
            case (#manageUserGroups) 6;
        };
    };

    private func encodeGroupPermission(permission : SdkTypes.GroupPermission) : Nat {
        switch (permission) {
            case (#changeRoles) 0;
            case (#updateGroup) 1;
            case (#addMembers) 2;
            case (#inviteUsers) 3;
            case (#removeMembers) 4;
            case (#deleteMessages) 5;
            case (#pinMessages) 6;
            case (#reactToMessages) 7;
            case (#mentionAllMembers) 8;
            case (#startVideoCall) 9;
        };
    };

    private func encodeMessagePermission(permission : SdkTypes.MessagePermission) : Nat {
        switch (permission) {
            case (#text) 0;
            case (#image) 1;
            case (#video) 2;
            case (#audio) 3;
            case (#file) 4;
            case (#poll) 5;
            case (#crypto) 6;
            case (#giphy) 7;
            case (#prize) 8;
            case (#p2pSwap) 9;
            case (#videoCall) 10;
        };
    };

    public func serializeSuccess(success : SdkTypes.SuccessResult) : Json.Json {
        let fields : [(Text, Json.Json)] = switch (success.message) {
            case (null) [];
            case (?message) [("message", serializeMessage(message))];
        };
        #object_(fields);
    };

    private func serializeMessage(message : SdkTypes.Message) : Json.Json {
        #object_([
            ("id", #string(message.id)),
            ("content", serializeMessageContent(message.content)),
            ("finalised", #bool(message.finalised)),
        ]);
    };

    private func serializeMessageContent(content : SdkTypes.MessageContent) : Json.Json {
        let (kind, value) : (Text, Json.Json) = switch (content) {
            case (#text(text)) ("Text", serializeTextContent(text));
            case (#image(image)) ("Image", serializeImageContent(image));
            case (#video(video)) ("Video", serializeVideoContent(video));
            case (#audio(audio)) ("Audio", serializeAudioContent(audio));
            case (#file(file)) ("File", serializeFileContent(file));
            case (#poll(poll)) ("Poll", serializePollContent(poll));
            case (#giphy(giphy)) ("Giphy", serializeGiphyContent(giphy));
            case (#custom(custom)) ("Custom", serializeCustomContent(custom));
        };
        serializeVariantWithValue(kind, value);
    };

    private func serializeTextContent(text : SdkTypes.TextContent) : Json.Json {
        #object_([("text", #string(text.text))]);
    };

    private func serializeImageContent(image : SdkTypes.ImageContent) : Json.Json {
        #object_([
            ("width", #number(#int(image.width))),
            ("height", #number(#int(image.height))),
            ("thumbnail_data", #string(image.thumbnailData)),
            (
                "caption",
                serializeNullable<Text>(image.caption, serializeText),
            ),
            ("mime_type", #string(image.mimeType)),
            (
                "blob_reference",
                serializeNullable<SdkTypes.BlobReference>(image.blobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializeVideoContent(video : SdkTypes.VideoContent) : Json.Json {
        #object_([
            ("width", #number(#int(video.width))),
            ("height", #number(#int(video.height))),
            ("thumbnail_data", #string(video.thumbnailData)),
            (
                "caption",
                serializeNullable<Text>(video.caption, serializeText),
            ),
            ("mime_type", #string(video.mimeType)),
            (
                "image_blob_reference",
                serializeNullable<SdkTypes.BlobReference>(video.imageBlobReference, serializeBlobReference),
            ),
            (
                "video_blob_reference",
                serializeNullable<SdkTypes.BlobReference>(video.videoBlobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializeAudioContent(audio : SdkTypes.AudioContent) : Json.Json {
        #object_([
            (
                "caption",
                serializeNullable<Text>(audio.caption, serializeText),
            ),
            ("mime_type", #string(audio.mimeType)),
            (
                "blob_reference",
                serializeNullable<SdkTypes.BlobReference>(audio.blobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializeFileContent(file : SdkTypes.FileContent) : Json.Json {
        #object_([
            ("name", #string(file.name)),
            (
                "caption",
                serializeNullable<Text>(file.caption, serializeText),
            ),
            ("mime_type", #string(file.mimeType)),
            ("file_size", #number(#int(file.fileSize))),
            (
                "blob_reference",
                serializeNullable<SdkTypes.BlobReference>(file.blobReference, serializeBlobReference),
            ),
        ]);
    };

    private func serializePollContent(poll : SdkTypes.PollContent) : Json.Json {
        #object_([
            ("config", serializePollConfig(poll.config)),
        ]);
    };

    private func serializePollConfig(pollConfig : SdkTypes.PollConfig) : Json.Json {
        #object_([
            ("text", serializeNullable<Text>(pollConfig.text, serializeText)),
            ("options", serializeArrayOfValues(pollConfig.options, serializeText)),
            (
                "end_date",
                serializeNullable<Nat>(pollConfig.endDate, serializeInt),
            ),
            ("anonymous", #bool(pollConfig.anonymous)),
            ("show_votes_before_end_date", #bool(pollConfig.showVotesBeforeEndDate)),
            ("allow_multiple_votes_per_user", #bool(pollConfig.allowMultipleVotesPerUser)),
            ("allow_user_to_change_vote", #bool(pollConfig.allowUserToChangeVote)),
        ]);
    };

    private func serializeGiphyContent(giphy : SdkTypes.GiphyContent) : Json.Json {
        #object_([
            ("caption", serializeNullable<Text>(giphy.caption, serializeText)),
            ("title", #string(giphy.title)),
            ("desktop", serializeGiphyImageVariant(giphy.desktop)),
            ("mobile", serializeGiphyImageVariant(giphy.mobile)),
        ]);
    };

    private func serializeCustomContent(custom : SdkTypes.CustomContent) : Json.Json {
        let base64Engine = Base64.Base64(#v(Base64.V2), ?false);
        let dataText = base64Engine.encode(#bytes(custom.data));
        #object_([
            ("kind", #string(custom.kind)),
            ("data", #string(dataText)),
        ]);
    };

    private func serializeGiphyImageVariant(giphyImageVariant : SdkTypes.GiphyImageVariant) : Json.Json {
        #object_([
            ("width", #number(#int(giphyImageVariant.width))),
            ("height", #number(#int(giphyImageVariant.height))),
            ("url", #string(giphyImageVariant.url)),
            ("mime_type", #string(giphyImageVariant.mimeType)),
        ]);
    };

    private func serializeText(option : Text) : Json.Json = #string(option);

    private func serializeInt(int : Int) : Json.Json = #number(#int(int));

    private func serializeArrayOfValues<T>(values : [T], serializer : T -> Json.Json) : Json.Json {
        #array(values.vals() |> Iter.map(_, serializer) |> Iter.toArray(_));
    };

    private func serializeBlobReference(blobReference : SdkTypes.BlobReference) : Json.Json {
        #object_([
            ("canister_id", #string(Principal.toText(blobReference.canister))),
            (
                "blob_id",
                #number(#int(blobReference.blobId)),
            ),
        ]);
    };

    private func serializeNullable<T>(value : ?T, serializer : T -> Json.Json) : Json.Json {
        switch (value) {
            case (null) #null_;
            case (?v) serializer(v);
        };
    };

    public func serializeBadRequest(badRequest : SdkTypes.BadRequestResult) : Json.Json {
        switch (badRequest) {
            case (#accessTokenNotFound) #string("AccessTokenNotFound");
            case (#accessTokenInvalid) #string("AccessTokenInvalid");
            case (#accessTokenExpired) #string("AccessTokenExpired");
            case (#commandNotFound) #string("CommandNotFound");
            case (#argsInvalid) #string("ArgsInvalid");
        };
    };

    public func serializeInternalError(error : SdkTypes.InternalErrorResult) : Json.Json {
        switch (error) {
            case (#invalid(invalid)) serializeVariantWithValue("Invalid", #string(invalid));
            case (#canisterError(canisterError)) serializeVariantWithValue("CanisterError", serializeCanisterError(canisterError));
            case (#c2cError((code, message))) serializeVariantWithValue("C2CError", #array([#number(#int(code)), #string(message)]));
        };
    };

    private func serializeCanisterError(canisterError : SdkTypes.CanisterError) : Json.Json {
        switch (canisterError) {
            case (#notAuthorized) #string("NotAuthorized");
            case (#frozen) #string("Frozen");
            case (#other(other)) serializeVariantWithValue("Other", #string(other));
        };
    };

    private func serializeVariantWithValue(variant : Text, value : Json.Json) : Json.Json {
        #object_([(variant, value)]);
    };

    public func deserializeBotActionByCommand(dataJson : Json.Json) : Result.Result<SdkTypes.BotActionByCommand, Text> {
        let (scopeType, scopeTypeValue) = switch (Json.getAsObject(dataJson, "scope")) {
            case (#ok(scopeObj)) scopeObj[0];
            case (#err(e)) return #err("Invalid 'scope' field: " # debug_show (e));
        };
        let scope : SdkTypes.BotActionScope = switch (scopeType) {
            case ("Chat") switch (deserializeBotActionChatDetails(scopeTypeValue)) {
                case (#ok(chat)) #chat(chat);
                case (#err(e)) return #err("Invalid 'Chat' scope value: " # e);
            };
            case ("Community") switch (deserializeBotActionCommunityDetails(scopeTypeValue)) {
                case (#ok(community)) #community(community);
                case (#err(e)) return #err("Invalid 'Community' scope value: " # e);
            };
            case (_) return #err("Invalid 'scope' field variant type: " # scopeType);
        };

        let botApiGateway = switch (getAsPrincipal(dataJson, "bot_api_gateway")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'bot_api_gateway' field: " # debug_show (e));
        };
        let bot = switch (getAsPrincipal(dataJson, "bot")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'bot' field: " # debug_show (e));
        };
        let grantedPermissions = switch (Json.get(dataJson, "granted_permissions")) {
            case (?permissions) switch (deserializeBotPermissions(permissions)) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'granted_permissions' field: " # e);
            };
            case (null) return #err("Missing 'granted_permissions' field");
        };
        let command = switch (Json.get(dataJson, "command")) {
            case (?commandJson) switch (deserializeCommand(commandJson)) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'command' field: " # e);
            };
            case (null) return #err("Missing 'command' field");
        };

        #ok({
            botApiGateway = botApiGateway;
            bot = bot;
            scope = scope;
            grantedPermissions = grantedPermissions;
            command = command;
        });
    };

    private func deserializeCommand(commandJson : Json.Json) : Result.Result<SdkTypes.Command, Text> {

        let commandName = switch (Json.getAsText(commandJson, "name")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'name' field: " # debug_show (e));
        };
        let commandArgs : [SdkTypes.CommandArg] = switch (Json.getAsArray(commandJson, "args")) {
            case (#ok(args)) switch (deserializeArrayOfValues(args, deserializeCommandArg)) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'args' field: " # e);
            };
            case (#err(e)) return #err("Invalid 'args' field: " # debug_show (e));
        };
        let initiator = switch (getAsPrincipal(commandJson, "initiator")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'initiator' field: " # debug_show (e));
        };
        #ok({
            name = commandName;
            args = commandArgs;
            initiator = initiator;
        });
    };

    private func deserializeBotPermissions(dataJson : Json.Json) : Result.Result<SdkTypes.BotPermissions, Text> {
        func getPermissions<T>(name : Text, getPermission : Nat -> ?T, deserializePermission : Json.Json -> Result.Result<T, Text>) : Result.Result<[T], Text> {
            switch (Json.get(dataJson, name)) {
                case (?#number(#int(encodedPermissions))) switch (decodePermissions<T>(encodedPermissions, getPermission)) {
                    case (#ok(v)) #ok(v);
                    case (#err(e)) #err("Invalid '" # name # "' BotPermission field: " # e);
                };
                case (?#array(permissions)) switch (deserializeArrayOfValues(permissions, deserializePermission)) {
                    case (#ok(v)) #ok(v);
                    case (#err(e)) #err("Invalid '" # name # "' field: " # e);
                };
                case (null) #ok([]); // No permissions
                case (_) #err("'" # name # "' BotPermission field not found: ");
            };
        };

        let communityPermissions = switch (
            getPermissions<SdkTypes.CommunityPermission>(
                "community",
                decodeCommunityPermission,
                deserializeCommunityPermission,
            )
        ) {
            case (#ok(permssions)) permssions;
            case (#err(e)) return #err(e);
        };

        let chatPermissions = switch (
            getPermissions<SdkTypes.GroupPermission>(
                "chat",
                decodeGroupPermission,
                deserializeGroupPermission,
            )
        ) {
            case (#ok(permssions)) permssions;
            case (#err(e)) return #err(e);
        };

        let messagePermissions = switch (
            getPermissions<SdkTypes.MessagePermission>(
                "message",
                decodeMessagePermission,
                deserializeMessagePermission,
            )
        ) {
            case (#ok(permssions)) permssions;
            case (#err(e)) return #err(e);
        };

        #ok({
            community = communityPermissions;
            chat = chatPermissions;
            message = messagePermissions;
        });
    };

    private func decodePermissions<T>(encodedPermissions : Int, getPermission : Nat -> ?T) : Result.Result<[T], Text> {
        if (encodedPermissions < 0) {
            return #err("Invalid encoded permissions value: " # Int.toText(encodedPermissions));
        };
        let encodedPermissionNat = Int.abs(encodedPermissions);
        if (encodedPermissionNat > 4294967295) {
            return #err("Invalid encoded permissions value: " # Nat.toText(encodedPermissionNat));
        };
        var encodedPermissionsNat32 = Nat32.fromNat(encodedPermissionNat);
        let permissions = Buffer.Buffer<T>(0);
        label f for (i in Iter.range(0, 32)) {
            if (encodedPermissionsNat32 == 0) {
                break f;
            };
            let flag = Nat32.pow(2, Nat32.fromNat(i));
            if (encodedPermissionsNat32 & flag == 0) {
                continue f; // Permission not set
            };
            encodedPermissionsNat32 := encodedPermissionsNat32 & ^flag;
            switch (getPermission(i)) {
                case (?permission) permissions.add(permission);
                case (null) return #err("Invalid encoded permission value: " # Nat.toText(i));
            };
        };

        #ok(Buffer.toArray(permissions));
    };

    private func decodeCommunityPermission(encodedPermission : Nat) : ?SdkTypes.CommunityPermission {
        let permission = switch (encodedPermission) {
            case (0) #changeRoles;
            case (1) #updateDetails;
            case (2) #inviteUsers;
            case (3) #removeMembers;
            case (4) #createPublicChannel;
            case (5) #createPrivateChannel;
            case (6) #manageUserGroups;
            case (_) return null;
        };
        ?permission;
    };

    private func decodeGroupPermission(encodedPermission : Nat) : ?SdkTypes.GroupPermission {
        let permission = switch (encodedPermission) {
            case (0) #changeRoles;
            case (1) #updateGroup;
            case (2) #addMembers;
            case (3) #inviteUsers;
            case (4) #removeMembers;
            case (5) #deleteMessages;
            case (6) #pinMessages;
            case (7) #reactToMessages;
            case (8) #mentionAllMembers;
            case (9) #startVideoCall;
            case (_) return null;
        };
        ?permission;
    };

    private func decodeMessagePermission(encodedPermission : Nat) : ?SdkTypes.MessagePermission {
        let permission = switch (encodedPermission) {
            case (0) #text;
            case (1) #image;
            case (2) #video;
            case (3) #audio;
            case (4) #file;
            case (5) #poll;
            case (6) #crypto;
            case (7) #giphy;
            case (8) #prize;
            case (9) #p2pSwap;
            case (10) #videoCall;
            case (_) return null;
        };
        ?permission;
    };

    private func deserializeMessagePermission(json : Json.Json) : Result.Result<SdkTypes.MessagePermission, Text> {
        let #string(permissionString) = json else return #err("Invalid message permission, expected string value");

        let permission : SdkTypes.MessagePermission = switch (permissionString) {
            case ("Text") #text;
            case ("Image") #image;
            case ("Video") #video;
            case ("Audio") #audio;
            case ("File") #file;
            case ("Poll") #poll;
            case ("Crypto") #crypto;
            case ("Giphy") #giphy;
            case ("Prize") #prize;
            case ("P2pSwap") #p2pSwap;
            case ("VideoCall") #videoCall;
            case (_) return #err("Invalid message permission: " # permissionString);
        };
        #ok(permission);
    };

    private func deserializeGroupPermission(json : Json.Json) : Result.Result<SdkTypes.GroupPermission, Text> {
        let #string(permissionString) = json else return #err("Invalid group permission, expected string value");

        let permission : SdkTypes.GroupPermission = switch (permissionString) {
            case ("ChangeRoles") #changeRoles;
            case ("UpdateGroup") #updateGroup;
            case ("AddMembers") #addMembers;
            case ("InviteUsers") #inviteUsers;
            case ("RemoveMembers") #removeMembers;
            case ("DeleteMessages") #deleteMessages;
            case ("PinMessages") #pinMessages;
            case ("ReactToMessages") #reactToMessages;
            case ("MentionAllMembers") #mentionAllMembers;
            case ("StartVideoCall") #startVideoCall;
            case (_) return #err("Invalid group permission: " # permissionString);
        };
        #ok(permission);
    };

    private func deserializeCommunityPermission(json : Json.Json) : Result.Result<SdkTypes.CommunityPermission, Text> {
        let #string(permissionString) = json else return #err("Invalid community permission, expected string value");

        let permission : SdkTypes.CommunityPermission = switch (permissionString) {
            case ("ChangeRoles") #changeRoles;
            case ("UpdateDetails") #updateDetails;
            case ("InviteUsers") #inviteUsers;
            case ("RemoveMembers") #removeMembers;
            case ("CreatePublicChannel") #createPublicChannel;
            case ("CreatePrivateChannel") #createPrivateChannel;
            case ("ManageUserGroups") #manageUserGroups;
            case (_) return #err("Invalid community permission: " # permissionString);
        };
        #ok(permission);
    };

    public func deserializeBotActionByApiKey(dataJson : Json.Json) : Result.Result<SdkTypes.BotActionByApiKey, Text> {
        let botApiGateway = switch (getAsPrincipal(dataJson, "bot_api_gateway")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'bot_api_gateway' field: " # debug_show (e));
        };
        let bot = switch (getAsPrincipal(dataJson, "bot")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'bot' field: " # debug_show (e));
        };

        let scope = switch (Json.getAsObject(dataJson, "scope")) {
            case (#ok(scope)) switch (deserializeAccessTokenScope(scope)) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'scope' field: " # e);
            };
            case (#err(e)) return #err("Invalid 'scope' field: " # debug_show (e));
        };

        let grantedPermissions = switch (Json.get(dataJson, "granted_permissions")) {
            case (?permissions) switch (deserializeBotPermissions(permissions)) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'granted_permissions' field: " # e);
            };
            case (null) return #err("Missing 'granted_permissions' field");
        };

        #ok({
            botApiGateway = botApiGateway;
            bot = bot;
            scope = scope;
            grantedPermissions = grantedPermissions;
        });
    };

    private func deserializeAccessTokenScope(scopeJson : [(Text, Json.Json)]) : Result.Result<SdkTypes.AccessTokenScope, Text> {
        let (scopeType, scopeTypeValue) = scopeJson[0];
        switch (scopeType) {
            case ("Chat") switch (Json.getAsObject(scopeTypeValue, "")) {
                case (#ok(chatObj)) switch (deserializeChat(chatObj[0])) {
                    case (#ok(chat)) #ok(#chat(chat));
                    case (#err(e)) return #err("Invalid 'Chat' scope value: " # e);
                };
                case (#err(e)) return #err("Invalid 'Chat' scope value: " # debug_show (e));
            };
            case ("Community") switch (getAsPrincipal(scopeTypeValue, "")) {
                case (#ok(canisterId)) #ok(#community(canisterId));
                case (#err(e)) return #err("Invalid 'Community' scope value: " # debug_show (e));
            };
            case (_) return #err("Invalid 'scope' field variant type: " # scopeType);
        };
    };

    private func deserializeArrayOfValues<T>(json : [Json.Json], deserialize : Json.Json -> Result.Result<T, Text>) : Result.Result<[T], Text> {
        let buffer = Buffer.Buffer<T>(json.size());
        for ((i, val) in IterTools.enumerate(json.vals())) {
            switch (deserialize(val)) {
                case (#ok(v)) buffer.add(v);
                case (#err(e)) return #err("Failed to deserialize array value [" # Nat.toText(i) # "]: " # e);
            };
        };
        #ok(Buffer.toArray(buffer));
    };

    private func deserializeCommandArg(json : Json.Json) : Result.Result<SdkTypes.CommandArg, Text> {
        let name = switch (Json.getAsText(json, "name")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'name' field: " # debug_show (e));
        };
        let (valueType, valueTypeValue) = switch (Json.getAsObject(json, "value")) {
            case (#ok(valueObj)) valueObj[0];
            case (#err(e)) return #err("Invalid 'value' field: " # debug_show (e));
        };
        let value : SdkTypes.CommandArgValue = switch (valueType) {
            case ("String") switch (Json.getAsText(valueTypeValue, "")) {
                case (#ok(string)) #string(string);
                case (#err(e)) return #err("Invalid 'String' value in CommandArg: " # debug_show (e));
            };
            case ("Boolean") switch (Json.getAsBool(valueTypeValue, "")) {
                case (#ok(bool)) #boolean(bool);
                case (#err(e)) return #err("Invalid 'Boolean' value in CommandArg: " # debug_show (e));
            };
            case ("Integer") switch (Json.getAsInt(valueTypeValue, "")) {
                case (#ok(int)) #integer(int);
                case (#err(e)) return #err("Invalid 'Integer' value in CommandArg: " # debug_show (e));
            };
            case ("Decimal") switch (Json.getAsFloat(valueTypeValue, "")) {
                case (#ok(float)) #decimal(float);
                case (#err(e)) return #err("Invalid 'Decimal' value in CommandArg: " # debug_show (e));
            };
            case ("User") switch (getAsPrincipal(valueTypeValue, "")) {
                case (#ok(p)) #user(p);
                case (#err(e)) return #err("Invalid 'User' value in CommandArg: " # debug_show (e));
            };
            case (_) return #err("Invalid value variant type: " # valueType);
        };
        #ok({
            name = name;
            value = value;
        });
    };

    private func deserializeBotActionChatDetails(dataJson : Json.Json) : Result.Result<SdkTypes.BotActionChatDetails, Text> {
        let chat = switch (Json.getAsObject(dataJson, "chat")) {
            case (#ok(chatObj)) switch (deserializeChat(chatObj[0])) {
                case (#ok(v)) v;
                case (#err(e)) return #err("Invalid 'chat' field: " # e);
            };
            case (#err(e)) return #err("Invalid 'chat' field: " # debug_show (e));
        };

        let threadRootMessageIndex = switch (Json.getAsNat(dataJson, "thread_root_message_index")) {
            case (#ok(v)) ?v;
            case (#err(_)) null; // TODO?
        };

        let messageId = switch (Json.getAsText(dataJson, "message_id")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'message_id' field: " # debug_show (e));
        };

        #ok({
            chat = chat;
            threadRootMessageIndex = threadRootMessageIndex;
            messageId = messageId;
        });
    };

    private func deserializeChat(chatVariantJson : (Text, Json.Json)) : Result.Result<SdkTypes.Chat, Text> {
        let (chatType, chatTypeValue) = chatVariantJson;
        let chat : SdkTypes.Chat = switch (chatType) {
            case ("Direct") switch (getAsPrincipal(chatTypeValue, "")) {
                case (#ok(p)) #direct(p);
                case (#err(e)) return #err("Invalid 'Direct' chat value: " # debug_show (e));
            };
            case ("Group") switch (getAsPrincipal(chatTypeValue, "")) {
                case (#ok(p)) #group(p);
                case (#err(e)) return #err("Invalid 'Group' chat value: " # debug_show (e));
            };
            case ("Channel") {
                let channelPrincipal = switch (getAsPrincipal(chatTypeValue, "[0]")) {
                    case (#ok(v)) v;
                    case (#err(e)) return #err("Invalid 'Channel' chat value: " # debug_show (e));
                };
                let channelId = switch (Json.getAsNat(chatTypeValue, "[1]")) {
                    case (#ok(v)) v;
                    case (#err(e)) return #err("Invalid 'Channel' chat value: " # debug_show (e));
                };
                #channel((channelPrincipal, channelId));
            };
            case (_) return #err("Invalid 'chat' field variant type: " # chatType);
        };
        #ok(chat);
    };

    private func deserializeBotActionCommunityDetails(dataJson : Json.Json) : Result.Result<SdkTypes.BotActionCommunityDetails, Text> {
        let communityId = switch (getAsPrincipal(dataJson, "community_id")) {
            case (#ok(v)) v;
            case (#err(e)) return #err("Invalid 'community_id' field: " # debug_show (e));
        };

        #ok({
            communityId = communityId;
        });
    };

    private func getAsPrincipal(json : Json.Json, path : Json.Path) : Result.Result<Principal, { #pathNotFound; #typeMismatch }> {
        switch (Json.getAsText(json, path)) {
            case (#ok(v)) #ok(Principal.fromText(v));
            case (#err(e)) return #err(e);
        };
    };
};
