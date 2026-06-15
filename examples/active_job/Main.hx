import jobs.SendWelcomeEmailJob;
import jobs.RetryProbeJob;

class Main {
	static function main() {
		SendWelcomeEmailJob.performLater(42, "reader@example.test");
		SendWelcomeEmailJob.performNow(7, "now@example.test");
		RetryProbeJob.performLater(1);
	}
}
