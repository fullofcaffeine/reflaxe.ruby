package devisehx;

/**
	Typed carrier for Devise's route resource, usually the plural form used by
	`devise_for`, such as `users` for the `user` scope.
**/
abstract RouteResource(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline function named(value:String):RouteResource {
		return new RouteResource(value);
	}

	public inline function toString():String {
		return this;
	}
}
