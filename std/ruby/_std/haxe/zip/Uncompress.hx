package haxe.zip;

/**
	Ruby implementation of Haxe's decompression API over the standard `zlib` gem.

	The typed `ruby.ArrayPacking` receiver contract keeps binary conversion local
	to this target boundary so Ruby strings do not leak into `haxe.io.Bytes` APIs.
	Like Haxe's PHP target, `execute` is one-shot; `windowBits`, `bufsize`, flush,
	and close do not retain or alter native state.
**/
@:coreApi
class Uncompress {
	public function new(?windowBits:Int) {}

	public function execute(src:haxe.io.Bytes, srcPos:Int, dst:haxe.io.Bytes, dstPos:Int):{done:Bool, read:Int, write:Int} {
		var input = src.sub(srcPos, src.length - srcPos);
		var data = run(input);
		dst.blit(dstPos, data, 0, data.length);
		return {done: true, read: input.length, write: data.length};
	}

	public function setFlushMode(f:FlushMode):Void {}

	public function close():Void {}

	public static function run(src:haxe.io.Bytes, ?bufsize:Int):haxe.io.Bytes {
		var input = ruby.ArrayPacking.packBytes(src.getData(), "C*");
		return haxe.io.Bytes.ofString(ruby.Zlib.Inflate.inflate(input));
	}
}
