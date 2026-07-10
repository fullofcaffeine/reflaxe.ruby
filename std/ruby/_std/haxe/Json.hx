package haxe;

@:rubyRequire("json")
/**
	Haxe JSON semantics over Ruby's native parser and generator.

	The runtime adapter is limited to behavior where Ruby JSON differs from the
	Haxe contract; valid parsing and final encoding remain native Ruby operations.
**/
class Json {
	public static function parse(text:String):Dynamic {
		// JSON values are deliberately open at this std API boundary. Ruby parser
		// failures cross Haxe try/catch through the compiler's StandardError rescue.
		return untyped __ruby__("JSON.parse({0})", text);
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
