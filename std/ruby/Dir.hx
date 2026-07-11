package ruby;

/**
	Typed Haxe facade for Ruby's core `Dir` class.

	The facade maps a focused set of directory queries and process operations to
	direct `Dir.*` calls. Open block, keyword, encoding, and multi-pattern forms
	are deliberately excluded so callers keep precise parameter and return types
	without `Dynamic`, casts, raw Ruby, or a wrapper runtime.
**/
@:native("Dir")
extern class Dir {
	@:native("pwd")
	public static function current():String;

	/**
		Changes Ruby's process-wide working directory and returns Ruby's integer
		status. Callers that need scoped restoration must save `current()` and
		restore it explicitly; the block-returning Ruby overload is not modeled by
		this bounded facade.
	**/
	@:native("chdir")
	public static function changeCurrent(path:String):Int;

	public static function home(?user:String):String;

	public static function entries(path:String):Array<String>;

	public static function children(path:String):Array<String>;

	/**
		Expands one Ruby glob pattern with an optional integer flag mask. Ruby's
		array-pattern and keyword options stay outside this overload because they
		require distinct typed contracts rather than a broad catch-all argument.
	**/
	public static function glob(pattern:String, ?flags:Int):Array<String>;

	@:native("exist?")
	public static function exists(path:String):Bool;

	@:native("empty?")
	public static function isEmpty(path:String):Bool;
}
