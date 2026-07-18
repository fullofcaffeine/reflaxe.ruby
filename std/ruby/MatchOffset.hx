package ruby;

/**
	Erased typed view of Ruby's two-element `MatchData#offset` result.

	Ruby returns `[nil, nil]` when an optional capture did not participate. This
	abstract names the two positions without allocating a wrapper or exposing a
	mutable array as the app-facing contract. An invalid capture index still raises
	Ruby's normal `IndexError` before this value is returned. `@:rubyNoEmit`
	removes the otherwise-empty abstract shell after these inline reads erase.
**/
@:rubyNoEmit
extern abstract MatchOffset(Array<Null<Int>>) {
	public inline function start():Null<Int> {
		return this[0];
	}

	public inline function finish():Null<Int> {
		return this[1];
	}

	public inline function isMatched():Bool {
		return this[0] != null;
	}
}
