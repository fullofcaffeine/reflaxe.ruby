class ClassWithToStringChild2 extends ClassWithToString {
	public function new() {
		super();
	}

	override public function toString():String {
		return "ClassWithToStringChild2.toString()";
	}
}
