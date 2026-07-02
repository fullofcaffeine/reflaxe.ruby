package unit;

/**
	Minimal upstream unitstd helper used by Map.unit.hx.

	The map fixture only needs one hash-code-aware key type and one plain object
	key type so RubyHx can prove both hashable and identity map semantics.
**/
class ClassWithHashCode {
	var i:Int;

	public function new(i:Int) {
		this.i = i;
	}

	public function hashCode():Int {
		return i;
	}
}

class ClassWithoutHashCode {
	public var i:Int;

	public function new(i:Int) {
		this.i = i;
	}
}
