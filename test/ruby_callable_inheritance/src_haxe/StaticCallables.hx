/** Static methods exercise first-class block and keyword adapters. **/
class StaticCallables {
	@:rubyBlockArg
	public static function decorate(value:Int, block:Int->String):String {
		return block(value);
	}

	@:rubyKwargs
	public static function label(options:CallableOptions):String {
		return options.prefix + (Reflect.hasField(options, "suffix") ? ":" + Std.string(options.suffix) : ":missing");
	}

	@:rubyBlockArg
	public static function optional(value:Int, ?block:Int->String):String {
		return block == null ? "optional:" + value : block(value);
	}

	@:rubyKwargs
	@:rubyBlockArg
	public static function compose(options:CallableOptions, block:String->String):String {
		return block(label(options));
	}

	public static function join(prefix:String, ...values:Int):String {
		return prefix + values.toArray().join(",");
	}
}
