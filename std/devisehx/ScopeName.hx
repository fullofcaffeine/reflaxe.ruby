package devisehx;

/**
	Typed carrier for a Devise scope name such as `user` or `admin`.

	Generated app-local contracts should create these from deterministic Devise
	inventory rather than letting app code pass arbitrary strings everywhere.
**/
abstract ScopeName(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline function named(value:String):ScopeName {
		return new ScopeName(value);
	}

	public inline function toString():String {
		return this;
	}
}
