package rails.active_record;

/**
	Typed ActiveRecord order expression.

	RailsHx keeps the model type at authoring time and lowers order expressions to
	Rails-native `order(column: :direction)` arguments.
**/
// `Order<TModel>` deliberately does not accept `from String`. Plain SQL/order
// strings such as "LOWER(title) ASC" should not bypass model ownership checks;
// typed builders like `Todo.f.title.asc()` or `Expr.lower(Todo.f.title).asc()`
// should cover normal app code, with future raw SQL routed through `Sql.*`.
abstract Order<TModel>(String) to String {
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

	public static function fromExpr<TModel, TValue>(expr:Expr<TModel, TValue>, direction:String):Order<TModel> {
		return new Order(expr.expression + ":" + direction);
	}

	public static function lower<TModel>(field:Field<TModel, String>):Expr<TModel, String> {
		return Expr.lower(field);
	}

	public static function many<TModel>(orders:Array<Order<TModel>>):Order<TModel> {
		return new Order(orders.join(","));
	}
}
