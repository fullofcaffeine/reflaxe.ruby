package rails.active_record;

/**
	Typed ActiveRecord boolean predicate.

	This is a Haxe authoring token, not a runtime abstraction over Rails. RailsHx
	keeps the owning model type in `Predicate<TModel>` so relation APIs can reject
	predicates from another model before Ruby is emitted, then the compiler lowers
	approved predicates to ordinary Rails/Arel calls.
**/
// There is intentionally no `from String`: raw SQL must use an explicit future
// `Sql.*` escape hatch instead of masquerading as a typed predicate.
abstract Predicate<TModel>(String) to String {
	public var expression(get, never):String;

	public inline function new(expression:String) {
		this = expression;
	}

	inline function get_expression():String {
		return this;
	}
}
