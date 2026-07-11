package haxe.zip;

/**
	Ruby implementation of Haxe's compression API over the standard `zlib` gem.

	Ruby Zlib exchanges binary `String` values, while RubyHx stores Haxe bytes as
	typed integer arrays. `ruby.ArrayPacking` models that target interop seam, so
	callers continue to use `haxe.io.Bytes` without an unchecked value.

	Like Haxe's PHP target, this compatibility surface executes each input in one
	shot; it retains only the compression level, so flush and close are no-ops.
**/
@:coreApi
class Compress {
	final level:Int;

	public function new(level:Int) {
		this.level = level;
	}

	public function execute(src:haxe.io.Bytes, srcPos:Int, dst:haxe.io.Bytes, dstPos:Int):{done:Bool, read:Int, write:Int} {
		var input = src.sub(srcPos, src.length - srcPos);
		var data = run(input, level);
		dst.blit(dstPos, data, 0, data.length);
		return {done: true, read: input.length, write: data.length};
	}

	public function setFlushMode(f:FlushMode):Void {}

	public function close():Void {}

	public static function run(s:haxe.io.Bytes, level:Int):haxe.io.Bytes {
		var input = ruby.ArrayPacking.packBytes(s.getData(), ruby.BinaryFormat.BytesUnsigned);
		return haxe.io.Bytes.ofString(ruby.Zlib.Deflate.deflate(input, level));
	}
}
