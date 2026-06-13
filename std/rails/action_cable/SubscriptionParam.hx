package rails.action_cable;

abstract SubscriptionParam<TValue>(String) to String from String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline function named<TValue>(name:String):SubscriptionParam<TValue> {
		return new SubscriptionParam<TValue>(name);
	}
}
