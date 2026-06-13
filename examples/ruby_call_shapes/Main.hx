// Ruby call-shape interop smoke.
//
// Demonstrates: Ruby keyword arguments, block arguments, Ruby symbols, native
// method names, and direct Kernel extern calls from typed Haxe.
// Type safety: object-literal kwargs are checked by Haxe structural typing,
// block functions have typed parameters, and `Symbol.of(...)` avoids raw symbol
// strings at call sites.
// IntelliSense: editors should complete typed extern methods, required kwargs,
// block function signatures, and `Kernel` helpers.
// Ruby output: idiomatic Ruby calls such as `foo(name: ..., count: ...)`,
// block syntax, and `:symbol` literals.
import ruby.Kernel;
import ruby.Symbol;

@:rubyRequireRelative("./support/native_interop")
@:native("NativeInterop")
extern class NativeInterop {
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
		var count = 2;
		Sys.println(NativeInterop.describe({name: "ruby", count: 2}));
		Sys.println(NativeInterop.describeDetails({name: "ruby", tags: [Symbol.of("fast"), Symbol.of("typed")], count: count}));
		NativeInterop.each([1, 2], function(value) {
			Sys.println(value);
		});
		NativeInterop.withOptions([3, 4], {prefix: "item", tags: [Symbol.of("safe")], count: count}, function(value) {
			Kernel.print("item=");
			Sys.println(value);
		});
		Sys.println(NativeInterop.accept_symbol(Symbol.of("ready")));
		Kernel.puts("kernel");
	}
}
