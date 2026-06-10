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
