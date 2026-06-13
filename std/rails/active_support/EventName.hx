package rails.active_support;

abstract EventName<TPayload>(String) to String from String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline function named<TPayload>(name:String):EventName<TPayload> {
		return new EventName<TPayload>(name);
	}
}
