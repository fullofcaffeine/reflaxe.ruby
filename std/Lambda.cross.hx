package;

class Lambda {
	public static function has<T>(it:Iterable<T>, value:T):Bool {
		for (item in it) {
			if (item == value) {
				return true;
			}
		}
		return false;
	}

	public static function count<T>(it:Iterable<T>, ?pred:T->Bool):Int {
		var count = 0;
		for (item in it) {
			if (pred == null || pred(item)) {
				count++;
			}
		}
		return count;
	}

	public static function array<T>(it:Iterable<T>):Array<T> {
		var out = [];
		for (item in it) {
			out.push(item);
		}
		return out;
	}
}
