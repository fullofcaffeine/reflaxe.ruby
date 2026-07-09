package haxe.ds;

import ruby.NativeHash;
import ruby.NativeHashData;
import ruby.NativeHashEntry;
import ruby.NativeIterator;

class IntMap<T> implements haxe.Constraints.IMap<Int, T> {
	final data:NativeHashData<Int, T>;

	public function new() {
		data = NativeHash.create();
	}

	public function set(key:Int, value:T):Void
		NativeHash.set(data, key, value);

	public function get(key:Int):Null<T>
		return NativeHash.get(data, key);

	public function exists(key:Int):Bool
		return NativeHash.exists(data, key);

	public function remove(key:Int):Bool
		return NativeHash.remove(data, key);

	public function keys():Iterator<Int>
		return new NativeIterator<Int>(NativeHash.keys(data));

	public function iterator():Iterator<T>
		return new NativeIterator<T>(NativeHash.values(data));

	public function keyValueIterator():KeyValueIterator<Int, T>
		return new NativeIterator<NativeHashEntry<Int, T>>(NativeHash.entries(data));

	public function copy():IntMap<T> {
		var out = new IntMap<T>();
		NativeHash.copyInto(out.data, data);
		return out;
	}

	public function toString():String
		return NativeHash.toString(data);

	public function clear():Void
		NativeHash.clear(data);
}
