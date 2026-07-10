package unitstd_ruby;

/** Focused Ruby Zlib checks beyond the authoritative upstream byte fixtures. */
class ZipSemantics {
	public static function run():Void {
		binaryBytesRoundTrip();
		invalidInputRaises();
	}

	static function binaryBytesRoundTrip():Void {
		var source = haxe.io.Bytes.alloc(5);
		for (entry in [
			{index: 0, value: 0},
			{index: 1, value: 127},
			{index: 2, value: 128},
			{index: 3, value: 255},
			{index: 4, value: 42}
		]) {
			source.set(entry.index, entry.value);
		}

		var compressed = haxe.zip.Compress.run(source, 9);
		var restored = haxe.zip.Uncompress.run(compressed);
		Assert.sameArray([0, 127, 128, 255, 42], [for (i in 0...restored.length) restored.get(i)], "Ruby Zlib should preserve arbitrary byte values");
	}

	static function invalidInputRaises():Void {
		Assert.raises(function() {
			haxe.zip.Uncompress.run(haxe.io.Bytes.ofString("not zlib data"));
		}, "Ruby Zlib should reject invalid compressed input");
	}
}
