package rails.active_record;

/**
	Typed Rails params/form scope key for an ActiveRecord model.

	The value still lowers to Rails' normal param scope string/symbol, but macros
	can use the model type to validate related field refs.
**/
abstract ModelKey<TModel>(String) from String to String {
	public var name(get, never):String;

	public inline function new(name:String) {
		this = name;
	}

	inline function get_name():String {
		return this;
	}

	public static inline function named<TModel>(name:String):ModelKey<TModel> {
		return new ModelKey(name);
	}
}
