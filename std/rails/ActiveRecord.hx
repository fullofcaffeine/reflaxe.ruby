package rails;

class ActiveRecord {}

typedef ColumnOptions<T> = {
	@:optional var nullable:Bool;
	@:optional var defaultValue:T;
	@:optional var primaryKey:Bool;
	@:optional var index:Bool;
	@:optional var unique:Bool;
	@:optional var dbType:String;
}

extern class BelongsTo<T> {}

extern class HasMany<T> {}

extern class HasOne<T> {}

extern class Validation<T> {}
