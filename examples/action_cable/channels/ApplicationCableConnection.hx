package channels;

import rails.action_cable.Connection;
import rails.action_cable.ConnectionIdentifier;
import rails.action_cable.ConnectionParam;
import rails.macros.CableConnectionDsl.*;

typedef CurrentCableUser = {
	var id:Int;
}

// Demonstrates: a typed Haxe-owned ActionCable connection that emits a normal
// ActionCable::Connection::Base subclass.
// Type safety: `currentUser` and `authToken` are typed tokens. Raw strings cannot
// satisfy `identifiedBy(...)`, `assign(...)`, or `requestParam(...)`.
// Runtime seam: `rejectUnauthorizedConnection()` lowers to Rails'
// `reject_unauthorized_connection`, so Rails still owns accepted/rejected
// connection semantics.
// Rails output: this emits `identified_by :current_user`, `self.current_user =`,
// and `request.params["token"]`.

@:railsCableConnection
class ApplicationCableConnection extends Connection {
	public static final currentUser:ConnectionIdentifier<CurrentCableUser> = ConnectionIdentifier.named("currentUser");
	public static final authToken:ConnectionParam<String> = ConnectionParam.named("token");

	static final identifiers = {
		identifiedBy(currentUser);
	};

	public function connect():Void {
		if (requestParam(authToken) == "reject") {
			rejectUnauthorizedConnection();
			return;
		}
		assign(currentUser, {id: 42});
	}
}
