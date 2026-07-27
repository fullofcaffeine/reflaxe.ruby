package rails.test;

import rails.action_cable.ConnectionIdentifier;
import rails.action_cable.ConnectionParam;

/**
	Typed marker base for Haxe-authored ActionCable connection tests.

	`@:railsConnectionTest(ConnectionType)` binds the declaration to one real
	`@:railsCableConnection` owner. The compiler erases this authoring facade and
	emits Rails' native `ActionCable::Connection::TestCase`; parameter and
	identifier tokens preserve their value types without introducing a RailsHx
	connection-test runtime.
**/
class ConnectionTestCase {
	public function new() {}

	@:railsActionCableTestConnect
	public function connectWithParam<TValue>(param:ConnectionParam<TValue>, value:TValue):Void {}

	@:railsActionCableTestConnectionValue
	public function connectionValue<TValue>(identifier:ConnectionIdentifier<TValue>):TValue {
		return cast null;
	}

	@:railsActionCableTestReject
	public function assertRejectConnection(body:Void->Void):Void {}
}
