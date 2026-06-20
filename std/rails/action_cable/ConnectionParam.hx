package rails.action_cable;

/**
	Typed ActionCable connection request parameter token.

	Connection auth often reads a small number of request params or cookies.
	This token covers the checked request-param path without making raw strings
	part of the app-facing API. Cookie/session/warden facades can build on the
	same pattern as those auth seams harden.
**/
abstract ConnectionParam<TValue>(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static function named<TValue>(name:String):ConnectionParam<TValue> {
		return new ConnectionParam<TValue>(name);
	}
}
