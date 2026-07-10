package unit.spec;

/** Fixture helpers mirrored from upstream unit.spec.TestSpecification. */
class NonRttiClass {}

@:rtti
@:keepSub
class RttiClass1 {
	static var v:String;

	public function f() {
		return 33.0;
	}
}

class RttiClass2 extends RttiClass1 {}

class RttiClass3 extends RttiClass1 {
	override function f():Int {
		return 33;
	}
}
