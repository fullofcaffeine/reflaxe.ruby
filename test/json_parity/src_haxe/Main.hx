/**
	Broader-suite haxe.Json parity runner for Ruby.

	The scalar/object/parser cases are adapted from upstream
	`tests/unit/src/unit/TestJson.hx`; invalid input comes from Issue4592, class
	pretty-printing from Issue11560, and replacer traversal from the documented
	`haxe.Json.stringify`/`haxe.format.JsonPrinter` contract.
**/
class Main {
	static function main():Void {
		var encoded = haxe.Json.stringify({x: -4500, y: 1.456, a: ["hello", "wor'\"\n\t\rd"]});
		var body = encoded.substr(1, encoded.length - 2);
		var parts = body.split(",");
		JsonParityAssert.isTrue(parts.remove('"x":-4500'), "integer field");
		JsonParityAssert.isTrue(parts.remove('"y":1.456'), "float field");
		JsonParityAssert.isTrue(parts.remove('"a":["hello"'), "array field");
		JsonParityAssert.isTrue(parts.remove('"wor\'\\"\\n\\t\\rd"]'), "escaped string field");
		JsonParityAssert.equal("", parts.join("#"), "object fragments");

		var scalars:Array<Dynamic> = [
			true,
			false,
			null,
			0,
			145,
			-145,
			0.15461,
			-485.15461,
			1e10,
			-1e-10,
			"",
			"hello",
			"he\n\r\t\\\\llo"
		];
		for (value in scalars) {
			JsonParityAssert.equal(value, haxe.Json.parse(haxe.Json.stringify(value)), "scalar round trip");
		}

		assertStableRoundTrip({field: 4});
		assertStableRoundTrip({test: {nested: null}});
		var mixed:Array<Dynamic> = [1, 2, 3, "str"];
		assertStableRoundTrip({array: mixed});

		JsonParityAssert.equal("é", haxe.Json.parse('"\\u00E9"'), "unicode escape");
		JsonParityAssert.equal("👽", haxe.Json.parse('"\\ud83d\\udc7d"'), "surrogate pair");
		JsonParityAssert.equal("null", haxe.Json.stringify(Math.POSITIVE_INFINITY), "positive infinity");
		JsonParityAssert.equal("null", haxe.Json.stringify(Math.NEGATIVE_INFINITY), "negative infinity");
		JsonParityAssert.equal("null", haxe.Json.stringify(Math.NaN), "NaN");
		JsonParityAssert.equal('"<fun>"', haxe.Json.stringify(function() {}), "root function");
		JsonParityAssert.equal('{"value":1}', haxe.Json.stringify({callback: function() {}, value: 1}), "object function field");
		JsonParityAssert.equal("1", haxe.Json.stringify(JsonParityChoice.Second), "enum index");
		JsonParityAssert.equal('{"one":{"two":"three"}}', haxe.Json.stringify({one: {two: "three"}}), "nested object");

		var replacerKeys:Array<String> = [];
		var replaced:Dynamic = haxe.Json.parse(haxe.Json.stringify({count: 2, values: [3]}, function(key:Dynamic, value:Dynamic):Dynamic {
			replacerKeys.push(Std.string(key));
			return Std.isOfType(value, Int) ? value * 2 : value;
		}));
		JsonParityAssert.equal(4, Reflect.field(replaced, "count"), "replacer object field");
		JsonParityAssert.equal(6, Reflect.field(replaced, "values")[0], "replacer array field");
		JsonParityAssert.isTrue(replacerKeys.indexOf("") >= 0, "replacer root key");
		JsonParityAssert.isTrue(replacerKeys.indexOf("count") >= 0, "replacer object key");
		JsonParityAssert.isTrue(replacerKeys.indexOf("0") >= 0, "replacer array index");

		var pretty = haxe.Json.stringify({one: {two: "three"}}, null, "\t");
		JsonParityAssert.isTrue(pretty.indexOf('\n\t"one": {') >= 0, "pretty object indent");
		JsonParityAssert.isTrue(pretty.indexOf('\n\t\t"two": "three"') >= 0, "pretty nested indent");

		var classJson = haxe.Json.stringify(new JsonParityChild(), "\t");
		JsonParityAssert.equal('{\n\t"anyVar": null\n}', classJson, "class field pretty printing");

		var invalidRaised = false;
		try {
			haxe.Json.parse('hello":"world"');
		} catch (_:Dynamic) {
			invalidRaised = true;
		}
		JsonParityAssert.isTrue(invalidRaised, "invalid JSON must raise");

		Sys.println("json-parity ok");
	}

	static function assertStableRoundTrip(value:Dynamic):Void {
		var encoded = haxe.Json.stringify(value);
		JsonParityAssert.equal(encoded, haxe.Json.stringify(haxe.Json.parse(encoded)), "structured round trip");
	}
}

/** Small assertion surface owned by the standalone broader-suite fixture. */
private class JsonParityAssert {
	public static function equal<T>(expected:T, actual:T, label:String):Void {
		if (actual != expected) {
			throw 'json parity failed: ${label}; expected ${expected}, got ${actual}';
		}
	}

	public static function isTrue(condition:Bool, label:String):Void {
		if (!condition) {
			throw 'json parity failed: ${label}';
		}
	}
}

@:keep
private class JsonParityParent {
	function anyFunc():Void {}

	public function new() {}
}

@:keep
private class JsonParityChild extends JsonParityParent {
	var anyVar:String = null;
}

private enum JsonParityChoice {
	First;
	Second;
}
