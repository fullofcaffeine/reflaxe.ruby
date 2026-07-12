/** Base declaration owns the block ABI used by overrides and recursive calls. **/
class BlockBase {
	public function new() {}

	@:rubyBlockArg
	public function visit(value:Int, block:Int->String):String {
		return block(value);
	}

	@:rubyBlockArg
	public function recursive(value:Int, block:Int->String):String {
		return value <= 0 ? block(value) : recursive(value - 1, block);
	}
}
