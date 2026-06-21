package rails.action_controller;

/**
	Typed `send_file` / `send_data` disposition token.

	Rails expects the wire values `"inline"` or `"attachment"`. This abstract
	keeps those values as strings in generated Ruby while giving Haxe users
	completion and preventing accidental booleans/objects at compile time.
**/
abstract SendDisposition(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline var inlineContent:SendDisposition = new SendDisposition("inline");
	public static inline var attachment:SendDisposition = new SendDisposition("attachment");
}
