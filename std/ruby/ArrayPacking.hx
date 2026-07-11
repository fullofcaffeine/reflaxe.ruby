package ruby;

/**
	Typed receiver contract for Ruby's binary `Array#pack` operation.

	Separate byte and float entrypoints retain element typing, while
	`ruby.BinaryFormat` restricts the format directives. Ruby output dispatches
	directly to the receiver without a wrapper or unchecked value.
**/
@:rubyPatch(Array)
extern class ArrayPacking {
	@:native("pack")
	public static function packBytes(receiver:Array<Int>, format:BinaryFormat):String;

	@:native("pack")
	public static function packFloats(receiver:Array<Float>, format:BinaryFormat):String;
}
