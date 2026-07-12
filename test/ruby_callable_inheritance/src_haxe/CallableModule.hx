/** Haxe-owned Ruby module whose included method may become a function value. **/
@:rubyModule("CallableModule")
class CallableModule {
	@:rubyBlockArg
	public function moduleVisit(value:Int, block:Int->String):String {
		return block(value);
	}
}
