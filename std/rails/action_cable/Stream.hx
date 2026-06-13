package rails.action_cable;

abstract Stream<TPayload>(String) to String from String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline function named<TPayload>(name:String):Stream<TPayload> {
		return new Stream<TPayload>(name);
	}
}
