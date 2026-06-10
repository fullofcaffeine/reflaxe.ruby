package ruby;

@:rubyAllowRaw
class NativeHash {
	public static function create():Dynamic {
		return untyped __ruby__("{}");
	}

	public static function set<K, V>(hash:Dynamic, key:K, value:V):Void {
		untyped __ruby__("{0}[{1}] = {2}", hash, key, value);
	}

	public static function get<K, V>(hash:Dynamic, key:K):Null<V> {
		return untyped __ruby__("{0}[{1}]", hash, key);
	}

	public static function exists<K>(hash:Dynamic, key:K):Bool {
		return untyped __ruby__("{0}.key?({1})", hash, key);
	}

	public static function remove<K>(hash:Dynamic, key:K):Bool {
		return untyped __ruby__("(if {0}.key?({1}) then {0}.delete({1}); true else false end)", hash, key);
	}

	public static function keys<K>(hash:Dynamic):Dynamic {
		return untyped __ruby__("{0}.keys", hash);
	}

	public static function values<V>(hash:Dynamic):Dynamic {
		return untyped __ruby__("{0}.values", hash);
	}

	public static function entries(hash:Dynamic):Dynamic {
		return untyped __ruby__("{0}.map { |key, value| Struct.new(:key, :value).new(key, value) }", hash);
	}

	public static function copyInto(target:Dynamic, source:Dynamic):Void {
		untyped __ruby__("{0}.replace({1})", target, source);
	}

	public static function clear(hash:Dynamic):Void {
		untyped __ruby__("{0}.clear", hash);
	}

	public static function toString(hash:Dynamic):String {
		return untyped __ruby__("{0}.to_s", hash);
	}
}
