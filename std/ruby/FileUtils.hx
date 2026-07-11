package ruby;

/**
	Typed Haxe facade for Ruby's standard-library `FileUtils` module.

	The facade exposes a bounded single-path API with truthful return types and
	direct native calls. Ruby's list-input, keyword, permission, ownership,
	symlink, and block variants stay excluded so filesystem mutation does not
	widen into `Dynamic`, casts, raw Ruby, or a wrapper runtime.
**/
@:rubyRequire("fileutils")
@:native("FileUtils")
extern class FileUtils {
	@:native("cp")
	public static function copyFile(source:String, destination:String):Void;

	@:native("cp_r")
	public static function copyTree(source:String, destination:String):Void;

	@:native("mv")
	public static function move(source:String, destination:String):Void;

	@:native("mkdir")
	public static function makeDirectory(path:String):Array<String>;

	@:native("mkdir_p")
	public static function makeDirectories(path:String):Array<String>;

	@:native("rmdir")
	public static function removeDirectory(path:String):Array<String>;

	@:native("rm")
	public static function removeFile(path:String):Array<String>;

	/**
		Removes a file while suppressing `StandardError`, matching Ruby's `rm_f`.
		The force behavior is explicit in the Haxe name because failures beyond a
		missing path can be ignored by the native operation.
	**/
	@:native("rm_f")
	public static function forceRemoveFile(path:String):Array<String>;

	/**
		Recursively removes one entry through Ruby's TOCTTOU-resistant operation.

		Set `ignoreErrors` only when intentionally accepting Ruby's force behavior.
		The shorter `rm_r`/`rm_rf` APIs are omitted because Ruby documents a local
		race risk for them under attacker-writable parent directories.
	**/
	@:native("remove_entry_secure")
	public static function secureRemoveTree(path:String, ?ignoreErrors:Bool):Void;

	public static function touch(path:String):Array<String>;

	@:native("compare_file")
	public static function sameContents(first:String, second:String):Bool;

	@:native("uptodate?")
	public static function isUpToDate(output:String, inputs:Array<String>):Bool;
}
