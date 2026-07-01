package;

class Lambda {
	public static function array<T>(it:Iterable<T>):Array<T> {
		var out = [];
		for (item in it) {
			out.push(item);
		}
		return out;
	}

	public static function list<T>(it:Iterable<T>):List<T> {
		var out = new List<T>();
		for (item in it) {
			out.add(item);
		}
		return out;
	}

	public static function map<T, S>(it:Iterable<T>, f:T->S):Array<S> {
		var out = [];
		for (item in it) {
			out.push(f(item));
		}
		return out;
	}

	public static function mapi<T, S>(it:Iterable<T>, f:Int->T->S):Array<S> {
		var out = [];
		var index = 0;
		for (item in it) {
			out.push(f(index, item));
			index++;
		}
		return out;
	}

	public static function has<T>(it:Iterable<T>, value:T):Bool {
		for (item in it) {
			if (item == value) {
				return true;
			}
		}
		return false;
	}

	public static function exists<T>(it:Iterable<T>, f:T->Bool):Bool {
		for (item in it) {
			if (f(item)) {
				return true;
			}
		}
		return false;
	}

	public static function foreach<T>(it:Iterable<T>, f:T->Bool):Bool {
		for (item in it) {
			if (!f(item)) {
				return false;
			}
		}
		return true;
	}

	public static function iter<T>(it:Iterable<T>, f:T->Void):Void {
		for (item in it) {
			f(item);
		}
	}

	public static function filter<T>(it:Iterable<T>, f:T->Bool):Array<T> {
		var out = [];
		for (item in it) {
			if (f(item)) {
				out.push(item);
			}
		}
		return out;
	}

	public static function fold<T, S>(it:Iterable<T>, f:T->S->S, first:S):S {
		var accumulator = first;
		for (item in it) {
			accumulator = f(item, accumulator);
		}
		return accumulator;
	}

	public static function foldi<T, S>(it:Iterable<T>, f:T->S->Int->S, first:S):S {
		var accumulator = first;
		var index = 0;
		for (item in it) {
			accumulator = f(item, accumulator, index);
			index++;
		}
		return accumulator;
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

	public static function empty<T>(it:Iterable<T>):Bool {
		return !it.iterator().hasNext();
	}

	public static function indexOf<T>(it:Iterable<T>, value:T):Int {
		var index = 0;
		for (item in it) {
			if (item == value) {
				return index;
			}
			index++;
		}
		return -1;
	}

	public static function find<T>(it:Iterable<T>, f:T->Bool):Null<T> {
		for (item in it) {
			if (f(item)) {
				return item;
			}
		}
		return null;
	}

	public static function findIndex<T>(it:Iterable<T>, f:T->Bool):Int {
		var index = 0;
		for (item in it) {
			if (f(item)) {
				return index;
			}
			index++;
		}
		return -1;
	}

	public static function concat<T>(a:Iterable<T>, b:Iterable<T>):Array<T> {
		var out = [];
		for (item in a) {
			out.push(item);
		}
		for (item in b) {
			out.push(item);
		}
		return out;
	}
}
