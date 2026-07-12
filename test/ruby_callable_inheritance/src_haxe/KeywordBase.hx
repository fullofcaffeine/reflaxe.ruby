/** Base declaration owns a keyword ABI with presence-sensitive optional data. **/
class KeywordBase {
	public function new() {}

	@:rubyKwargs
	public function configure(options:CallableOptions):String {
		return options.prefix + (Reflect.hasField(options, "suffix") ? ":" + Std.string(options.suffix) : ":missing");
	}
}
