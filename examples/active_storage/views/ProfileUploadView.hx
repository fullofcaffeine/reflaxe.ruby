package views;

import models.Profile;
import rails.action_view.HtmlNode;

typedef ProfileUploadLocals = {
	var profile:Profile;
}

// Direct-upload HHX fixture.
//
// `@:railsTemplate` declares the Rails partial path the compiler materializes.
// `@:railsTemplateAst("render")` tells RailsInlineMarkup to parse the inline
// HHX return value into a typed HtmlNode AST, so attachment refs are checked in
// Haxe before the compiler emits normal Rails ERB.
@:railsTemplate("profiles/_upload_form")
@:railsTemplateAst("render")
class ProfileUploadView {
	public static function render(locals:ProfileUploadLocals):HtmlNode {
		return <form_with url="/profiles" scope="profile" local multipart class="profile-upload-form">
			<field_label name=${Profile.attachments.avatar}>Avatar</field_label>
			<file_field name=${Profile.attachments.avatar} direct_upload accept="image/png,image/jpeg" />
			<submit>Upload avatar</submit>
		</form_with>;
	}
}
