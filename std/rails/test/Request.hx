package rails.test;

/**
	Typed request helpers for Haxe-authored Rails integration tests.

	These functions are compiler-erased facades. In `@:railsTest` sources they
	lower to ordinary ActionDispatch helpers such as `get(path)` and
	`post(path, params: {...})`; if they reach runtime, the compiler missed a
	required RailsHx lowering step.
**/
typedef RequestOptions = {
	@:optional var params:Dynamic;
	@:optional var headers:Dynamic;
	@:optional var as:String;
}

class Request {
	public static function get(path:String, ?options:RequestOptions):Void {
		unlowered("get");
	}

	public static function post(path:String, ?options:RequestOptions):Void {
		unlowered("post");
	}

	public static function patch(path:String, ?options:RequestOptions):Void {
		unlowered("patch");
	}

	public static function delete(path:String, ?options:RequestOptions):Void {
		unlowered("delete");
	}

	static function unlowered(name:String):Void {
		throw 'rails.test.Request.$name must be lowered by reflaxe.ruby.';
	}
}
