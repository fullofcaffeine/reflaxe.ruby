package ruby;

/**
	Typed, capture-only facade for Ruby's Open3 library.

	`Open3Executable` forces Ruby's direct-exec command form, and the final Haxe
	rest parameter lowers to a native Ruby splat. The result stays a fixed,
	property-only `Open3Capture`, so the heterogeneous Ruby tuple never leaks into
	application code. Shell command lines, process option hashes, stdin keywords,
	streaming handles, and pipelines remain outside this bounded contract.
**/
@:rubyRequire("open3")
@:native("Open3")
extern class Open3 {
	@:native("capture3")
	public static function capture(executable:Open3Executable, ...arguments:String):Open3Capture;
}
