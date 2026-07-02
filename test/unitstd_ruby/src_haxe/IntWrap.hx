/**
	Minimal upstream unitstd helper used by Array.unit.hx.

	The Haxe upstream suite declares this inside its broader test specification
	module. The Ruby lane keeps only the deterministic value wrapper needed by
	ArraySort and identity-sensitive array mutation assertions.
**/
class IntWrap {
	public var i(default, null):Int;

	public function new(i:Int) {
		this.i = i;
	}

	public static function compare(a:IntWrap, b:IntWrap):Int {
		return if (a.i == b.i) 0; else if (a.i > b.i) 1; else -1;
	}
}
