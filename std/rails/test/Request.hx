package rails.test;

/**
	Typed request helpers for Haxe-authored Rails integration tests.

	These functions are compiler-erased facades. In `@:railsTest` sources they
	lower to ordinary ActionDispatch helpers such as `get(path)` and
	`post(path, params: {...})`, plus response inspection calls such as
	`response.body`; if they reach runtime, the compiler missed a required
	RailsHx lowering step.
**/
typedef RequestOptions<TParams, THeaders> = {
	@:optional var params:TParams;
	@:optional var headers:THeaders;
	@:optional var as:String;
}

class Request {
	public static function get<TParams, THeaders>(path:String, ?options:RequestOptions<TParams, THeaders>):Void {
		unlowered("get");
	}

	public static function post<TParams, THeaders>(path:String, ?options:RequestOptions<TParams, THeaders>):Void {
		unlowered("post");
	}

	public static function patch<TParams, THeaders>(path:String, ?options:RequestOptions<TParams, THeaders>):Void {
		unlowered("patch");
	}

	public static function delete<TParams, THeaders>(path:String, ?options:RequestOptions<TParams, THeaders>):Void {
		unlowered("delete");
	}

	public static function responseBody():String {
		unlowered("responseBody");
		return "";
	}

	public static function responseMediaType():Null<String> {
		unlowered("responseMediaType");
		return null;
	}

	static function unlowered(name:String):Void {
		throw 'rails.test.Request.$name must be lowered by reflaxe.ruby.';
	}
}
