package rails.active_record;

/**
	Typed ActiveRecord expression.

	RailsHx exposes `Expr<TModel, TValue>` as the stable Haxe API for expression
	building and keeps Arel as a generated Ruby backend detail. The model type
	keeps expressions attached to the relation owner; the value type keeps
	predicate values and function builders checked by Haxe.
**/
// The underlying string is only a lightweight compiler token. Avoid `from
// String`: app-facing SQL fragments should be named, explicit escape hatches,
// not accidental conversions into a typed query expression.
abstract Expr<TModel, TValue>(String) to String {
	public var expression(get, never):String;

	public inline function new(expression:String) {
		this = expression;
	}

	inline function get_expression():String {
		return this;
	}

	public static function field<TModel, TValue>(field:Field<TModel, TValue>):Expr<TModel, TValue> {
		return new Expr(field.name);
	}

	public static function lower<TModel>(field:Field<TModel, String>):Expr<TModel, String> {
		return new Expr("lower:" + field.name);
	}

	public function eq(value:TValue):Predicate<TModel> {
		return new Predicate(this + ":eq");
	}

	public function gt(value:TValue):Predicate<TModel> {
		return new Predicate(this + ":gt");
	}

	public function gte(value:TValue):Predicate<TModel> {
		return new Predicate(this + ":gteq");
	}

	public function lt(value:TValue):Predicate<TModel> {
		return new Predicate(this + ":lt");
	}

	public function lte(value:TValue):Predicate<TModel> {
		return new Predicate(this + ":lteq");
	}

	public function asc():Order<TModel> {
		return Order.fromExpr(cast this, "asc");
	}

	public function desc():Order<TModel> {
		return Order.fromExpr(cast this, "desc");
	}
}
