package rails.active_record;

/**
	Typed reference to an ActiveRecord-backed model field.

	RailsHx emits these as Rails-native field names/symbols, while Haxe keeps the
	model and value type available at authoring time.
**/
abstract Field<TModel, TValue>(String) from String to String {
	public var name(get, never):String;

	public inline function new(name:String) {
		this = name;
	}

	inline function get_name():String {
		return this;
	}

	public static inline function named<TModel, TValue>(name:String):Field<TModel, TValue> {
		return new Field(name);
	}

	public function asc():Order<TModel> {
		return Order.named(this, "asc");
	}

	public function desc():Order<TModel> {
		return Order.named(this, "desc");
	}
}
