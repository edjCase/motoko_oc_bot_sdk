import Principal "mo:base/Principal";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";

module {

    public type BotApiActor = actor {
        bot_send_message : (SendMessageArgs) -> async SendMessageResponse;
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
