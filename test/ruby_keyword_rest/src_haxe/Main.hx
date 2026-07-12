// Ruby rest/splat executable QA.
//
// Type safety and IntelliSense: `RestShapes` accepts only `Int` rest values,
// while both individual arguments and an `Array<Int>` spread are checked by
// Haxe. Generated Ruby should expose ordinary `*values` APIs to Ruby callers.
import KeywordShapes.KeywordOptions;

class Main {
	static var factoryCalls:Int = 0;

	static function main():Void {
		Sys.println(KeywordShapes.describe("inline", {requiredLabel: "ruby", retries: 1}));
		Sys.println(KeywordShapes.describe("inline-null", {requiredLabel: "ruby", retries: 2, note: null}));

		var stored:KeywordOptions = {requiredLabel: "stored", retries: 3, active: true};
		Sys.println(KeywordShapes.describe("stored", stored));
		Sys.println(new KeywordShapes().describeInstance(stored));

		var wider = {requiredLabel: "narrowed", retries: 4, extra: "not-a-keyword"};
		var narrowed:KeywordOptions = wider;
		Sys.println(KeywordShapes.describe("narrowed", narrowed));
		Sys.println(KeywordShapes.describe("factory", makeOptions()));
		Sys.println("factory-calls:" + factoryCalls);

		var explicitNull = KeywordShapes.passthrough({requiredLabel: "echo", retries: 6, note: null});
		var absent = KeywordShapes.passthrough({requiredLabel: "echo", retries: 7});
		Sys.println("echo-null:" + Reflect.hasField(explicitNull, "note") + ":" + Std.string(explicitNull.note));
		Sys.println("echo-absent:" + Reflect.hasField(absent, "note"));
		Sys.println(KeywordShapes.mutate({requiredLabel: "mutated", retries: 8}));
		Sys.println(KeywordShapes.transform({requiredLabel: "block", retries: 8}, value -> value.toUpperCase()));
		Sys.println(new KeywordConstructed({requiredLabel: "ctor", retries: 9}).rendered);

		Sys.println("predicate:" + KeywordShapes.ready());
		Sys.println(KeywordShapes.saveBang("record"));
		KeywordShapes.assignValue(10);
		Sys.println("assigned:" + KeywordShapes.assigned());

		Sys.println(RestShapes.join("inline", 1, 2));
		var stored = [3, 4];
		Sys.println(RestShapes.join("stored", ...stored));
		Sys.println(RestShapes.forward("forward", 5, 6));
		Sys.println(new RestShapes(...[7, 8]).values.join(","));
		Sys.println(new RestShapes().joinInstance("instance-rest", 9, 10));
	}

	static function makeOptions():KeywordOptions {
		factoryCalls++;
		return {requiredLabel: "made", retries: 5, note: "once"};
	}
}
