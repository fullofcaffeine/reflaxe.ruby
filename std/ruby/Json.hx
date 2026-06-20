package ruby;

@:rubyRequire("json")
@:native("JSON")
extern class Json {
	@:native("parse")
	public static function parse(input:String):Dynamic;
}
