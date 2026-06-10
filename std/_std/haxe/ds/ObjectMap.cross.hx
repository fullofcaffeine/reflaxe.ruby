package haxe.ds;

import ruby.NativeHash;
import ruby.NativeIterator;

class ObjectMap<K:{}, V> implements haxe.Constraints.IMap<K, V> {
	final data:Dynamic;

	public function new() {
		data = NativeHash.create();
	}

	public function set(key:K, value:V):Void NativeHash.set(data, key, value);

	public function get(key:K):Null<V> return NativeHash.get(data, key);

	public function exists(key:K):Bool return NativeHash.exists(data, key);

	public function remove(key:K):Bool return NativeHash.remove(data, key);

	public function keys():Iterator<K> return new NativeIterator<K>(NativeHash.keys(data));

	public function iterator():Iterator<V> return new NativeIterator<V>(NativeHash.values(data));

	public function keyValueIterator():KeyValueIterator<K, V> return cast new NativeIterator<Dynamic>(NativeHash.entries(data));

	public function copy():ObjectMap<K, V> {
		var out = new ObjectMap<K, V>();
		NativeHash.copyInto(out.data, data);
		return out;
	}

	public function toString():String return NativeHash.toString(data);

	public function clear():Void NativeHash.clear(data);
}
