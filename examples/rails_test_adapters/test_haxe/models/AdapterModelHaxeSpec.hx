package test_haxe.models;

import rails.test.Assert.*;
import rails.test.Dsl.*;
import rails.test.ModelTestCase;

// Demonstrates the optional RSpec adapter. The Haxe assertion DSL stays typed
// and compiler-erased, while Ruby output becomes an RSpec model spec.
@:railsTestAdapter("rails.rspec")
@:railsTest("models/adapter_model_haxe_spec")
class AdapterModelHaxeSpec extends ModelTestCase {
	@:railsTests
	static function define():Void {
		setup(() -> {
			truthy(true);
		});

		test("rspec adapter emits model expectations", () -> {
			equal(3, 1 + 2);
			notEqual("typed", "dynamic");
			includes(["typed", "rails"], "rails");
			nilValue((null : Null<String>));
			notNil("value");
			assertDifference(() -> 1, 0, () -> {
				truthy(true);
			});
			assertNoDifference(() -> 1, () -> {
				truthy(true);
			});
		});
	}
}
