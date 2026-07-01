package ruby;

@:rubyRequire("json")
@:native("JSON")
extern class Json {
	@:native("parse")
	public static function parse(input:String):Dynamic;

	@:native("generate")
	public static function generate(value:Dynamic):String;

	@:native("pretty_generate")
	public static function prettyGenerate(value:Dynamic):String;
}
