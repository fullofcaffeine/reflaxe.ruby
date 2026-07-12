/** ActiveSupport::Concern variant of the same Haxe-owned typed block contract. **/
@:rubyConcern("BlockConcern")
class BlockConcern {
	@:rubyBlockArg
	public function decorateFromConcern(value:Int, block:Int->String):String {
		return block(value);
	}
}
