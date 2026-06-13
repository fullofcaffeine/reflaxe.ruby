package jobs;

// Typed ActiveJob fixture.
//
// Demonstrates: a Haxe-authored Rails job with queue/retry/discard metadata,
// a typed `perform(...)` method, and generated typed enqueue helpers.
// Type safety: `rails.macros.JobMacro` injects static `performLater` and
// `performNow` methods with the same argument types as `perform`, so enqueue
// call sites are checked by Haxe before the compiler emits Rails calls.
// IntelliSense: editors should complete `performLater(userId:Int, email:String)`
// and `performNow(userId:Int, email:String)` on the job class.
// Ruby output: an `ActiveJob::Base` subclass with normal Rails `queue_as`,
// `retry_on`, `discard_on`, `perform`, `perform_later`, and `perform_now`.
@:railsJob
@:queueAs("mailers")
@:retryOn("StandardError", {waitSeconds: 5, attempts: 3})
@:discardOn("ActiveJob::DeserializationError")
class SendWelcomeEmailJob extends rails.active_job.Base {
	public function perform(userId:Int, email:String):Void {
		var payload = "welcome:" + email;
		trace(payload);
	}
}
