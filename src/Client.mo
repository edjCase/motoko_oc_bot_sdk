import Types "./Types";
import Principal "mo:base/Principal";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";

module {
    public class Client(botApiGateway : Principal, authToken_ : Types.AuthToken) {
        let botApiActor = actor (Principal.toText(botApiGateway)) : BotApiGatewayActor;
        let authToken : AuthToken = switch (authToken_) {
            case (#jwt(jwt)) #Jwt(jwt);
            case (#apiKey(apiKey)) #ApiKey(apiKey);
        };

        public func sendMessage(message : Types.MessageContent) : async* SendMessageResponse {
            let mappedMessage = mapMessage(message);
            // TODO
            await botApiActor.bot_send_message({
                channel_id = null;
                message_id = null;
                content = mappedMessage;
                block_level_markdown = false;
                finalised = false;
                auth_token = authToken;
            });
        };
    };

    private func mapMessage(message : Types.MessageContent) : MessageContent {
        switch (message) {
            case (#text(text)) #Text(text);
            case (#image(image)) #Image({
                width = Nat32.fromNat(image.width);
                height = Nat32.fromNat(image.height);
                thumbnail_data = image.thumbnailData;
                caption = image.caption;
                mime_type = image.mimeType;
                blob_reference = mapBlobReference(image.blobReference);
            });
            case (#video(video)) #Video({
                width = Nat32.fromNat(video.width);
                height = Nat32.fromNat(video.height);
                thumbnail_data = video.thumbnailData;
                caption = video.caption;
                mime_type = video.mimeType;
                image_blob_reference = mapBlobReference(video.imageBlobReference);
                video_blob_reference = mapBlobReference(video.videoBlobReference);
            });
            case (#audio(audio)) #Audio({
                caption = audio.caption;
                mime_type = audio.mimeType;
                blob_reference = mapBlobReference(audio.blobReference);
            });
            case (#file(file)) #File({
                name = file.name;
                caption = file.caption;
                mime_type = file.mimeType;
                file_size = Nat32.fromNat(file.fileSize);
                blob_reference = mapBlobReference(file.blobReference);
            });
            case (#poll(poll)) #Poll({
                config = mapPollConfig(poll.config);
            });
            case (#giphy(giphy)) #Giphy({
                caption = giphy.caption;
                title = giphy.title;
                desktop = mapImageVariant(giphy.desktop);
                mobile = mapImageVariant(giphy.mobile);
            });
            case (#custom(custom)) #Custom(custom);
        };
    };

    private func mapBlobReference(blobReference : ?Types.BlobReference) : ?BlobReference {
        switch (blobReference) {
            case (null) null;
            case (?r) ?{
                canister = r.canister;
                blob_id = r.blobId;
            };
        };
    };

    private func mapImageVariant(imageVariant : Types.GiphyImageVariant) : GiphyImageVariant {
        return {
            width = imageVariant.width;
            height = imageVariant.height;
            url = imageVariant.url;
            mime_type = imageVariant.mimeType;
        };
    };

    private func mapPollConfig(pollConfig : Types.PollConfig) : PollConfig {
        return {
            text = pollConfig.text;
            options = pollConfig.options;
            end_date = switch (pollConfig.endDate) {
                case (null) null;
                case (?timestamp) ?Nat64.fromNat(timestamp);
            };
            anonymous = pollConfig.anonymous;
            show_votes_before_end_date = pollConfig.showVotesBeforeEndDate;
            allow_multiple_botes_per_user = pollConfig.allowMultipleVotesPerUser;
            allow_user_to_change_vote = pollConfig.allowUserToChangeVote;
        };
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

    public type BotApiGatewayActor = actor {
        bot_send_message : (SendMessageArgs) -> async SendMessageResponse;
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
