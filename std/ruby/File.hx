package ruby;

/**
	Typed facade for Ruby's core `File` class and bounded instance IO values.

	The instance contract is shared by direct `File.open(...)` results and
	resource-safe stdlib callbacks such as `Tempfile.create`. It intentionally
	omits open block/keyword forms and advanced IO operations instead of exposing
	them through `Dynamic`.
**/
@:native("File")
extern class File {
	@:native("read")
	public static function read(path:String):String;

	@:native("open")
	public static function open(path:String, ?mode:String):File;

	@:native("exist?")
	public static function exists(path:String):Bool;

	public function path():String;

	public function write(value:String):Int;

	@:native("read")
	public function readAll():String;

	public function read(length:Int):Null<String>;

	public function rewind():Int;

	public function flush():File;

	public function close():Void;

	@:native("closed?")
	public function isClosed():Bool;

	public function size():Int;
}
