/** Interface-owned Ruby block ABI; implementations inherit this metadata. **/
interface BlockApi {
	@:rubyBlockArg
	public function visit(value:Int, block:Int->String):String;
}
