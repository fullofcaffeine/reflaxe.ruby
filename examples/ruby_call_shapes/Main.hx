// Ruby call-shape interop smoke.
//
// Demonstrates: Ruby keyword arguments, block arguments, Ruby symbols, native
// method names, first-class method values, and direct Kernel extern calls from
// typed Haxe.
// Type safety: inline and stored kwargs are checked by Haxe structural typing;
// `@:optional` plus field-level `@:native` preserves optional Ruby labels;
// block functions have typed parameters; and `Symbol.of(...)` avoids raw
// symbol strings at call sites.
// IntelliSense: editors should complete typed extern methods, required/optional
// kwargs, block function signatures, captured method-value signatures, and
// `Kernel` helpers.
// Ruby output: idiomatic Ruby calls such as `foo(name: ..., count: ...)`,
// block syntax, and `:symbol` literals. Captured methods alone receive a small
// documented lambda that restores Ruby keywords/blocks at invocation.
import ruby.Kernel;
import ruby.Symbol;

typedef OptionalDescribeOptions = {
	var name:String;
	var count:Int;

	@:optional
	@:native("label_text")
	var label:Null<String>;
}

@:rubyRequireRelative("./support/native_interop")
@:native("NativeInterop")
extern class NativeInterop {
	@:rubyKwargs
	public static function describe(options:{name:String, count:Int}):String;

	@:native("describe_optional")
	@:rubyKwargs
	public static function describeOptional(options:OptionalDescribeOptions):String;

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
		Sys.println(NativeInterop.describeOptional({name: "inline", count: 3}));
		var stored:OptionalDescribeOptions = {name: "stored", count: 4, label: null};
		Sys.println(NativeInterop.describeOptional(stored));
		var describeValue = NativeInterop.describeOptional;
		Sys.println(describeValue({name: "captured", count: 5}));
		Sys.println(NativeInterop.describeDetails({name: "ruby", tags: [Symbol.of("fast"), Symbol.of("typed")], count: count}));
		NativeInterop.each([1, 2], function(value) {
			Sys.println(value);
		});
		var eachValue = NativeInterop.each;
		eachValue([6], value -> Sys.println(value));
		NativeInterop.withOptions([3, 4], {prefix: "item", tags: [Symbol.of("safe")], count: count}, function(value) {
			Kernel.print("item=");
			Sys.println(value);
		});
		Sys.println(NativeInterop.accept_symbol(Symbol.of("ready")));
		Kernel.puts("kernel");
	}
}
