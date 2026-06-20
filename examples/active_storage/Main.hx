import models.Profile;
import rails.active_storage.Attachable;
import rails.active_storage.Attachables;
import rails.active_storage.Blob;
import rails.action_view.HtmlNode;
import ruby.File;
import views.ProfileUploadView;

// ActiveStorage dogfood entrypoint.
//
// Demonstrates: typed attachment refs, signed-id/blob attachables, typed blob
// metadata/direct-upload helpers, and a typed HHX upload partial. IntelliSense
// should complete `Profile.attachments.*`, `Blob.signedId()`, and the generated
// template render call. Ruby output remains ordinary ActiveStorage receiver
// calls and ordinary Rails ERB for the upload form.
class Main {
	static function main() {
		var profile = new Profile();
		var hasAvatar = Profile.attachments.avatar.attached(profile);
		Profile.attachments.avatar.attach(profile, "avatar.png");
		Profile.attachments.avatar.attach(profile, Attachable.io(File.open("avatar.png"), "avatar.png", {contentType: "image/png"}));
		var uploadedBlob:Blob = cast null;
		var uploadedSignedId = uploadedBlob.signedId();
		var uploadedFilename = uploadedBlob.filename().toString();
		var uploadedContentType = uploadedBlob.contentType();
		var directUploadUrl = uploadedBlob.serviceUrlForDirectUpload();
		var directUploadHeaders = uploadedBlob.serviceHeadersForDirectUpload();
		Profile.attachments.avatar.attach(profile, uploadedSignedId);
		Profile.attachments.avatar.attach(profile, uploadedBlob);
		Profile.attachments.avatar.purge(profile);
		var hasGallery = Profile.attachments.gallery.attached(profile);
		Profile.attachments.gallery.attach(profile, ["one.png", "two.png"]);
		Profile.attachments.gallery.attach(profile, Attachables.of([
			Attachable.io(File.open("one.png"), "one.png", {contentType: "image/png"}),
			Attachable.io(File.open("two.png"), "two.png", {contentType: "image/png"})
		]));
		Profile.attachments.gallery.purge(profile);
		var uploadForm:HtmlNode = ProfileUploadView.render({profile: profile});
	}
}
