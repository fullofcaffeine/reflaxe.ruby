package mailers;

import rails.action_mailer.MailAddress;
import rails.action_mailer.MailLayout;
import rails.action_mailer.MailParam;
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

final class WelcomeMailerParam {
	public static final email:MailParam<String> = "email";
	public static final name:MailParam<String> = "name";
	public static final message:MailParam<String> = "message";
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

@:railsMailer
class UserMailer extends rails.action_mailer.Base {
	// Rails parameterized mailers use `UserMailer.with(...).action`.
	// This typed extern stub emits no Ruby method; it only gives Haxe callers a
	// checked params object and lowers to the native Rails `.with(...)` class API.
	@:native("with")
	@:rubyKwargs
	@:rubyExternStub
	public static function withParams(params:WelcomeMailerParams):UserMailer {
		return cast null;
	}

	public function welcome(email:String, name:String, message:String):Void {
		attachments().add("welcome.txt", message);
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
		var email = param(WelcomeMailerParam.email);
		var name = param(WelcomeMailerParam.name);
		var message = param(WelcomeMailerParam.message);
		attachments().add("welcome.txt", message);
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
