import rails.test.ActionCableAssert.assertBroadcasts;
import rails.test.Dsl.test;
import rails.test.RequestTestCase;
import rails.turbo.StreamName;

class InvalidActionCableRspecMain {
	static function main():Void {
		var testClass:Class<InvalidActionCableRspecTest> = InvalidActionCableRspecTest;
	}
}

@:railsTest("requests/invalid_action_cable_rspec_spec")
@:railsTestAdapter("rails.rspec")
class InvalidActionCableRspecTest extends RequestTestCase {
	@:railsTests
	static function define():Void {
		test("does not guess a matcher", () -> {
			assertBroadcasts(StreamName.named("rooms:updates"), 1, () -> {});
		});
	}
}
