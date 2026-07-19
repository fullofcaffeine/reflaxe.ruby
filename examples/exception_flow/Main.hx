// Exception flow smoke.
//
// Demonstrates: Haxe `throw`/`try`/`catch` lowering to Ruby exception control
// flow while preserving Haxe's typed catch value.
// Type safety: the catch binding is declared as `String`, so downstream code
// sees a typed `message` instead of an untyped Ruby exception object.
// IntelliSense: editors should expose String members on `message`.
// Ruby output: structural `raise`/`begin`/`rescue`, ordered Haxe type checks,
// and the hxruby exception carrier only when Ruby needs one.
import ruby.StandardError;

class Main {
	static var throwEvaluations:Int = 0;

	static function main():Void {
		try {
			fail();
			Sys.println("unreachable");
		} catch (message:String) {
			Sys.println(message);
		}

		Sys.println(classify("string"));
		Sys.println(classify(7));
		Sys.println(classify(true));
		Sys.println(valueFromTry(false));
		Sys.println(valueFromTry(true));
		try {
			onlyString(7);
		} catch (number:Int) {
			Sys.println("rethrown:" + number);
		}
		Sys.println(catchNativeError());
		Sys.println(catchWildcardException());
		Sys.println(catchNativeWildcardException());
		Sys.println(evaluateThrownValueOnce());
		Sys.println(rethrowNativeError());
		Sys.println(rethrowNativeWildcardException());
	}

	static function fail():Void {
		throw "boom";
	}

	static function classify(value:Dynamic):String {
		try {
			throw value;
		} catch (message:String) {
			return "string:" + message;
		} catch (number:Int) {
			return "int:" + number;
		} catch (_:Dynamic) {
			return "dynamic";
		}
	}

	static function valueFromTry(shouldThrow:Bool):String {
		return try {
			if (shouldThrow) {
				throw "value";
			}
			"try-value";
		} catch (message:String) {
			"catch:" + message;
		}
	}

	static function onlyString(value:Dynamic):String {
		try {
			throw value;
		} catch (message:String) {
			return message;
		}
		return "unreachable";
	}

	static function catchNativeError():String {
		try {
			haxe.Json.parse("{");
		} catch (_:String) {
			return "wrong-string-catch";
		} catch (_:StandardError) {
			return "native";
		}
		return "missing-native-error";
	}

	static function catchWildcardException():String {
		try {
			throw "wildcard";
		} catch (error:haxe.Exception) {
			return error.message;
		}
	}

	static function catchNativeWildcardException():String {
		try {
			haxe.Json.parse("{");
		} catch (error:haxe.Exception) {
			return "native-wildcard:" + (error.message.length > 0);
		}
		return "missing-native-wildcard";
	}

	static function evaluateThrownValueOnce():String {
		throwEvaluations = 0;
		try {
			throw nextThrownValue();
		} catch (message:String) {
			return "once:" + message + ":" + throwEvaluations;
		}
	}

	static function nextThrownValue():String {
		throwEvaluations++;
		return "once";
	}

	static function rethrowNativeError():String {
		try {
			try {
				haxe.Json.parse("{");
			} catch (error:Dynamic) {
				throw error;
			}
		} catch (_:StandardError) {
			return "native-rethrow";
		}
		return "missing-native-rethrow";
	}

	static function rethrowNativeWildcardException():String {
		try {
			try {
				haxe.Json.parse("{");
			} catch (error:haxe.Exception) {
				throw error;
			}
		} catch (_:StandardError) {
			return "native-wildcard-rethrow";
		}
		return "missing-native-wildcard-rethrow";
	}
}
