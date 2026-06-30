package haxe.io;

import haxe.Int64;

/**
	Ruby-backed IEEE-754 bit reinterpretation helpers used by `BytesBuffer`.

	Ruby already exposes the exact byte-level conversions we need through
	`Array#pack` and `String#unpack1`, so this target override keeps the boundary
	small and avoids emitting Haxe std's portable scratch-object implementation.
**/
class FPHelper {
	public static function floatToI32(value:Float):Int {
		return untyped __ruby__("[{0}].pack('e').unpack1('l<')", value);
	}

	public static function i32ToFloat(value:Int):Float {
		return untyped __ruby__("[{0}].pack('l<').unpack1('e')", value);
	}

	public static function doubleToI64(value:Float):Int64 {
		var low:Int = untyped __ruby__("[{0}].pack('E').byteslice(0, 4).unpack1('l<')", value);
		var high:Int = untyped __ruby__("[{0}].pack('E').byteslice(4, 4).unpack1('l<')", value);
		return Int64.make(high, low);
	}

	public static function i64ToDouble(low:Int, high:Int):Float {
		return untyped __ruby__("[{0}, {1}].pack('l<l<').unpack1('E')", low, high);
	}
}
