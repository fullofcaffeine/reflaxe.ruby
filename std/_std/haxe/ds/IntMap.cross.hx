package haxe.ds;

class IntMap<T> implements haxe.Constraints.IMap<Int, T> {
	final data:Map<Int, T> = new Map();

	public function new() {}

	public function set(key:Int, value:T):Void data.set(key, value);

	public function get(key:Int):Null<T> return data.get(key);

	public function exists(key:Int):Bool return data.exists(key);

	public function remove(key:Int):Bool return data.remove(key);

	public function keys():Iterator<Int> return data.keys();

	public function iterator():Iterator<T> return data.iterator();

	public function keyValueIterator():KeyValueIterator<Int, T> return data.keyValueIterator();

	public function copy():IntMap<T> {
		var out = new IntMap<T>();
		for (key in keys()) {
			out.set(key, get(key));
		}
		return out;
	}

	public function toString():String return data.toString();

	public function clear():Void data.clear();
}
