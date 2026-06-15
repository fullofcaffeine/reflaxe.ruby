package jobs;

import rails.macros.JobDsl.*;
import ruby.StandardError;

// Runtime retry probe for the generated Rails ActiveJob lane.
//
// Demonstrates: a typed Haxe job whose failure is handled by Rails `retry_on`.
// Type safety: lifecycle queue/retry options are checked by JobDsl and
// `performLater(attempt:Int)` is generated from the typed `perform` signature.
// Runtime behavior: the Rails test app performs this job, catches the raised
// `HxException` through `retry_on StandardError`, and asserts the retry is
// re-enqueued on the typed retry queue.
@:railsJob
class RetryProbeJob extends rails.active_job.Base {
	static final lifecycle = {
		queueAs("critical");
		retryOn(StandardError, {waitSeconds: 5, attempts: 2, queue: "retries"});
	}

	public function perform(attempt:Int):Void {
		throw "retry:" + Std.string(attempt);
	}
}
