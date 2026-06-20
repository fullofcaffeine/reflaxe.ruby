package rails.action_cable;

/**
	Typed ActionCable connection identifier token.

	Rails stores connection identifiers as methods such as `current_user`.
	RailsHx keeps those names as typed tokens so connection classes and channels
	can share the same identifier without repeating raw strings. The token erases
	to the Rails identifier name; there is intentionally no `from String`
	conversion, so app code must declare identifiers in one checked place.
**/
abstract ConnectionIdentifier<TValue>(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static function named<TValue>(name:String):ConnectionIdentifier<TValue> {
		return new ConnectionIdentifier<TValue>(name);
	}
}
