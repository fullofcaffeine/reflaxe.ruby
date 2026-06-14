package rails.active_record;

/**
	Typed token for Rails pessimistic lock clauses.

	Use `lock()` for Rails' default lock and `lock(Lock.forUpdate())`,
	`lock(Lock.noWait())`, or `lock(Lock.share())` when the lock clause should be
	explicit. `custom(...)` is the intentional escape hatch for database-specific
	lock strings.
**/
abstract Lock(String) to String {
	public static inline function forUpdate():Lock {
		return cast "FOR UPDATE";
	}

	public static inline function noWait():Lock {
		return cast "FOR UPDATE NOWAIT";
	}

	public static inline function share():Lock {
		return cast "FOR SHARE";
	}

	public static inline function custom(value:String):Lock {
		return cast value;
	}
}
