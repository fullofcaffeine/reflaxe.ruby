package ruby;

/**
	Typed lifecycle facade for Ruby's standard-library `Tempfile` API.

	Prefer the static `create*` methods: `@:rubyBlockArg` turns the typed Haxe
	callback into Ruby's native block form, whose `ensure` closes and removes the
	file. The constructor remains available when code genuinely needs a nominal
	`Tempfile`, but callers must finish that lifecycle with `closeAndUnlink()`.
**/
@:rubyRequire("tempfile")
@:native("Tempfile")
extern class Tempfile {
	public function new(?baseName:String, ?directory:String);

	/** Creates a scoped native file with Ruby's default generated basename. **/
	@:native("create")
	@:rubyBlockArg
	public static function createDefault<T>(block:File->T):T;

	/** Creates a scoped native file whose generated basename starts with `baseName`. **/
	@:native("create")
	@:rubyBlockArg
	public static function create<T>(baseName:String, block:File->T):T;

	/** Creates a scoped native file in the specified directory. **/
	@:native("create")
	@:rubyBlockArg
	public static function createIn<T>(baseName:String, directory:String, block:File->T):T;

	/** Returns `null` after the filesystem entry has been unlinked. **/
	public function path():Null<String>;

	public function write(value:String):Int;

	@:native("read")
	public function readAll():String;

	public function read(length:Int):Null<String>;

	public function rewind():Int;

	/** Flushes buffered data; the delegated native return value is intentionally hidden. **/
	public function flush():Void;

	public function close(?unlinkNow:Bool):Void;

	/**
		Closes the handle and unlinks its filesystem entry immediately.

		This is the required deterministic cleanup operation for constructor-created
		values; relying on Ruby's GC finalizer can leave files behind indefinitely.
	**/
	@:native("close!")
	public function closeAndUnlink():Void;

	public function unlink():Void;

	@:native("closed?")
	public function isClosed():Bool;

	public function size():Int;
}
