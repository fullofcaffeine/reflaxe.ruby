import jobs.SendWelcomeEmailJob;

class Main {
	static function main() {
		SendWelcomeEmailJob.performLater(42, "reader@example.test");
		SendWelcomeEmailJob.performNow(7, "now@example.test");
	}
}
