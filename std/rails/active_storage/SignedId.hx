package rails.active_storage;

/*
	Opaque ActiveStorage signed blob id.

	Rails direct uploads submit signed ids as strings, but Haxe code should keep
	that boundary explicit so arbitrary filenames/ids do not accidentally look
	like verified ActiveStorage blob references.
 */
abstract SignedId(String) from String to String {
	inline function new(value:String) {
		this = value;
	}

	public static function unchecked(value:String):SignedId {
		return new SignedId(value);
	}
}
