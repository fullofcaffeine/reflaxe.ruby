/**
	Executable fixtures for the Haxe-owned side of Ruby's block ABI.

	Every method uses an ordinary typed Haxe function parameter. The compiler,
	not the author, chooses direct `yield` or captured `&block` output according
	to how the value is used.
**/
class OwnedBlocks {
	public function new() {}

	@:rubyBlockArg
	public static function direct<T>(value:Int, block:Int->T):T {
		return block(value);
	}

	@:rubyBlockArg
	public function instanceDirect<T>(value:Int, block:Int->T):T {
		return block(value);
	}

	@:rubyBlockArg
	public static function optional(value:Int, ?block:(Int->String)):String {
		if (block == null) {
			return "none";
		}
		return block(value);
	}

	@:rubyBlockArg
	public static function capture(block:Int->String):Int->String {
		return block;
	}

	@:rubyBlockArg
	public static function forward(value:Int, block:Int->String):String {
		return direct(value, block);
	}

	@:rubyBlockArg
	public static function nested(value:Int, block:Int->String):String {
		var invoke = () -> block(value);
		return invoke();
	}

	@:rubyBlockArg
	public static function sum(values:Array<Int>, block:Int->Int):Int {
		var total = 0;
		for (value in values) {
			total += block(value);
		}
		return total;
	}

	@:rubyBlockArg
	public static function zero(block:Void->String):String {
		return block();
	}

	@:rubyBlockArg
	public static function pair(left:Int, right:Int, block:Int->Int->Int):Int {
		return block(left, right);
	}
}
