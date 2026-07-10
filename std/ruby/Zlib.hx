package ruby;

/** Typed access to Ruby's one-shot `Zlib::Deflate` compression API. */
@:rubyRequire("zlib")
@:native("Zlib::Deflate")
extern class Deflate {
	public static function deflate(input:String, level:Int):String;
}

/** Typed access to Ruby's one-shot `Zlib::Inflate` decompression API. */
@:rubyRequire("zlib")
@:native("Zlib::Inflate")
extern class Inflate {
	public static function inflate(input:String):String;
}
