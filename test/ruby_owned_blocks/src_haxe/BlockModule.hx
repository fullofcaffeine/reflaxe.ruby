/** A Haxe-owned Ruby module whose typed callback lowers to the receiver's block. **/
@:rubyModule("BlockModule")
class BlockModule {
	@:rubyBlockArg
	public function decorateFromModule(value:Int, block:Int->String):String {
		return block(value);
	}
}
