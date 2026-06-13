// Native Ruby constant/method mapping smoke.
//
// Demonstrates: wrapping existing Ruby constants with `@:native` while exposing
// a Haxe-friendly API surface.
// Type safety: `RubyJSON.encode` and `RubyFile.baseName` are checked as Haxe
// static methods with declared argument/return types.
// IntelliSense: editors should complete `encode`/`baseName`; generated Ruby
// still calls `JSON.generate` and `File.basename`.
// Ruby output: direct calls to existing Ruby constants, not generated wrappers.
@:rubyRequire("json")
@:native("JSON")
extern class RubyJSON {
	@:native("generate")
	public static function encode(value:Dynamic):String;
}

@:native("File")
extern class RubyFile {
	@:native("basename")
	public static function baseName(path:String):String;
}

class Main {
	static function main() {
		Sys.println(RubyJSON.encode({name: "ruby", count: 2}));
		Sys.println(RubyFile.baseName("/tmp/reflaxe.rb"));
	}
}
