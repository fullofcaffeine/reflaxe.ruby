/** Base callable owns both a Ruby bang name and block ABI. **/
class NativeBlockBase {
	public function new() {}

	@:native("transform!")
	@:rubyBlockArg
	public function transform(value:Int, block:Int->String):String {
		return block(value);
	}
}
