package ruby;

/**
	Typed receiver contract for the binary Ruby `String` operations RubyHx uses.

	The separate Int and Float entrypoints keep `unpack1` result types explicit;
	callers cannot request an open-ended value or leak `Dynamic` into Haxe APIs.
**/
@:rubyPatch(String)
extern class BinaryString {
	@:native("byteslice")
	public static function byteSlice(receiver:String, start:Int, length:Int):String;

	@:native("unpack1")
	public static function unpackInt(receiver:String, format:BinaryFormat):Int;

	@:native("unpack1")
	public static function unpackFloat(receiver:String, format:BinaryFormat):Float;
}
