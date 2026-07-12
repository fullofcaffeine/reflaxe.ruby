/** Unannotated override inherits the base bang name and block contract. **/
class NativeBlockChild extends NativeBlockBase {
	public function new() {
		super();
	}

	override public function transform(value:Int, block:Int->String):String {
		return "native:" + super.transform(value + 1, block);
	}
}
