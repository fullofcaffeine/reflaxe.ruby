// End-to-end Ruby interop smoke.
//
// Demonstrates: combining native constants, `require`, keyword args, block args,
// symbols, and Kernel calls in one realistic Ruby boundary.
// Type safety: the Ruby boundary is modeled as extern classes, so Haxe checks
// method names, parameter shapes, callback signatures, and return types before
// Ruby is generated.
// IntelliSense: editors should complete the extern APIs exactly like normal
// Haxe classes while preserving Ruby names through metadata.
// Ruby output: direct `JSON`, `File`, and `RubyInterop` calls with Ruby-native
// kwargs/block syntax.
import ruby.Kernel;
import ruby.Symbol;

@:rubyRequire("json")
@:native("JSON")
extern class RubyJSON {
	@:native("generate")
	public static function encode(value:Dynamic):String;
}

@:native("File")
extern class RubyFile {
	@:native("basename")
	public static function baseName(path:String):String;
}

@:rubyRequireRelative("./support/ruby_interop")
@:native("RubyInterop")
extern class RubyInterop {
	@:rubyKwargs
	public static function describe(options:{name:String, count:Int}):String;

	@:rubyBlockArg
	public static function each(values:Array<Int>, block:Int->Void):Void;

	@:native("describe_details")
	@:rubyKwargs
	public static function describeDetails(options:{name:String, tags:Array<Symbol>, count:Int}):String;

	@:native("with_options")
	@:rubyKwargs
	@:rubyBlockArg
	public static function withOptions(values:Array<Int>, options:{prefix:String, tags:Array<Symbol>, count:Int}, block:Int->Void):Void;

	public static function accept_symbol(value:Symbol):String;
}

class Main {
	static function main() {
		var count = 3;
		Sys.println(RubyJSON.encode({name: "ruby", count: 2}));
		Sys.println(RubyFile.baseName("/tmp/reflaxe.rb"));
		Sys.println(RubyInterop.describe({name: "interop", count: 3}));
		Sys.println(RubyInterop.describeDetails({name: "interop", tags: [Symbol.of("safe"), Symbol.of("typed")], count: count}));
		RubyInterop.each([4, 5], function(value) {
			Sys.println(value);
		});
		RubyInterop.withOptions([6, 7], {prefix: "interop", tags: [Symbol.of("block")], count: count}, function(value) {
			Kernel.print("interop=");
			Sys.println(value);
		});
		Sys.println(RubyInterop.accept_symbol(Symbol.of("ready")));
		Kernel.puts("kernel");
	}
}
