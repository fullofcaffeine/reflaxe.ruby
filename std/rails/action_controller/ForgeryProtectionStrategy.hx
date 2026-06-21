package rails.action_controller;

/**
	Typed Rails `protect_from_forgery` strategy token.

	Rails expects symbols such as `:exception` or `:null_session`. The abstract
	keeps Haxe code completion/type-checking on the app-facing side while the
	compiler lowers the value to the normal Rails symbol in generated Ruby.
**/
abstract ForgeryProtectionStrategy(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline var exception:ForgeryProtectionStrategy = new ForgeryProtectionStrategy("exception");
	public static inline var nullSession:ForgeryProtectionStrategy = new ForgeryProtectionStrategy("null_session");
	public static inline var resetSession:ForgeryProtectionStrategy = new ForgeryProtectionStrategy("reset_session");
}
