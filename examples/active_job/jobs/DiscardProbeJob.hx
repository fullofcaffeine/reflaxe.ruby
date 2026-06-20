package jobs;

import rails.active_job.DeserializationError;
import rails.macros.JobDsl.*;

// Runtime discard probe for the generated Rails ActiveJob lane.
//
// Demonstrates: a typed Haxe job whose failure is handled by Rails
// `discard_on`, not by a RailsHx runtime wrapper.
// Type safety: `discardOn(DeserializationError)` reads the Ruby exception
// constant from a typed extern, and `performLater(recordId:Int)` is generated
// from the typed `perform` signature.
// Runtime behavior: the Rails test app performs this job and asserts that
// Rails' own ActiveJob::TestHelper records it as discarded.
@:railsJob
class DiscardProbeJob extends rails.active_job.Base {
	static final lifecycle = {
		queueAs("critical");
		discardOn(DeserializationError);
	}

	public function perform(recordId:Int):Void {
		DeserializationError.raise("discard:" + Std.string(recordId));
	}
}
