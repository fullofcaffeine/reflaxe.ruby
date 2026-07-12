/**
	Typed contract for a Ruby-owned monkey patch that accepts a native block.

	The support Ruby file owns the actual String method; Haxe `using` supplies
	completion and type checking while generated calls remain direct dispatch.
**/
@:rubyRequireRelative("./support/string_block_patch")
@:rubyPatch(String)
extern class StringBlockPatch {
	@:rubyBlockArg
	public static function decorate(receiver:String, block:String->String):String;
}
