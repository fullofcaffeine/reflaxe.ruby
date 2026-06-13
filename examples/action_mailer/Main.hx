import mailers.UserMailer;

class Main {
	static function main() {
		var mailer = new UserMailer();
		mailer.welcome("reader@example.test", "Ada", "Typed RailsHx mailers are ready.");
	}
}
