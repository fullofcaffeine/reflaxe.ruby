package test_haxe.models;

import rails.test.Assert.*;
import rails.test.Dsl.*;
import rails.test.ModelTestCase;

// Demonstrates the default RailsHx test adapter: omitting @:railsTestAdapter
// keeps Rails/Minitest output under test/generated/**/*_test.rb.
@:railsTest("models/adapter_model_haxe_test")
class AdapterModelHaxeTest extends ModelTestCase {
	@:railsTests
	static function define():Void {
		test("default adapter emits minitest", () -> {
			equal("typed", "typed");
			truthy(true);
		});
	}
}
