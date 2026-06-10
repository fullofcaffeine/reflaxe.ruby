package haxe.ds;

class ObjectMap<K:{}, V> implements haxe.Constraints.IMap<K, V> {
	final data:Map<K, V> = new Map();

	public function new() {}

	public function set(key:K, value:V):Void data.set(key, value);

	public function get(key:K):Null<V> return data.get(key);

	public function exists(key:K):Bool return data.exists(key);

	public function remove(key:K):Bool return data.remove(key);

	public function keys():Iterator<K> return data.keys();

	public function iterator():Iterator<V> return data.iterator();

	public function keyValueIterator():KeyValueIterator<K, V> return data.keyValueIterator();

	public function copy():ObjectMap<K, V> {
		var out = new ObjectMap<K, V>();
		for (key in keys()) {
			out.set(key, get(key));
		}
		return out;
	}

	public function toString():String return data.toString();

	public function clear():Void data.clear();
}
