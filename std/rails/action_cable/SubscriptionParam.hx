package rails.action_cable;

/**
	Typed subscription parameter key.

	The value lowers to Rails' params string key, but no implicit `from String`
	conversion is provided. Use `SubscriptionParam.named(...)` in one shared
	place so param names stay discoverable and each key carries its value type.
**/
abstract SubscriptionParam<TValue>(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static function named<TValue>(name:String):SubscriptionParam<TValue> {
		return new SubscriptionParam<TValue>(name);
	}
}
