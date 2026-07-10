package unit.spec;

/**
	Fixture helpers mirrored from upstream unit.spec.TestSpecification.

	Keeping these helpers in the upstream package preserves the class names that
	Type.unit.hx asserts while the combined Ruby lane expands specs from Main.
**/
@:keep
class C {
	public function func():Void {}

	public var v:String;
	public var prop(default, null):String;

	static function staticFunc():Void {}

	public static var staticVar:String;
	static var staticProp(default, null):String;

	public function new() {
		v = "var";
		prop = "prop";
		staticVar = "staticVar";
		staticProp = "staticProp";
	}
}

@:keep
class C2 {
	public var v:String;
	public var prop(default, null):String;
	@:isVar public var propAcc(get, set):String;

	public function new() {
		v = "var";
		prop = "prop";
		propAcc = "0";
	}

	public function func():String {
		return "foo";
	}

	public function get_propAcc():String {
		return "1";
	}

	public function set_propAcc(value:String):String {
		return this.propAcc = value.toUpperCase();
	}
}

class CChild extends C {}

class EmptyClass {
	public function new() {}
}

@:keep
class ReallyEmptyClass {}

@:keep
class ClassWithCtorDefaultValues {
	public var a:Null<Int>;
	public var b:String;

	public function new(a = 1, b = "foo") {
		this.a = a;
		this.b = b;
	}
}

class ClassWithCtorDefaultValuesChild extends ClassWithCtorDefaultValues {}

@:keep
class ClassWithCtorDefaultValues2 {
	public var a:Null<Float>;
	public var b:String;

	public function new(a = 1.1, b = "foo") {
		this.a = a;
		this.b = b;
	}
}
