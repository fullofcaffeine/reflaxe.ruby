package mailers;

import rails.action_view.Template;
import rails.macros.MailerMacro;
import views.WelcomeEmailHtmlView;
import views.WelcomeEmailTextView;
import views.WelcomeEmailView.WelcomeEmailLocals;

// Typed ActionMailer fixture.
//
// Demonstrates: a Haxe-authored Rails mailer action that emits a normal
// `ActionMailer::Base` subclass and sends multipart mail through Rails'
// `mail(...) do |format| ... end` API.
// Type safety: `MailOptions` gives editor completion for common mail kwargs,
// `Template.of(...) : Template<WelcomeEmailLocals>` binds each HHX template to
// a locals typedef, and `MailerMacro.mailMultipart(...)` validates the locals
// object before Ruby is generated.
// IntelliSense: editors should complete `mailMultipart`, `Template.of`, mail
// kwargs such as `to`/`from`/`subject`, and `WelcomeEmailLocals` fields.
// Ruby output: a Rails-native mailer with `mail(to:, from:, subject:)` and
// format-specific `render(template:, locals:)` calls. The templates themselves
// are generated as ordinary ERB under `app/views`.
@:railsMailer
class UserMailer extends rails.action_mailer.Base {
	public function welcome(email:String, name:String, message:String):Void {
		var locals:WelcomeEmailLocals = {
			name: name,
			message: message,
			productName: "RailsHx"
		};
		MailerMacro.mailMultipart(this, {
			to: email,
			from: "team@example.test",
			subject: "Welcome to typed RailsHx mail"
		}, (Template.of(WelcomeEmailHtmlView) : Template<WelcomeEmailLocals>), locals,
			(Template.of(WelcomeEmailTextView) : Template<WelcomeEmailLocals>), locals);
	}
}
