package haxe.ds;

import ruby.NativeHash;
import ruby.NativeHashData;
import ruby.NativeHashEntry;
import ruby.NativeIterator;

class StringMap<T> implements haxe.Constraints.IMap<String, T> {
	final data:NativeHashData<String, T>;

	public function new() {
		data = NativeHash.create();
	}

	public function set(key:String, value:T):Void
		NativeHash.set(data, key, value);

	public function get(key:String):Null<T>
		return NativeHash.get(data, key);

	public function exists(key:String):Bool
		return NativeHash.exists(data, key);

	public function remove(key:String):Bool
		return NativeHash.remove(data, key);

	public function keys():Iterator<String>
		return new NativeIterator<String>(NativeHash.keys(data));

	public function iterator():Iterator<T>
		return new NativeIterator<T>(NativeHash.values(data));

	public function keyValueIterator():KeyValueIterator<String, T>
		return new NativeIterator<NativeHashEntry<String, T>>(NativeHash.entries(data));

	public function copy():StringMap<T> {
		var out = new StringMap<T>();
		NativeHash.copyInto(out.data, data);
		return out;
	}

	public function toString():String
		return NativeHash.toString(data);

	public function clear():Void
		NativeHash.clear(data);
}
