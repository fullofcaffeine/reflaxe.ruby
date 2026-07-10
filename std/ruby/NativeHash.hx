package ruby;

@:rubyAllowRaw
class NativeHash {
	/** Inline map construction so static Haxe map literals need no load-order wrapper. */
	public static inline function create<K, V>():NativeHashData<K, V> {
		return untyped __ruby__("{}");
	}

	public static function createIdentity<K, V>():NativeHashData<K, V> {
		return untyped __ruby__("{}.compare_by_identity");
	}

	/** Inline the canonical write path to the ordinary Ruby `hash[key] = value`. */
	public static inline function set<K, V>(hash:NativeHashData<K, V>, key:K, value:V):Void {
		untyped __ruby__("{0}[{1}] = {2}", hash, key, value);
	}

	public static function get<K, V>(hash:NativeHashData<K, V>, key:K):Null<V> {
		return untyped __ruby__("{0}[{1}]", hash, key);
	}

	public static function exists<K, V>(hash:NativeHashData<K, V>, key:K):Bool {
		return untyped __ruby__("{0}.key?({1})", hash, key);
	}

	public static function remove<K, V>(hash:NativeHashData<K, V>, key:K):Bool {
		return untyped __ruby__("(if {0}.key?({1}) then {0}.delete({1}); true else false end)", hash, key);
	}

	public static function keys<K, V>(hash:NativeHashData<K, V>):Array<K> {
		return untyped __ruby__("{0}.keys", hash);
	}

	public static function values<K, V>(hash:NativeHashData<K, V>):Array<V> {
		return untyped __ruby__("{0}.values", hash);
	}

	public static function entries<K, V>(hash:NativeHashData<K, V>):Array<NativeHashEntry<K, V>> {
		return untyped __ruby__("{0}.map { |key, value| Ruby::NativeHashEntry.new(key, value) }", hash);
	}

	public static function copyInto<K, V>(target:NativeHashData<K, V>, source:NativeHashData<K, V>):Void {
		untyped __ruby__("{0}.replace({1})", target, source);
	}

	public static function clear<K, V>(hash:NativeHashData<K, V>):Void {
		untyped __ruby__("{0}.clear", hash);
	}

	public static function toString<K, V>(hash:NativeHashData<K, V>):String {
		return untyped __ruby__("{0}.to_s", hash);
	}
}
