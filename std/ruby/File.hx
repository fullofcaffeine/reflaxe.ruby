package ruby;

@:native("File")
extern class File {
	@:native("read")
	public static function read(path:String):String;

	@:native("open")
	public static function open(path:String):Dynamic;
}
