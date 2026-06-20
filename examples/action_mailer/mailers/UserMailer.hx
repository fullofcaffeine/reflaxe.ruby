package mailers;

import rails.action_mailer.AttachmentValue;
import rails.action_mailer.MailAddress;
import rails.action_mailer.MailLayout;
import rails.action_mailer.MessageDelivery;
import rails.action_view.Template;
import rails.macros.MailerMacro;
import views.WelcomeEmailHtmlView;
import views.WelcomeEmailTextView;
import views.WelcomeEmailView.WelcomeEmailLocals;

typedef WelcomeMailerParams = {
	var email:String;
	var name:String;
	var message:String;
}

// Typed ActionMailer fixture.
//
// Demonstrates: a Haxe-authored Rails mailer action that emits a normal
// `ActionMailer::Base` subclass and sends multipart mail through Rails'
// `mail(...) do |format| ... end` API.
// Type safety: `MailOptions` gives editor completion for common mail kwargs,
// accepts single or array recipient values through `MailAddress`, and rejects
// arbitrary object-shaped recipients unless `MailAddress.unchecked(...)` is used.
// `Template.of(...) : Template<WelcomeEmailLocals>` binds each HHX template to
// a locals typedef, and `MailerMacro.mailMultipart(...)` validates the locals
// object before Ruby is generated.
// IntelliSense: editors should complete `mailMultipart`, `Template.of`, mail
// kwargs such as `to`/`from`/`subject`, and `WelcomeEmailLocals` fields.
// Ruby output: a Rails-native mailer with `mail(to:, from:, subject:)` and
// format-specific `render(template:, locals:)` calls. The templates themselves
// are generated as ordinary ERB under `app/views`.
// Attachments demonstrate both typed paths: a terse string body and Rails'
// hash/inline attachment form through `AttachmentValue.content(...)`.

@:railsMailer
@:railsMailerParams(WelcomeMailerParams)
class UserMailer extends rails.action_mailer.Base {
	// `@:railsMailerParams` generates:
	// - `withParams(params:WelcomeMailerParams)`, a typed facade for Rails
	//   `UserMailer.with(...)`;
	// - `p.email` / `p.name` / `p.message`, typed param tokens that lower to
	//   `params[:email]`, etc. inside the generated Ruby mailer.
	public function welcome(email:String, name:String, message:String):Void {
		attachments().add("welcome.txt", message);
		attachments().inlineAttachments().add("welcome.csv", AttachmentValue.content("name,message\n" + name + "," + message, {mimeType: "text/csv"}));
		var locals:WelcomeEmailLocals = {
			name: name,
			message: message,
			productName: "RailsHx"
		};
		MailerMacro.mailMultipart(this, {
			to: email,
			from: "team@example.test",
			cc: ["ops@example.test"],
			replyTo: MailAddress.one("reply@example.test"),
			subject: "Welcome to typed RailsHx mail",
			layout: MailLayout.none()
		},
			(Template.of(WelcomeEmailHtmlView) : Template<WelcomeEmailLocals>), locals, (Template.of(WelcomeEmailTextView) : Template<WelcomeEmailLocals>),
			locals);
	}

	public function welcomeFromParams():MessageDelivery {
		var email = param(UserMailer.p.email);
		var name = param(UserMailer.p.name);
		var message = param(UserMailer.p.message);
		attachments().add("welcome.txt", message);
		attachments().inlineAttachments().add("welcome.csv", AttachmentValue.content("name,message\n" + name + "," + message, {mimeType: "text/csv"}));
		var locals:WelcomeEmailLocals = {
			name: name,
			message: message,
			productName: "RailsHx"
		};
		return MailerMacro.mailMultipart(this, {
			to: email,
			from: "team@example.test",
			cc: ["ops@example.test"],
			replyTo: MailAddress.one("reply@example.test"),
			subject: "Welcome to typed RailsHx parameterized mail",
			layout: MailLayout.none()
		},
			(Template.of(WelcomeEmailHtmlView) : Template<WelcomeEmailLocals>), locals, (Template.of(WelcomeEmailTextView) : Template<WelcomeEmailLocals>),
			locals);
	}
}
