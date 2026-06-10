package ruby;

@:native("Kernel")
extern class Kernel {
	public static function puts(value:Dynamic):Void;
	public static function print(value:Dynamic):Void;
}
