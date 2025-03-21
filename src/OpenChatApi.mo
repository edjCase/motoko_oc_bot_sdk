import Principal "mo:base/Principal";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";

module {

    public type BotApiActor = actor {
        bot_send_message : (SendMessageArgs) -> async SendMessageResponse;
        bot_delete_channel : (DeleteChannelArgs) -> async DeleteChannelResponse;
        bot_create_channel : (CreateChannelArgs) -> async CreateChannelResponse;
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
