package ruby;

/**
	Bounded typed facade for Ruby's native core `Regexp` class.

	Construction accepts only a String pattern and the closed common option set.
	`match()` returns native `MatchData` and updates Ruby's match globals as Ruby
	normally does; `matches()` maps to `match?` and deliberately avoids that global
	state. Patterns are executable matching programs: keep untrusted pattern and
	target sizes bounded and use `compileWith(...)` to set a per-instance timeout.

	Global last-match access, heterogeneous union, arbitrary option integers,
	encoding flags, byte offsets, and block-return overloads remain outside this
	precise cross-version surface.
**/
@:native("Regexp")
extern class Regexp {
	public function new(pattern:String, ?options:RegexpOptions);

	/** Constructs a regexp with explicit typed Ruby keyword configuration. **/
	@:native("new")
	@:rubyKwargs
	public static function compileWith(pattern:String, options:RegexpOptions, configuration:RegexpCompileOptions):Regexp;

	/** Escapes a literal String for safe inclusion in a larger trusted pattern. **/
	public static function escape(value:String):String;

	/** Matches from an optional character offset and updates Ruby match globals. **/
	public function match(value:String, ?offset:Int):Null<MatchData>;

	/** Tests from an optional character offset without updating Ruby match globals. **/
	@:native("match?")
	public function matches(value:String, ?offset:Int):Bool;

	public function source():String;

	public function names():Array<String>;

	/** Maps every declared capture name to its one or more numeric indexes. **/
	@:native("named_captures")
	public function namedCaptureIndexes():NativeHashData<String, Array<Int>>;

	/** Returns Ruby's complete option bits, including possible internal read-only bits. **/
	public function options():Int;

	@:native("casefold?")
	public function isCaseInsensitive():Bool;

	@:native("fixed_encoding?")
	public function hasFixedEncoding():Bool;

	/** Returns the per-instance timeout in seconds, or `null` for the class default. **/
	@:native("timeout")
	public function timeoutSeconds():Null<Float>;

	@:native("to_s")
	public function toString():String;
}
