package ruby;

@:native("Kernel")
extern class Kernel {
	public static function puts<T>(value:T):Void;
	public static function print<T>(value:T):Void;
}
