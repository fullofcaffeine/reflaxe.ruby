package haxe;

@:rubyRequire("json")
/**
	Haxe JSON semantics over Ruby's native parser and generator.

	The runtime adapter is limited to behavior where Ruby JSON differs from the
	Haxe contract; valid parsing and final encoding remain native Ruby operations.
**/
class Json {
	public static function parse(text:String):Dynamic {
		// Ruby's parser error must cross the Haxe std boundary as a Haxe throw so
		// ordinary `catch (error:Dynamic)` code can observe invalid JSON.
		var parsed:Dynamic = untyped __ruby__("(begin [true, JSON.parse({0})]; rescue JSON::ParserError => error; [false, error]; end)", text);
		if (!parsed[0]) {
			throw parsed[1];
		}
		return parsed[1];
	}

	public static function stringify(value:Dynamic, ?replacer:Dynamic, ?space:String):String {
		// Some native-target callers historically pass pretty-print spacing as the
		// second argument. Keep that compatibility at this explicit Dynamic std seam.
		if (space == null && replacer != null && untyped __ruby__("{0}.is_a?(String)", replacer)) {
			space = untyped replacer;
			replacer = null;
		}
		// Ruby JSON owns encoding, while this adapter supplies the Haxe-only
		// replacer, non-finite-number, enum, and generated-class semantics.
		var prepared:Dynamic = untyped __ruby__("HXRuby.json_prepare({0}, {1})", value, replacer);
		if (space != null) {
			return untyped __ruby__("JSON.pretty_generate({0}, indent: {1})", prepared, space);
		}
		return untyped __ruby__("JSON.generate({0})", prepared);
	}
}
