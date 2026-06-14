import models.Profile;

class Main {
	static function main() {
		var profile = new Profile();
		var hasAvatar = Profile.attachments.avatar.attached(profile);
		Profile.attachments.avatar.attach(profile, "avatar.png");
		Profile.attachments.avatar.attachUnchecked(profile, {io: "raw", filename: "avatar.png"});
		Profile.attachments.avatar.purge(profile);
		var hasGallery = Profile.attachments.gallery.attached(profile);
		Profile.attachments.gallery.attach(profile, ["one.png", "two.png"]);
		Profile.attachments.gallery.purge(profile);
	}
}
