package haxe;

@:rubyRequire("json")
class Json {
	public static function parse(text:String):Dynamic {
		return untyped __ruby__("JSON.parse({0})", text);
	}

	public static function stringify(value:Dynamic, ?replacer:Dynamic, ?space:String):String {
		// Ruby JSON has no direct Haxe replacer callback equivalent. Fail loudly
		// until the target grows a real traversal adapter instead of ignoring it.
		if (replacer != null) {
			throw "haxe.Json.stringify replacer is not supported on Ruby yet";
		}
		if (space != null) {
			return untyped __ruby__("JSON.pretty_generate({0}, indent: {1})", value, space);
		}
		return untyped __ruby__("JSON.generate({0})", value);
	}
}
