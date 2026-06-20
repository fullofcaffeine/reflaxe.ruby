package previews;

import mailers.UserMailer;
import rails.action_mailer.MessageDelivery;

// Typed ActionMailer preview fixture.
//
// Demonstrates: a Haxe-authored Rails mailer preview that emits the standard
// Rails `ActionMailer::Preview` artifact under `test/mailers/previews`.
// Type safety: the preview calls `UserMailer.withParams(...)`, so missing or
// mistyped parameterized mailer params fail during Haxe compilation.
// Ruby output: a top-level `UserMailerPreview < ActionMailer::Preview` class
// with a normal `welcome` preview method returning the Rails message delivery.
@:railsMailerPreview
class UserMailerPreview extends rails.action_mailer.Preview {
	public function welcome():MessageDelivery {
		return UserMailer.withParams({
			email: "preview@example.test",
			name: "Preview Ada",
			message: "Previewed through typed RailsHx params."
		}).welcomeFromParams();
	}
}
