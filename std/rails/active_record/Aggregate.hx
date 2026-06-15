package rails.active_record;

/**
	Typed aggregate expression builders for RailsHx ActiveRecord queries.

	These functions intentionally return `Expr<TModel, TValue>` instead of an
	app-facing Arel node. Haxe keeps the model/value type available for
	predicates such as `Aggregate.count(Todo.f.id).gt(1)`, while the compiler
	lowers the token to Rails/Arel Ruby such as
	`Models::Todo.arel_table[:id].count`.
**/
class Aggregate {
	public static function count<TModel, TValue>(field:Field<TModel, TValue>):Expr<TModel, Int> {
		return new Expr("count:" + field.name);
	}

	public static function sum<TModel>(field:Field<TModel, Int>):Expr<TModel, Int> {
		return new Expr("sum:" + field.name);
	}

	public static function average<TModel>(field:Field<TModel, Int>):Expr<TModel, Float> {
		return new Expr("average:" + field.name);
	}

	public static function minimum<TModel, TValue>(field:Field<TModel, TValue>):Expr<TModel, TValue> {
		return new Expr("minimum:" + field.name);
	}

	public static function maximum<TModel, TValue>(field:Field<TModel, TValue>):Expr<TModel, TValue> {
		return new Expr("maximum:" + field.name);
	}
}
