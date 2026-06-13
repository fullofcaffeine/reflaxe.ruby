package rails.turbo;

abstract StreamName<TPayload>(String) to String from String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline function named<TPayload>(name:String):StreamName<TPayload> {
		return new StreamName<TPayload>(name);
	}
}
