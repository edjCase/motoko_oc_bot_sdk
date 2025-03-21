import Principal "mo:base/Principal";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";

module {

    public type BotApiActor = actor {
        bot_send_message : (SendMessageArgs) -> async SendMessageResponse;
        bot_delete_channel : (DeleteChannelArgs) -> async DeleteChannelResponse;
        bot_create_channel : (CreateChannelArgs) -> async CreateChannelResponse;
        bot_chat_events : (ChatEventsArgs) -> async ChatEventsResponse;
        bot_chat_details : (ChatDetailsArgs) -> async ChatDetailsResponse;
    };

    public type ChatDetailsArgs = {
        channel_id : ?Nat32;
        auth_token : AuthToken;
    };

    public type ChatDetailsResponse = {
        #Success : ChatDetails;
        #FailedAuthentication : Text;
        #DirectChatUnsupported;
        #NotAuthorized;
        #NotFound;
        #InternalError : Text;
    };

    public type ChatDetails = {
        name : Text;
        description : Text;
        avatar_id : ?Nat;
        is_public : Bool;
        history_visible_to_new_joiners : Bool;
        messages_visible_to_non_members : Bool;
        permissions : ChatPermissions;
        rules : VersionedRules;
        events_ttl : ?Milliseconds;
        events_ttl_last_updated : ?TimestampMillis;
        gate_config : ?AccessGateConfig;
        video_call_in_progress : ?VideoCall;
        verified : ?Bool;
        frozen : ?FrozenGroupInfo;
        date_last_pinned : ?TimestampMillis;
        last_updated : TimestampMillis;
        external_url : ?Text;
        latest_event_index : EventIndex;
        latest_message_index : ?MessageIndex;
        member_count : Nat32;
    };

    public type VersionedRules = {
        text : Text;
        version : Nat32;
        enabled : Bool;
    };

    public type VideoCall = {
        message_index : MessageIndex;
        call_type : VideoCallType;
    };

    public type VideoCallType = {
        #Default;
        #Broadcast;
    };

    public type FrozenGroupInfo = {
        timestamp : TimestampMillis;
        frozen_by : UserId;
        reason : ?Text;
    };

    public type ChatEventsResponse = {
        #Success : EventsResponse;
        #FailedAuthentication : Text;
        #NotAuthorized;
        #NotFound;
        #InternalError : Text;
    };

    public type EventIndex = Nat32;

    public type MessageIndex = Nat32;

    public type TimestampMillis = Nat64;

    public type MessageId = Nat64;

    public type UserId = Principal;

    public type CanisterId = Principal;

    public type EventsResponse = {
        events : [EventWrapper<ChatEvent>];
        unauthorized : [EventIndex];
        expired_event_ranges : [(EventIndex, EventIndex)];
        expired_message_ranges : [(MessageIndex, MessageIndex)];
        latest_event_index : EventIndex;
        chat_last_updated : TimestampMillis;
    };

    public type EventWrapper<T> = {
        index : EventIndex;
        timestamp : TimestampMillis;
        correlation_id : Nat64;
        expires_at : ?TimestampMillis;
        event : T;
    };

    public type ChatEvent = {
        #Empty;
        #Message : Message;
        #GroupChatCreated : GroupCreated;
        #DirectChatCreated : DirectChatCreated;
        #GroupNameChanged : GroupNameChanged;
        #GroupDescriptionChanged : GroupDescriptionChanged;
        #GroupRulesChanged : GroupRulesChanged;
        #AvatarChanged : AvatarChanged;
        #ParticipantsAdded : MembersAdded;
        #ParticipantsRemoved : MembersRemoved;
        #ParticipantJoined : MemberJoined;
        #ParticipantLeft : MemberLeft;
        #RoleChanged : RoleChanged;
        #UsersBlocked : UsersBlocked;
        #UsersUnblocked : UsersUnblocked;
        #MessagePinned : MessagePinned;
        #MessageUnpinned : MessageUnpinned;
        #PermissionsChanged : PermissionsChanged;
        #GroupVisibilityChanged : GroupVisibilityChanged;
        #GroupInviteCodeChanged : GroupInviteCodeChanged;
        #ChatFrozen : GroupFrozen;
        #ChatUnfrozen : GroupUnfrozen;
        #EventsTimeToLiveUpdated : EventsTimeToLiveUpdated;
        #GroupGateUpdated : GroupGateUpdated;
        #UsersInvited : UsersInvited;
        #MembersAddedToDefaultChannel : MembersAddedToDefaultChannel;
        #ExternalUrlUpdated : ExternalUrlUpdated;
        #BotAdded : BotAdded;
        #BotRemoved : BotRemoved;
        #BotUpdated : BotUpdated;
        #FailedToDeserialize;
    };

    public type GroupCreated = {
        name : Text;
        description : Text;
        created_by : UserId;
    };

    public type DirectChatCreated = {};

    public type GroupNameChanged = {
        new_name : Text;
        previous_name : Text;
        changed_by : UserId;
    };

    public type GroupDescriptionChanged = {
        new_description : Text;
        previous_description : Text;
        changed_by : UserId;
    };

    public type GroupRulesChanged = {
        enabled : Bool;
        prev_enabled : Bool;
        changed_by : UserId;
    };

    public type AvatarChanged = {
        new_avatar : ?Document;
        previous_avatar : ?Document;
        changed_by : UserId;
    };

    public type MembersAdded = {
        user_ids : [UserId];
        added_by : UserId;
        unblocked : [UserId];
    };

    public type MembersRemoved = {
        user_ids : [UserId];
        removed_by : UserId;
    };

    public type UsersBlocked = {
        user_ids : [UserId];
        blocked_by : UserId;
    };

    public type UsersUnblocked = {
        user_ids : [UserId];
        unblocked_by : UserId;
    };

    public type MemberJoined = {
        user_id : UserId;
        invited_by : ?UserId;
    };

    public type MemberLeft = {
        user_id : UserId;
    };

    public type RoleChanged = {
        user_ids : [UserId];
        changed_by : UserId;
        old_role : ChatRole;
        new_role : ChatRole;
    };

    public type MessagePinned = {
        message_index : MessageIndex;
        pinned_by : UserId;
    };

    public type MessageUnpinned = {
        message_index : MessageIndex;
        unpinned_by : UserId;
        due_to_message_deleted : Bool;
    };

    public type PermissionsChanged = {
        old_permissions_v2 : ChatPermissions;
        new_permissions_v2 : ChatPermissions;
        changed_by : UserId;
    };

    public type GroupVisibilityChanged = {
        public_ : ?Bool;
        messages_visible_to_non_members : ?Bool;
        changed_by : UserId;
    };

    public type GroupInviteCodeChanged = {
        change : GroupInviteCodeChange;
        changed_by : UserId;
    };

    public type GroupInviteCodeChange = {
        #Enabled;
        #Disabled;
        #Reset;
    };

    public type GroupFrozen = {
        frozen_by : UserId;
        reason : ?Text;
    };

    public type GroupUnfrozen = {
        unfrozen_by : UserId;
    };

    public type EventsTimeToLiveUpdated = {
        updated_by : UserId;
        new_ttl : ?Milliseconds;
    };

    public type GroupGateUpdated = {
        updated_by : UserId;
        new_gate_config : ?AccessGateConfig;
    };

    public type MembersAddedToDefaultChannel = {
        count : Nat32;
    };

    public type ExternalUrlUpdated = {
        updated_by : UserId;
        new_url : ?Text;
    };

    public type UsersInvited = {
        user_ids : [UserId];
        invited_by : UserId;
    };

    public type BotAdded = {
        user_id : UserId;
        added_by : UserId;
    };

    public type BotRemoved = {
        user_id : UserId;
        removed_by : UserId;
    };

    public type BotUpdated = {
        user_id : UserId;
        updated_by : UserId;
    };

    public type Message = {
        message_index : MessageIndex;
        message_id : MessageId;
        sender : UserId;
        content : MessageContent;
        bot_context : ?BotMessageContext;
        replies_to : ?ReplyContext;
        reactions : [(Text, [UserId])];
        tips : Tips;
        thread_summary : ?ThreadSummary;
        edited : Bool;
        forwarded : Bool;
        block_level_markdown : Bool;
    };

    public type ThreadSummary = {
        participant_ids : [UserId];
        followed_by_me : Bool;
        reply_count : Nat32;
        latest_event_index : EventIndex;
        latest_event_timestamp : TimestampMillis;
    };

    public type BotMessageContext = {
        command : ?Command;
        finalised : Bool;
    };

    public type Command = {
        name : Text;
        args : [CommandArg];
        initiator : UserId;
        meta : ?CommandMeta;
    };

    public type CommandArg = {
        name : Text;
        value : CommandArgValue;
    };

    public type CommandArgValue = {
        #String : Text;
        #Integer : Int;
        #Decimal : Float;
        #Boolean : Bool;
        #User : UserId;
    };

    public type CommandMeta = {
        timezone : Text; // IANA timezone e.g. "Europe/London"
        language : Text; // The language selected in OpenChat e.g. "en"
    };

    public type ReplyContext = {
        chat_if_other : ?(Chat, ?MessageIndex);
        event_index : EventIndex;
    };

    public type ChannelId = Nat32;

    public type Chat = {
        #Direct : CanisterId;
        #Group : CanisterId;
        #Channel : (CanisterId, ChannelId);
    };

    public type Tips = [(CanisterId, [(UserId, Nat)])];

    public type ChatEventsArgs = {
        channel_id : ?Nat32;
        events : EventsSelectionCriteria;
        auth_token : AuthToken;
    };

    public type EventsSelectionCriteria = {
        #Page : EventsPageArgs;
        #ByIndex : EventsByIndexArgs;
        #Window : EventsWindowArgs;
    };

    public type EventsPageArgs = {
        start_index : EventIndex;
        ascending : Bool;
        max_messages : Nat32;
        max_events : Nat32;
    };

    public type EventsByIndexArgs = {
        events : [Nat32];
    };

    public type EventsWindowArgs = {
        mid_point : MessageIndex;
        max_messages : Nat32;
        max_events : Nat32;
    };

    public type Milliseconds = Nat64;

    public type CreateChannelArgs = {
        is_public : Bool;
        name : Text;
        description : Text;
        rules : Rules;
        avatar : ?Document;
        history_visible_to_new_joiners : Bool;
        messages_visible_to_non_members : Bool;
        permissions : ?ChatPermissions;
        events_ttl : ?Milliseconds;
        gate_config : ?AccessGateConfig;
        external_url : ?Text;
        auth_token : AuthToken;
    };

    public type AccessGateConfig = {
        gate : AccessGate;
        expiry : ?Milliseconds;
    };

    public type AccessGateNonComposite = {
        #DiamondMember;
        #LifetimeDiamondMember;
        #UniquePerson;
        #VerifiedCredential : VerifiedCredentialGate;
        #SnsNeuron : SnsNeuronGate;
        #Payment : PaymentGate;
        #TokenBalance : TokenBalanceGate;
        #Locked;
        #ReferredByMember;
    };

    public type AccessGate = AccessGateNonComposite or {
        #Composite : CompositeGate;
    };

    public type CompositeGate = {
        inner : [AccessGateNonComposite];
        and_ : Bool;
    };

    public type TokenBalanceGate = {
        ledger_canister_id : Principal;
        min_balance : Nat;
    };

    public type PaymentGate = {
        ledger_canister_id : Principal;
        amount : Nat;
        fee : Nat;
    };

    public type SnsNeuronGate = {
        governance_canister_id : Principal;
        min_stake_e8s : ?Nat64;
        min_dissolve_delay : ?Milliseconds;
    };

    public type VerifiedCredentialGate = {
        issuer_canister_id : Principal;
        issuer_origin : Text;
        credential_type : Text;
        credential_name : Text;
        credential_arguments : [(Text, VerifiedCredentialArgumentValue)];
    };

    public type VerifiedCredentialArgumentValue = {
        #String : Text;
        #Int : Int32;
    };

    public type Rules = {
        text : Text;
        enabled : Bool;
    };

    public type Document = {
        id : Nat;
        mime_type : Text;
        data : [Nat8];
    };

    public type ChatPermissions = {
        change_roles : ChatPermissionRole;
        update_group : ChatPermissionRole;
        add_members : ChatPermissionRole;
        invite_users : ChatPermissionRole;
        remove_members : ChatPermissionRole;
        delete_messages : ChatPermissionRole;
        pin_messages : ChatPermissionRole;
        react_to_messages : ChatPermissionRole;
        mention_all_members : ChatPermissionRole;
        start_video_call : ChatPermissionRole;
        message_permissions : MessagePermissions;
        thread_permissions : ?MessagePermissions;
    };

    public type MessagePermissions = {
        default : ChatPermissionRole;
        text : ?ChatPermissionRole;
        image : ?ChatPermissionRole;
        video : ?ChatPermissionRole;
        audio : ?ChatPermissionRole;
        file : ?ChatPermissionRole;
        poll : ?ChatPermissionRole;
        crypto : ?ChatPermissionRole;
        giphy : ?ChatPermissionRole;
        prize : ?ChatPermissionRole;
        p2p_swap : ?ChatPermissionRole;
        video_call : ?ChatPermissionRole;
        custom : [CustomPermission];
    };

    public type ChatRole = {
        #Participant;
        #Owner;
        #Admin;
        #Moderator;
        #Member;
    };

    public type CustomPermission = {
        subtype : Text;
        role : ChatPermissionRole;
    };

    public type ChatPermissionRole = {
        #None;
        #Owner;
        #Admins;
        #Moderators;
        #Members;
    };

    public type CreateChannelResponse = {
        #Success : CreateChannelSuccessResult;
        #FailedAuthentication : Text;
        #InvalidRequest : Text;
        #NotAuthorized;
        #Frozen;
        #C2CError : (Int32, Text);
    };

    public type CreateChannelSuccessResult = {
        channel_id : Nat32;
    };

    public type DeleteChannelArgs = {
        channel_id : Nat32;
        auth_token : AuthToken;
    };

    public type DeleteChannelResponse = {
        #Success;
        #ChannelNotFound;
        #FailedAuthentication : Text;
        #InvalidRequest : Text;
        #NotAuthorized;
        #Frozen;
        #C2CError : (Int32, Text);
    };

    public type SendMessageArgs = {
        channel_id : ?Nat32;
        message_id : ?Nat64;
        content : MessageContent;
        block_level_markdown : Bool;
        finalised : Bool;
        auth_token : AuthToken;
    };

    public type SendMessageResponse = {
        #Success : SendMessageSuccessResult;
        #FailedAuthentication : Text;
        #InvalidRequest : Text;
        #NotAuthorized;
        #Frozen;
        #ThreadNotFound;
        #MessageAlreadyFinalised;
        #C2CError : (Int32, Text);
    };

    public type SendMessageSuccessResult = {
        message_id : Nat64;
        event_index : Nat32;
        message_index : Nat32;
        timestamp : Nat64; // milliseconds
        expires_at : ?Nat64; // milliseconds
    };

    public type AuthToken = {
        #Jwt : Text;
        #ApiKey : Text;
    };

    public type MessageContent = {
        #Text : TextContent;
        #Image : ImageContent;
        #Video : VideoContent;
        #Audio : AudioContent;
        #File : FileContent;
        #Poll : PollContent;
        #Giphy : GiphyContent;
        #Custom : CustomContent;
    };

    public type TextContent = {
        text : Text;
    };

    public type ImageContent = {
        width : Nat32;
        height : Nat32;
        thumbnail_data : ThumbnailData;
        caption : ?Text;
        mime_type : Text;
        blob_reference : ?BlobReference;
    };

    public type ThumbnailData = (Text);

    public type BlobReference = {
        canister : Principal;
        blob_id : Nat;
    };

    public type VideoContent = {
        width : Nat32;
        height : Nat32;
        thumbnail_data : ThumbnailData;
        caption : ?Text;
        mime_type : Text;
        image_blob_reference : ?BlobReference;
        video_blob_reference : ?BlobReference;
    };

    public type AudioContent = {
        caption : ?Text;
        mime_type : Text;
        blob_reference : ?BlobReference;
    };

    public type FileContent = {
        name : Text;
        caption : ?Text;
        mime_type : Text;
        file_size : Nat32;
        blob_reference : ?BlobReference;
    };

    public type PollContent = {
        config : PollConfig;
    };

    public type PollConfig = {
        text : ?Text;
        options : [Text];
        end_date : ?Nat64; // milliseconds
        anonymous : Bool;
        show_votes_before_end_date : Bool;
        allow_multiple_botes_per_user : Bool;
        allow_user_to_change_vote : Bool;
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
        mime_type : Text;
    };

    public type CustomContent = {
        kind : Text;
        data : [Nat8];
    };

};
