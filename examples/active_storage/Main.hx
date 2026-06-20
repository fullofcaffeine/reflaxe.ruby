import models.Profile;
import rails.active_storage.Attachable;
import rails.active_storage.Attachables;
import ruby.File;

class Main {
	static function main() {
		var profile = new Profile();
		var hasAvatar = Profile.attachments.avatar.attached(profile);
		Profile.attachments.avatar.attach(profile, "avatar.png");
		Profile.attachments.avatar.attach(profile, Attachable.io(File.open("avatar.png"), "avatar.png", {contentType: "image/png"}));
		Profile.attachments.avatar.purge(profile);
		var hasGallery = Profile.attachments.gallery.attached(profile);
		Profile.attachments.gallery.attach(profile, ["one.png", "two.png"]);
		Profile.attachments.gallery.attach(profile, Attachables.of([
			Attachable.io(File.open("one.png"), "one.png", {contentType: "image/png"}),
			Attachable.io(File.open("two.png"), "two.png", {contentType: "image/png"})
		]));
		Profile.attachments.gallery.purge(profile);
	}
}
