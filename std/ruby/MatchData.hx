package ruby;

/**
	Read-only typed facade for Ruby's native core `MatchData` value.

	Instances are returned by `ruby.Regexp.match`; callers cannot construct them.
	Indexed captures preserve Ruby's nullable unmatched-group behavior, while
	named captures are available as a typed inventory instead of an unchecked
	name lookup that could raise for an unknown string. Byte offsets, ranges,
	heterogeneous `values_at`, mutation, and global backreference state are omitted.
**/
@:native("MatchData")
extern class MatchData {
	/** Returns an indexed capture, or `null` when that group did not participate. **/
	@:native("match")
	public function capture(index:Int):Null<String>;

	/** Returns the character length of an indexed capture, preserving nullability. **/
	@:native("match_length")
	public function captureLength(index:Int):Null<Int>;

	/** Returns character offsets; an unmatched optional group yields `[nil, nil]`. **/
	public function offset(index:Int):MatchOffset;

	@:native("pre_match")
	public function before():String;

	@:native("post_match")
	public function after():String;

	public function captures():Array<Null<String>>;

	/** Returns every declared named capture and its nullable matched value. **/
	@:native("named_captures")
	public function namedCaptures():NativeHashData<String, Null<String>>;

	public function names():Array<String>;

	public function size():Int;

	/** Returns the complete target string used for this match. **/
	public function string():String;

	public function regexp():Regexp;

	@:native("to_a")
	public function toArray():Array<Null<String>>;

	/** Returns the complete matched substring. **/
	@:native("to_s")
	public function toString():String;
}
