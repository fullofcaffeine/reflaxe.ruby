package interop;

// Rails-owned Ruby constant adopted through a typed Haxe extern.
// Generated from sig/rbs_price_formatter.rbs.
// Generated from deterministic RBS metadata.
// Unsupported or incomplete signatures are omitted with review markers; no broad fallback type is synthesized.
@:native("RbsPriceFormatter")
extern class RbsPriceFormatter {
	// Inferred from strict deterministic RBS metadata.
	public function new(?currency:String):Void;
	// Inferred from strict deterministic RBS metadata.
	@:native("label_for")
	public function labelFor(kind:String, ?cents:Int):String;
	// Inferred from strict deterministic RBS metadata.
	@:native("maybe_label")
	public function maybeLabel(kind:Null<String>, ?cents:Null<Int>):Null<String>;
	// Inferred from strict deterministic RBS metadata.
	@:native("maybe_total")
	public function maybeTotal(amount:Null<Float>):Null<Float>;
	// Inferred from strict deterministic RBS metadata.
	@:native("normalize_tags")
	public function normalizeTags(labels:Array<String>):Array<String>;
	// Inferred from strict deterministic RBS metadata.
	@:native("maybe_symbols")
	public function maybeSymbols(symbols:Null<Array<ruby.Symbol>>):Null<Array<ruby.Symbol>>;
	// Review required: skipped unknown_shape: unsupported RBS parameter type for amount; use a supported scalar, nilable scalar, Symbol, or Array<T> contract (line 8).
	// Review required: skipped unknown_optional: unsupported RBS parameter type for amount; use a supported scalar, nilable scalar, Symbol, or Array<T> contract (line 9).
	// Review required: skipped open_input: unsupported RBS parameter type for payload; use a supported scalar, nilable scalar, Symbol, or Array<T> contract (line 10).
	// Review required: skipped open_return: unsupported RBS return type at line 11; use a supported scalar, nilable scalar, Symbol, Array<T>, or void contract.
	// Review required: skipped overloaded: overloaded RBS signatures at line 12 are outside the strict subset; expose one reviewed signature in a hand-maintained contract.
	// Inferred from strict deterministic RBS metadata.
	public static function call(cents:Int, ?includeSymbol:Bool):String;
	// Inferred from strict deterministic RBS metadata.
	@:native("parse_flag")
	public static function parseFlag(raw:Null<Bool>):Null<Bool>;
}
