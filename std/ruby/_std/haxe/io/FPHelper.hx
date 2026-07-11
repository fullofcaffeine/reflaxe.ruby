package haxe.io;

import haxe.Int64;

/**
	Ruby-backed IEEE-754 bit reinterpretation helpers used by `BytesBuffer`.

	Ruby already exposes the exact byte-level conversions we need through
	`Array#pack` and `String#unpack1`. Typed `ruby.ArrayPacking`,
	`ruby.BinaryString`, and `ruby.BinaryFormat` contracts keep those operations
	precise without `Dynamic`, casts, or raw Ruby injection, while avoiding Haxe
	std's portable scratch-object implementation.
**/
class FPHelper {
	public static function floatToI32(value:Float):Int {
		var packed = ruby.ArrayPacking.packFloats([value], ruby.BinaryFormat.Float32LittleEndian);
		return ruby.BinaryString.unpackInt(packed, ruby.BinaryFormat.Int32LittleEndian);
	}

	public static function i32ToFloat(value:Int):Float {
		var packed = ruby.ArrayPacking.packBytes([value], ruby.BinaryFormat.Int32LittleEndian);
		return ruby.BinaryString.unpackFloat(packed, ruby.BinaryFormat.Float32LittleEndian);
	}

	public static function doubleToI64(value:Float):Int64 {
		var packed = ruby.ArrayPacking.packFloats([value], ruby.BinaryFormat.Float64LittleEndian);
		var low = ruby.BinaryString.unpackInt(ruby.BinaryString.byteSlice(packed, 0, 4), ruby.BinaryFormat.Int32LittleEndian);
		var high = ruby.BinaryString.unpackInt(ruby.BinaryString.byteSlice(packed, 4, 4), ruby.BinaryFormat.Int32LittleEndian);
		return Int64.make(high, low);
	}

	public static function i64ToDouble(low:Int, high:Int):Float {
		var packed = ruby.ArrayPacking.packBytes([low, high], ruby.BinaryFormat.TwoInt32LittleEndian);
		return ruby.BinaryString.unpackFloat(packed, ruby.BinaryFormat.Float64LittleEndian);
	}
}
