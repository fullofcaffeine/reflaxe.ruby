package test_haxe.channels;

import channels.ApplicationCableConnection;
import rails.test.Assert.equal;
import rails.test.ConnectionTestCase;

/**
	Haxe-authored connection test proving accepted and rejected authentication
	through Rails' own `ActionCable::Connection::TestCase`. The nominal param and
	identifier tokens keep their value types in editor completion while generated
	Ruby remains ordinary Rails test code.
**/
@:railsConnectionTest(channels.ApplicationCableConnection)
@:railsTest("channels/application_cable_connection_haxe_test")
@:keep
class ApplicationCableConnectionHaxeTest extends ConnectionTestCase {
	@:test
	public function acceptsTheTypedConnection():Void {
		connectWithParam(ApplicationCableConnection.authToken, "ok");
		equal({id: 42}, connectionValue(ApplicationCableConnection.currentUser));
	}

	@:test
	public function rejectsTheTypedConnection():Void {
		assertRejectConnection(() -> {
			connectWithParam(ApplicationCableConnection.authToken, "reject");
		});
	}
}
