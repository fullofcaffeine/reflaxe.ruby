package rails.active_record;

/**
	Typed reference to an ActiveRecord association.

	RailsHx keeps the owner and target model types at authoring time and lowers
	association references to Rails-native symbols for `includes`/`joins`.
**/
abstract Association<TModel, TTarget>(String) from String to String {
	public var name(get, never):String;

	public inline function new(name:String) {
		this = name;
	}

	inline function get_name():String {
		return this;
	}

	public static inline function named<TModel, TTarget>(name:String):Association<TModel, TTarget> {
		return new Association(name);
	}

	public static function nested<TModel, TMiddle, TTarget>(parent:Association<TModel, TMiddle>,
			child:Association<TMiddle, TTarget>):Association<TModel, TTarget> {
		return cast "";
	}
}
