package rails.active_record;

/**
	Typed reference to an ActiveRecord field whose Haxe value type is nullable.

	RailsHx uses this for APIs where nullability is part of the query contract,
	such as `whereNull` / `whereNotNull`. It still coerces to a normal `Field`
	for projections, ordering, and other field-ref APIs.
**/
// `to String` lets the Ruby compiler and Rails helper surfaces erase this
// lightweight Haxe-only type back to the Rails column name. There is
// intentionally no matching `from String`: nullable predicates must receive a
// generated model field ref, not an unchecked string literal such as "status".
abstract NullableField<TModel, TValue>(String) to String {
	public var name(get, never):String;

	public inline function new(name:String) {
		this = name;
	}

	inline function get_name():String {
		return this;
	}

	public static inline function named<TModel, TValue>(name:String):NullableField<TModel, TValue> {
		return new NullableField(name);
	}

	// `@:to` is a Haxe abstract conversion. It lets a nullable field be reused
	// anywhere a normal `Field<TModel, Null<TValue>>` is expected, such as
	// ordering, projection, or generic field-ref helpers. The stricter
	// `NullableField` type is still required at the `whereNull`/`whereNotNull`
	// boundary, so non-nullable fields fail before Ruby is emitted.
	@:to
	public inline function toField():Field<TModel, Null<TValue>> {
		return Field.named(this);
	}

	public function asc():Order<TModel> {
		return Order.named(this, "asc");
	}

	public function desc():Order<TModel> {
		return Order.named(this, "desc");
	}
}
