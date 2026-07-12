/** Override intentionally omits metadata; the base method remains authoritative. **/
class BlockChild extends BlockBase {
	public function new() {
		super();
	}

	override public function visit(value:Int, block:Int->String):String {
		return "child:" + super.visit(value + 1, block);
	}
}
