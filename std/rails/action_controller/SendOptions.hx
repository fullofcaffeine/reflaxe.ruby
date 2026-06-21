package rails.action_controller;

/**
	Typed Rails `send_file` / `send_data` options.

	Why: Rails accepts a keyword hash here, but app-facing Haxe should not pass
	raw strings for status/disposition when a small typed token catches mistakes
	before the request hits Rails. The compiler lowers this object to ordinary
	Rails kwargs such as `filename: "todos.csv", disposition: "attachment"`.
**/
typedef SendOptions = {
	@:optional var filename:String;
	@:optional var type:String;
	@:optional var disposition:SendDisposition;
	@:optional var status:Status;
}
