import mailers.UserMailer;
import rails.active_job.Base;

class Main {
	static function main() {
		var mailer = new UserMailer();
		mailer.welcome("reader@example.test", "Ada", "Typed RailsHx mailers are ready.");
		var queuedDelivery:Base = UserMailer.withParams({
			email: "reader@example.test",
			name: "Ada",
			message: "Typed parameterized RailsHx mailers are ready."
		}).welcomeFromParams().deliverLater();
	}
}
