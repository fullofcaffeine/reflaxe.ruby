package ruby;

/**
	Typed receiver contract for Ruby's binary `Array#pack` operation.

	Haxe callers retain `Array<Int>` element typing, while Ruby output dispatches
	directly to the receiver without a wrapper or unchecked binary-string value.
**/
@:rubyPatch(Array)
extern class ArrayPacking {
	@:native("pack")
	public static function packBytes(receiver:Array<Int>, format:String):String;
}
