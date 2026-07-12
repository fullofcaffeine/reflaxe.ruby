/** Unannotated implementation proves the interface's callable ABI is effective. **/
class InterfaceWorker implements BlockApi {
	public function new() {}

	public function visit(value:Int, block:Int->String):String {
		return block(value + 1);
	}
}
