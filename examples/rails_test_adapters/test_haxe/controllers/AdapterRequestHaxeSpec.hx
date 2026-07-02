package test_haxe.controllers;

import rails.action_controller.Status;
import rails.test.Assert.*;
import rails.test.Dsl.*;
import rails.test.Request.*;
import rails.test.RequestTestCase;

// Demonstrates RSpec request-spec lowering. Haxe authors keep typed request
// helper calls, and RailsHx emits ordinary RSpec request helper usage.
@:railsTestAdapter("rails.rspec")
@:railsTest("controllers/adapter_request_haxe_spec")
class AdapterRequestHaxeSpec extends RequestTestCase {
	@:railsTests
	static function define():Void {
		test("rspec adapter emits request expectations", () -> {
			get("/");
			assertResponse(Status.ok);
			includes(responseBody(), "ok");
		});
	}
}
