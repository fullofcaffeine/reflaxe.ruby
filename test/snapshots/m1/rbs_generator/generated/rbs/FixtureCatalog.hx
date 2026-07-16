package generated.rbs;

// Generated from catalog.rbs.
// Generated from deterministic RBS metadata.
// Unsupported or incomplete signatures are omitted with review markers; no broad fallback type is synthesized.
@:rubyRequire("fixture_catalog")
@:native("FixtureCatalog")
extern class FixtureCatalog {
	// Inferred from strict deterministic RBS metadata.
	public function new(?prefix:String):Void;
	// Inferred from strict deterministic RBS metadata.
	@:native("empty?")
	public function empty():Bool;
	// Inferred from strict deterministic RBS metadata.
	@:native("label_for")
	public function labelFor(key:String, ?count:Int):String;
	// Inferred from strict deterministic RBS metadata.
	@:native("maybe_label")
	public function maybeLabel(key:Null<String>):Null<String>;
	// Inferred from strict deterministic RBS metadata.
	@:native("nested_rows")
	public function nestedRows(rows:Array<Array<String>>):Array<Array<String>>;
	// Inferred from strict deterministic RBS metadata.
	public static function normalize(classValue:String):String;
}
