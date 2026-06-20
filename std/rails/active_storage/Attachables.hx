package rails.active_storage;

/*
	Typed collection of ActiveStorage attachables for `has_many_attached`.

	The `Array<String>` conversion preserves the common signed-id array path,
	while `of(...)` lets callers mix richer typed `Attachable` builders without
	falling back to raw `Dynamic`.
 */
abstract Attachables(Dynamic) to Dynamic {
	inline function new(value:Dynamic) {
		this = value;
	}

	@:from
	public static function signedIds(values:Array<String>):Attachables {
		return new Attachables(values);
	}

	@:from
	public static function typedSignedIds(values:Array<SignedId>):Attachables {
		return new Attachables(values);
	}

	public static function of(values:Array<Attachable>):Attachables {
		return new Attachables(values);
	}

	public static function unchecked(value:Dynamic):Attachables {
		return new Attachables(value);
	}
}
