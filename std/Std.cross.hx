package;

class Std {
	public static function string<T>(value:T):String {
		return "" + value;
	}

	public static function parseInt(value:String):Null<Int> {
		return value == null ? null : 0;
	}

	public static function parseFloat(value:String):Float {
		return value == null ? Math.NaN : 0.0;
	}

	public static function is(value:Dynamic, type:Dynamic):Bool {
		return isOfType(value, type);
	}

	public static function isOfType(value:Dynamic, type:Dynamic):Bool {
		return untyped __is__(value, type);
	}

	public static function int(value:Float):Int {
		return cast value;
	}

	public static function downcast<T:S, S>(value:S, c:Class<T>):Null<T> {
		return isOfType(value, c) ? cast value : null;
	}

	public static function random(max:Int):Int {
		return max <= 0 ? 0 : cast Math.floor(Math.random() * max);
	}
}
