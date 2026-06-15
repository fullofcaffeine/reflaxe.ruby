package jobs;

import rails.active_job.DeserializationError;
import rails.macros.JobDsl.*;
import ruby.StandardError;

// Typed ActiveJob fixture.
//
// Demonstrates: a Haxe-authored Rails job with a contextual lifecycle DSL,
// a typed `perform(...)` method, and generated typed enqueue helpers.
// Type safety: `JobDsl` validates the queue/options and reads Ruby exception
// constants from typed externs such as `StandardError` and
// `DeserializationError`. `rails.macros.JobMacro` injects static
// `performLater` and `performNow` methods with the same argument types as
// `perform`, so enqueue call sites are checked by Haxe before Rails calls are
// emitted.
// IntelliSense: editors should complete `queueAs`, `retryOn`, `discardOn`,
// `performLater(userId:Int, email:String)`, and
// `performNow(userId:Int, email:String)`.
// Ruby output: an `ActiveJob::Base` subclass with normal Rails `queue_as`,
// `retry_on`, `discard_on`, `perform`, `perform_later`, and `perform_now`.
@:railsJob
class SendWelcomeEmailJob extends rails.active_job.Base {
	static final lifecycle = {
		queueAs("mailers");
		retryOn(StandardError, {waitSeconds: 5, attempts: 3});
		discardOn(DeserializationError);
	}

	public function perform(userId:Int, email:String):Void {
		var payload = "welcome:" + email;
		trace(payload);
	}
}
