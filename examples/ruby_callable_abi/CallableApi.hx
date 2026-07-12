/**
	Pure RubyHx library that exposes Ruby-native callable shapes to both languages.

	Haxe callers always see ordinary typed function parameters. The compiler owns
	the Ruby implementation choice: direct callbacks become `yield`, while
	escaping, forwarded, and optional callbacks are represented by `&block`.
**/
class CallableApi {
	@:rubyBlockArg
	public static function direct(value:Int, block:Int->Int):Int {
		return block(value);
	}

	@:rubyBlockArg
	public static function capture(block:Int->Int):Int->Int {
		return block;
	}

	@:rubyBlockArg
	public static function forward(value:Int, block:Int->Int):Int {
		return direct(value, block);
	}

	@:rubyBlockArg
	public static function optional(value:Int, ?block:(Int->Int)):Int {
		return block == null ? value : block(value);
	}

	@:rubyKwargs
	@:rubyBlockArg
	public static function decorate(value:String, options:CallableOptions, block:String->String):String {
		return block(options.prefix + value + options.suffix);
	}
}
