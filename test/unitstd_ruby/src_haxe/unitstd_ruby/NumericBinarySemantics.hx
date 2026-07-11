package unitstd_ruby;

/**
	Focused Ruby numeric checks beyond the upstream Float/Int32/FPHelper fixtures.

	These assertions pin boundaries Ruby represents differently: signed zero is
	observable only through IEEE-754 bits/division, while Int32 unsigned ordering
	must not inherit Ruby Integer's arbitrary-precision comparison.
**/
class NumericBinarySemantics {
	public static function run():Void {
		signedZeroBitsRoundTrip();
		doubleSpecialValuesRoundTrip();
		int32UnsignedComparisonUsesBits();
	}

	static function signedZeroBitsRoundTrip():Void {
		var negativeZero = haxe.io.FPHelper.i32ToFloat(0x80000000);
		Assert.isTrue(haxe.io.FPHelper.floatToI32(negativeZero) == 0x80000000, "FPHelper should preserve the Float32 negative-zero sign bit");
		Assert.isTrue(1.0 / negativeZero == Math.NEGATIVE_INFINITY, "Float32 negative zero should remain observable through division");

		var bits = haxe.io.FPHelper.doubleToI64(-0.0);
		Assert.isTrue(bits.low == 0 && bits.high == 0x80000000, "FPHelper should preserve the Float64 negative-zero sign bit");
		Assert.isTrue(1.0 / haxe.io.FPHelper.i64ToDouble(bits.low, bits.high) == Math.NEGATIVE_INFINITY,
			"Float64 negative zero should survive its exact bit round trip");
	}

	static function doubleSpecialValuesRoundTrip():Void {
		for (value in [Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NaN]) {
			var bits = haxe.io.FPHelper.doubleToI64(value);
			var restored = haxe.io.FPHelper.i64ToDouble(bits.low, bits.high);
			Assert.isTrue(Math.isNaN(value) ? Math.isNaN(restored) : restored == value, "FPHelper should round-trip Float64 special values");
		}
	}

	static function int32UnsignedComparisonUsesBits():Void {
		var minusOne:haxe.Int32 = -1;
		var zero:haxe.Int32 = 0;
		Assert.isTrue(haxe.Int32.ucompare(minusOne, zero) > 0, "Int32.ucompare should treat -1 as unsigned 0xffffffff");
		Assert.isTrue(haxe.Int32.ucompare(zero, minusOne) < 0, "Int32.ucompare should order zero before unsigned 0xffffffff");
	}
}
