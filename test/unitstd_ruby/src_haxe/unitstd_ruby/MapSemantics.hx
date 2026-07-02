package unitstd_ruby;

/**
	Focused RubyHx map checks for native Ruby Hash-backed std maps.

	Upstream `Map.unit.hx` owns broad Haxe parity; these checks pin the Ruby
	backend seams that are easy to regress: insertion order, object identity, and
	`KeyValueIterable` lowering through the compiler.
**/
class MapSemantics {
	public static function run():Void {
		stringMapKeepsRubyHashOrder();
		objectMapKeepsIdentityKeys();
		keyValueIterableDispatchesToMapReceiver();
	}

	static function stringMapKeepsRubyHashOrder():Void {
		var map = new haxe.ds.StringMap<Int>();
		map.set("first", 1);
		map.set("second", 2);
		map.set("third", 3);

		Assert.sameArray(["first", "second", "third"], [for (key in map.keys()) key], "StringMap keys should preserve Ruby Hash insertion order");
		Assert.sameArray([1, 2, 3], [for (value in map.iterator()) value], "StringMap values should preserve Ruby Hash insertion order");
		Assert.sameArray(["first:1", "second:2", "third:3"], [for (key => value in map) key + ":" + Std.string(value)],
			"StringMap keyValueIterator should preserve entry order");
	}

	static function objectMapKeepsIdentityKeys():Void {
		var first = {id: 1};
		var sameShape = {id: 1};
		var map = new haxe.ds.ObjectMap<{id:Int}, String>();
		map.set(first, "first");
		map.set(sameShape, "same-shape");

		Assert.isTrue(map.exists(first), "ObjectMap should find the original object key");
		Assert.isTrue(map.exists(sameShape), "ObjectMap should keep a distinct same-shape object key");
		Assert.isTrue(map.get(first) == "first", "ObjectMap should not conflate same-shape object keys");
		Assert.isTrue(map.get(sameShape) == "same-shape", "ObjectMap should preserve object key identity");
		Assert.sameArray(["first", "same-shape"], [for (value in map.iterator()) value], "ObjectMap should preserve object insertion order");
	}

	static function keyValueIterableDispatchesToMapReceiver():Void {
		var map = new haxe.ds.IntMap<String>();
		map.set(1, "one");
		map.set(2, "two");
		var iterable:KeyValueIterable<Int, String> = map;

		Assert.sameArray([1, 2], [for (entry in iterable.keyValueIterator()) entry.key],
			"KeyValueIterable<Int,String> should dispatch to IntMap.keyValueIterator");
		Assert.sameArray(["one", "two"], [for (entry in iterable.keyValueIterator()) entry.value],
			"KeyValueIterable<Int,String> should return IntMap entry values");
	}
}
