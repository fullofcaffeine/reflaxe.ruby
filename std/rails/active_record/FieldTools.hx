package rails.active_record;

/**
	Fluent typed helpers for generated ActiveRecord field refs.

	These methods are exposed through `@:using` on `Field`, so app code can write
	`Todo.f.title.lower().eq("ship")` instead of spelling the lower-level
	`Expr.lower(Todo.f.title).eq("ship")` form. The helpers intentionally return
	compiler-recognized `Expr`/`Predicate` tokens rather than SQL strings:
	Haxe checks the model owner and value type, then RailsHx lowers the token to
	normal Rails/Arel Ruby.
**/
class FieldTools {
	public static function expr<TModel, TValue>(field:Field<TModel, TValue>):Expr<TModel, TValue> {
		return Expr.field(field);
	}

	public static function lower<TModel>(field:Field<TModel, String>):Expr<TModel, String> {
		return Expr.lower(field);
	}

	public static function eq<TModel, TValue>(field:Field<TModel, TValue>, value:TValue):Predicate<TModel> {
		return Expr.field(field).eq(value);
	}

	public static function gt<TModel, TValue>(field:Field<TModel, TValue>, value:TValue):Predicate<TModel> {
		return Expr.field(field).gt(value);
	}

	public static function gte<TModel, TValue>(field:Field<TModel, TValue>, value:TValue):Predicate<TModel> {
		return Expr.field(field).gte(value);
	}

	public static function lt<TModel, TValue>(field:Field<TModel, TValue>, value:TValue):Predicate<TModel> {
		return Expr.field(field).lt(value);
	}

	public static function lte<TModel, TValue>(field:Field<TModel, TValue>, value:TValue):Predicate<TModel> {
		return Expr.field(field).lte(value);
	}

	public static function count<TModel, TValue>(field:Field<TModel, TValue>):Expr<TModel, Int> {
		return Aggregate.count(field);
	}

	public static function sum<TModel>(field:Field<TModel, Int>):Expr<TModel, Int> {
		return Aggregate.sum(field);
	}

	public static function average<TModel>(field:Field<TModel, Int>):Expr<TModel, Float> {
		return Aggregate.average(field);
	}

	public static function minimum<TModel, TValue>(field:Field<TModel, TValue>):Expr<TModel, TValue> {
		return Aggregate.minimum(field);
	}

	public static function maximum<TModel, TValue>(field:Field<TModel, TValue>):Expr<TModel, TValue> {
		return Aggregate.maximum(field);
	}
}
