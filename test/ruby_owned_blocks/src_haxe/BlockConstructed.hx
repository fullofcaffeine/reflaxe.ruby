/** Proves that a typed constructor callback is a native Ruby `new { ... }` block. **/
class BlockConstructed {
	public var rendered(default, null):String;

	@:rubyBlockArg
	public function new(value:Int, block:Int->String) {
		rendered = block(value);
	}
}
