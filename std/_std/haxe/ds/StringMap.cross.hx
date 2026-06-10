package haxe.ds;

class StringMap<T> implements haxe.Constraints.IMap<String, T> {
	final data:Map<String, T> = new Map();

	public function new() {}

	public function set(key:String, value:T):Void data.set(key, value);

	public function get(key:String):Null<T> return data.get(key);

	public function exists(key:String):Bool return data.exists(key);

	public function remove(key:String):Bool return data.remove(key);

	public function keys():Iterator<String> return data.keys();

	public function iterator():Iterator<T> return data.iterator();

	public function keyValueIterator():KeyValueIterator<String, T> return data.keyValueIterator();

	public function copy():StringMap<T> {
		var out = new StringMap<T>();
		for (key in keys()) {
			out.set(key, get(key));
		}
		return out;
	}

	public function toString():String return data.toString();

	public function clear():Void data.clear();
}
