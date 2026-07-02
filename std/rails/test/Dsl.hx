package rails.test;

/**
	Compiler-erased declaration DSL for Haxe-authored Rails tests.

	These functions are valid, typed Haxe calls so editors can complete them and
	the Haxe typer can check lambda bodies. The Ruby compiler consumes calls at
	the top level of an `@:railsTests static function define():Void` host and
	emits ordinary blocks for the selected Rails test adapter. If these methods
	reach runtime, the compiler missed a required lowering step.
**/
class Dsl {
	public static function test(description:TestDescription, body:Void->Void):Void {
		unlowered("test");
	}

	public static function setup(body:Void->Void):Void {
		unlowered("setup");
	}

	public static function teardown(body:Void->Void):Void {
		unlowered("teardown");
	}

	static function unlowered(name:String):Void {
		throw 'rails.test.Dsl.$name must be lowered by reflaxe.ruby.';
	}
}
