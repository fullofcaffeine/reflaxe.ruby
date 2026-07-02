package ruby;

/**
	Opaque typed handle for a Ruby `Hash` owned by `NativeHash`.

	The underlying value is deliberately hidden because only the raw Ruby helper
	methods may operate on it. Type parameters keep map keys and values precise at
	Haxe call sites while the compiler still emits a native Ruby hash.
**/
abstract NativeHashData<K, V>({}) {}
