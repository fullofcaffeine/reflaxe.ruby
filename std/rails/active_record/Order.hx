package rails.active_record;

/**
	Typed ActiveRecord order expression.

	RailsHx keeps the model type at authoring time and lowers order expressions to
	Rails-native `order(column: :direction)` arguments.
**/
abstract Order<TModel>(String) from String to String {
	public var expression(get, never):String;

	public inline function new(expression:String) {
		this = expression;
	}

	inline function get_expression():String {
		return this;
	}

	public static inline function named<TModel>(field:String, direction:String):Order<TModel> {
		return new Order(field + ":" + direction);
	}

	public static function many<TModel>(orders:Array<Order<TModel>>):Order<TModel> {
		return new Order(orders.join(","));
	}
}
