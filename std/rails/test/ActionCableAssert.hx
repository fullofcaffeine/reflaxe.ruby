package rails.test;

import rails.turbo.StreamName;

/**
	Typed Minitest assertions for Rails ActionCable broadcasts.

	Using one of these helpers in an `@:railsTest` body asks the compiler to
	include Rails' native `ActionCable::TestHelper` module in the generated test.
	The compiler then lowers the call directly to the matching block assertion;
	no RailsHx assertion runtime is emitted. RSpec is rejected until RailsHx has
	a separately verified matcher contract instead of guessing equivalent
	semantics.
**/
class ActionCableAssert {
	@:railsTestInclude("ActionCable::TestHelper")
	public static function assertBroadcasts<TLocals>(stream:StreamName<TLocals>, count:Int, body:Void->Void):Void {
		throw "rails.test.ActionCableAssert.assertBroadcasts must be lowered by reflaxe.ruby.";
	}
}
