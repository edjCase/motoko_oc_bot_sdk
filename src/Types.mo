import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import Nat8 "mo:base/Nat8";

module {
    public type CanisterId = Principal;
    public type UserId = Principal;
    public type ChannelId = Nat;
    public type TimestampMillis = Nat;
    public type TimestampNanos = Nat;
    public type Milliseconds = Nat;
    public type Nanoseconds = Nat;
    public type MessageId = Text; // Nat64 encoded as string or any other unique identifier
    public type MessageIndex = Nat;
    public type EventIndex = Nat;
    public type Hash = [Nat8]; // 32 bytes

    public type Command = {
        name : Text;
        args : [CommandArg];
        initiator : UserId;
    };

    public type CommandArg = {
        name : Text;
        value : CommandArgValue;
    };

    public type CommandArgValue = {
        #string : Text;
        #integer : Int;
        #decimal : Float;
        #boolean : Bool;
        #user : UserId;
    };

    public type CommandResponse = {
        #success : SuccessResult;
        #badRequest : BadRequestResult;
        #internalError : InternalErrorResult;
    };

    public type SuccessResult = {
        message : ?Message;
    };

    public type Message = {
        id : MessageId;
        content : MessageContent;
        finalised : Bool;
        blockLevelMarkdown : Bool;
        ephemeral : Bool;
    };

    public type MessageContent = {
        #text : TextContent;
        #image : ImageContent;
        #video : VideoContent;
        #audio : AudioContent;
        #file : FileContent;
        #poll : PollContent;
        #giphy : GiphyContent;
        #custom : CustomContent;
    };

    public type MessageContentOrUnsupported = MessageContent or {
        #unsupported : UnsupporedContent;
    };

    public type TextContent = {
        text : Text;
    };

    public type ImageContent = {
        width : Nat;
        height : Nat;
        thumbnailData : ThumbnailData;
        caption : ?Text;
        mimeType : Text;
        blobReference : ?BlobReference;
    };

    public type ThumbnailData = (Text);

    public type BlobReference = {
        canister : CanisterId;
        blobId : Nat;
    };

    public type VideoContent = {
        width : Nat;
        height : Nat;
        thumbnailData : ThumbnailData;
        caption : ?Text;
        mimeType : Text;
        imageBlobReference : ?BlobReference;
        videoBlobReference : ?BlobReference;
    };

    public type AudioContent = {
        caption : ?Text;
        mimeType : Text;
        blobReference : ?BlobReference;
    };

    public type FileContent = {
        name : Text;
        caption : ?Text;
        mimeType : Text;
        fileSize : Nat;
        blobReference : ?BlobReference;
    };

    public type PollContent = {
        config : PollConfig;
    };

    public type PollConfig = {
        text : ?Text;
        options : [Text];
        endDate : ?TimestampMillis;
        anonymous : Bool;
        showVotesBeforeEndDate : Bool;
        allowMultipleVotesPerUser : Bool;
        allowUserToChangeVote : Bool;
    };

    public type GiphyContent = {
        caption : ?Text;
        title : Text;
        desktop : GiphyImageVariant;
        mobile : GiphyImageVariant;
    };

    public type GiphyImageVariant = {
        width : Nat;
        height : Nat;
        url : Text;
        mimeType : Text;
    };

    public type CustomContent = {
        kind : Text;
        data : [Nat8];
    };

    public type UnsupporedContent = {
        kind : Text;
    };

    public type BadRequestResult = {
        #accessTokenNotFound;
        #accessTokenInvalid;
        #accessTokenExpired;
        #commandNotFound;
        #argsInvalid;
    };

    public type InternalErrorResult = {
        #invalid : Text;
        #canisterError : CanisterError;
        #c2cError : C2CError;
    };

    public type CanisterError = {
        #notAuthorized;
        #frozen;
        #other : Text;
    };

    public type C2CError = (Int, Text);

    public type ExecuteContext = {
        action : BotAction;
        jwt : Text;
    };

    public type BotAction = {
        #command : BotActionByCommand;
        #apiKey : BotActionByApiKey;
    };

    public type BotActionByApiKey = {
        botApiGateway : CanisterId;
        bot : UserId;
        scope : AccessTokenScope;
        grantedPermissions : BotPermissions;
    };

    public type AccessTokenScope = {
        #chat : Chat;
        #community : CanisterId;
    };

    public type BotActionByCommand = {
        botApiGateway : CanisterId;
        bot : UserId;
        scope : BotActionScope;
        grantedPermissions : BotPermissions;
        command : Command;
    };

    public type BotActionScope = {
        #chat : BotActionChatDetails;
        #community : BotActionCommunityDetails;
    };

    public type BotActionChatDetails = {
        chat : Chat;
        threadRootMessageIndex : ?MessageIndex;
        messageId : MessageId;
    };

    public type Chat = {
        #direct : CanisterId;
        #group : CanisterId;
        #channel : (CanisterId, ChannelId);
    };

    public type BotActionCommunityDetails = {
        communityId : CanisterId;
    };

    public type BotPermissions = {
        chat : [GroupPermission];
        community : [CommunityPermission];
        message : [MessagePermission];
    };

    public type CommunityPermission = {
        #changeRoles;
        #updateDetails;
        #inviteUsers;
        #removeMembers;
        #createPublicChannel;
        #createPrivateChannel;
        #manageUserGroups;
    };

    public type GroupPermission = {
        #changeRoles;
        #updateGroup;
        #addMembers;
        #inviteUsers;
        #removeMembers;
        #deleteMessages;
        #pinMessages;
        #reactToMessages;
        #mentionAllMembers;
        #startVideoCall;
    };

    public type MessagePermission = {
        #text;
        #image;
        #video;
        #audio;
        #file;
        #poll;
        #crypto;
        #giphy;
        #prize;
        #p2pSwap;
        #videoCall;
    };

    public type BotSchema = {
        description : Text;
        commands : [SlashCommand];
        autonomousConfig : ?AutonomousConfig;
    };

    public type AutonomousConfig = {
        permissions : ?BotPermissions;
        syncApiKey : Bool;
    };

    public type SlashCommand = {
        name : Text;
        description : Text;
        placeholder : ?Text;
        params : [SlashCommandParam];
        permissions : BotPermissions;
    };

    public type SlashCommandParam = {
        name : Text;
        description : Text;
        placeholder : ?Text;
        required : Bool;
        paramType : SlashCommandParamType;
    };

    public type SlashCommandParamType = {
        #userParam;
        #booleanParam;
        #stringParam : StringParam;
        #integerParam : IntegerParam;
        #decimalParam : DecimalParam;
        #dateTimeParam : DateTimeParam;
    };

    public type StringParam = {
        minLength : Nat;
        maxLength : Nat;
        choices : [BotCommandOptionChoice<Text>];
        multiLine : Bool;
    };

    public type IntegerParam = {
        minValue : Int;
        maxValue : Int;
        choices : [BotCommandOptionChoice<Int>];
    };

    public type DecimalParam = {
        minValue : Float;
        maxValue : Float;
        choices : [BotCommandOptionChoice<Float>];
    };

    public type DateTimeParam = {
        futureOnly : Bool;
    };

    public type BotCommandOptionChoice<T> = {
        name : Text;
        value : T;
    };

    public type SendMessageArgs = {
        channelId : ?ChannelId;
        messageId : ?Nat;
        content : MessageContent;
        blockLevelMarkdown : Bool;
        finalized : Bool;
        authToken : AuthToken;
    };

    public type SendMessageResponse = {
        #success : SendMessageSuccessResult;
        #failedAuthentication : Text;
        #invalidRequest : Text;
        #notAuthorized;
        #frozen;
        #threadNotFound;
        #messageAlreadyFinalised;
        #c2cError : C2CError;
    };

    public type SendMessageSuccessResult = {
        messageId : MessageId;
        eventIndex : EventIndex;
        messageIndex : MessageIndex;
        timestamp : TimestampMillis;
        expiresAt : ?TimestampMillis;
    };

    public type AuthToken = {
        #jwt : Text;
        #apiKey : Text;
    };

    public type BotApiGatewayActor = actor {
        bot_send_message : (SendMessageArgs) -> async SendMessageResponse;
    };

};
