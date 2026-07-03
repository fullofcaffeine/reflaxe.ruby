package ruby;

/**
	Typed RubyHx key/value record used by `NativeHash.entries`.

	This keeps map iteration on a small generated Ruby class with `key` and
	`value` readers instead of depending on the broader `HXRuby` runtime.
**/
class NativeHashEntry<K, V> {
	public var key:K;
	public var value:V;

	public function new(key:K, value:V) {
		this.key = key;
		this.value = value;
	}
}
