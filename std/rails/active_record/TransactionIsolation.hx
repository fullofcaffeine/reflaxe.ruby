package rails.active_record;

/**
	Typed transaction isolation token for Rails `transaction(isolation: ...)`.
**/
abstract TransactionIsolation(String) to String {
	public static inline function readUncommitted():TransactionIsolation {
		return cast "read_uncommitted";
	}

	public static inline function readCommitted():TransactionIsolation {
		return cast "read_committed";
	}

	public static inline function repeatableRead():TransactionIsolation {
		return cast "repeatable_read";
	}

	public static inline function serializable():TransactionIsolation {
		return cast "serializable";
	}
}
