package;

class Std {
	public static function string<T>(value:T):String {
		return untyped __ruby__("HXRuby.stringify({0})", value);
	}

	public static function parseInt(value:String):Null<Int> {
		return untyped __ruby__("HXRuby.parse_int({0})", value);
	}

	public static function parseFloat(value:String):Float {
		return untyped __ruby__("HXRuby.parse_float({0})", value);
	}

	public static function is(value:Dynamic, type:Dynamic):Bool {
		return isOfType(value, type);
	}

	public static function isOfType(value:Dynamic, type:Dynamic):Bool {
		return untyped __is__(value, type);
	}

	public static function int(value:Float):Int {
		return untyped __ruby__("{0}.to_i", value);
	}

	public static function downcast<T:S, S>(value:S, c:Class<T>):Null<T> {
		return isOfType(value, c) ? cast value : null;
	}

	public static function random(max:Int):Int {
		return untyped __ruby__("({0} <= 0 ? 0 : rand({0}))", max);
	}
}
