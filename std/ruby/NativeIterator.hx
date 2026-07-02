package ruby;

@:rubyAllowRaw
class NativeIterator<T> {
	final values:Array<T>;
	var index:Int = 0;

	public function new(values:Array<T>) {
		this.values = values;
	}

	public function hasNext():Bool {
		return untyped __ruby__("{0} < {1}.length", index, values);
	}

	public function next():T {
		var value:T = untyped __ruby__("{0}[{1}]", values, index);
		index = index + 1;
		return value;
	}
}
