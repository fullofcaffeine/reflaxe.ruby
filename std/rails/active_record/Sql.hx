package rails.active_record;

/**
	Explicit SQL escape hatch for ActiveRecord query fragments.

	Prefer typed RailsHx builders first: criteria objects, field refs, `Expr`,
	`Projection`, `Group`, and typed aggregate helpers. Use `Sql.unsafe*` only
	when Rails needs SQL that RailsHx cannot model yet. The API name is
	intentionally loud so audits can find raw SQL quickly.
**/
// No `from String`: raw SQL must opt into a named unsafe constructor and a
// matching relation method such as `whereSql(...)` or `orderSql(...)`.
abstract Sql<TModel, TKind>(String) to String {
	public var fragment(get, never):String;

	public inline function new(fragment:String) {
		this = fragment;
	}

	inline function get_fragment():String {
		return this;
	}

	public static function unsafeWhere<TModel>(fragment:String):Sql<TModel, SqlWhere> {
		return new Sql(fragment);
	}

	public static function unsafeOrder<TModel>(fragment:String):Sql<TModel, SqlOrder> {
		return new Sql(fragment);
	}
}
