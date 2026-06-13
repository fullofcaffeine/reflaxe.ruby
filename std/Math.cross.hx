package;

class Math {
	public static var PI(default, null):Float = untyped __ruby__("::Math::PI");
	public static var NEGATIVE_INFINITY(default, null):Float = untyped __ruby__("-Float::INFINITY");
	public static var POSITIVE_INFINITY(default, null):Float = untyped __ruby__("Float::INFINITY");
	public static var NaN(default, null):Float = untyped __ruby__("Float::NAN");

	public static function abs(v:Float):Float {
		return untyped __ruby__("{0}.abs", v);
	}

	public static function min(a:Float, b:Float):Float {
		return untyped __ruby__("HXRuby.math_min({0}, {1})", a, b);
	}

	public static function max(a:Float, b:Float):Float {
		return untyped __ruby__("HXRuby.math_max({0}, {1})", a, b);
	}

	public static function sin(v:Float):Float {
		return untyped __ruby__("HXRuby.math_unary(:sin, {0})", v);
	}

	public static function cos(v:Float):Float {
		return untyped __ruby__("HXRuby.math_unary(:cos, {0})", v);
	}

	public static function tan(v:Float):Float {
		return untyped __ruby__("HXRuby.math_unary(:tan, {0})", v);
	}

	public static function asin(v:Float):Float {
		return untyped __ruby__("HXRuby.math_unary(:asin, {0})", v);
	}

	public static function acos(v:Float):Float {
		return untyped __ruby__("HXRuby.math_unary(:acos, {0})", v);
	}

	public static function atan(v:Float):Float {
		return untyped __ruby__("HXRuby.math_unary(:atan, {0})", v);
	}

	public static function atan2(y:Float, x:Float):Float {
		return untyped __ruby__("HXRuby.math_binary(:atan2, {0}, {1})", y, x);
	}

	public static function exp(v:Float):Float {
		return untyped __ruby__("HXRuby.math_unary(:exp, {0})", v);
	}

	public static function log(v:Float):Float {
		return untyped __ruby__("HXRuby.math_unary(:log, {0})", v);
	}

	public static function pow(v:Float, exp:Float):Float {
		return untyped __ruby__("HXRuby.math_pow({0}, {1})", v, exp);
	}

	public static function sqrt(v:Float):Float {
		return untyped __ruby__("HXRuby.math_unary(:sqrt, {0})", v);
	}

	public static function round(v:Float):Int {
		return untyped __ruby__("HXRuby.math_round({0})", v);
	}

	public static function floor(v:Float):Int {
		return untyped __ruby__("{0}.floor", v);
	}

	public static function ceil(v:Float):Int {
		return untyped __ruby__("{0}.ceil", v);
	}

	public static function random():Float {
		return untyped __ruby__("rand");
	}

	public static inline function ffloor(v:Float):Float {
		return floor(v);
	}

	public static inline function fceil(v:Float):Float {
		return ceil(v);
	}

	public static inline function fround(v:Float):Float {
		return round(v);
	}

	public static function isFinite(f:Float):Bool {
		return untyped __ruby__("{0}.finite?", f);
	}

	public static function isNaN(f:Float):Bool {
		return untyped __ruby__("HXRuby.math_nan?({0})", f);
	}
}
