package;

import rails.test.ActionCableAssert.assertBroadcasts;
import rails.test.Dsl.test;
import rails.test.RequestTestCase;
import rails.turbo.StreamName;

/**
	Positive compiler fixture for the native ActionCable Minitest boundary.

	The typed call must both lower to `assert_broadcasts` and request
	`ActionCable::TestHelper` on the generated request test class.
**/
@:railsTest("controllers/hotwire_broadcast_request_test")
class BroadcastRequestTest extends RequestTestCase {
	@:railsTests
	static function define():Void {
		test("observes one typed stream broadcast", () -> {
			assertBroadcasts(StreamName.named("rooms:updates"), 1, () -> {});
		});
	}
}
