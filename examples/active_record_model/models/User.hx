package models;

// Associated Rails model fixture.
//
// Demonstrates: a RailsHx model with `has_many` associations, including a
// through/source association.
// Type safety: `User.a.todos` and `User.associations.todos` are typed
// association refs; using them with the wrong model owner should fail in Haxe.
// IntelliSense: editors should complete `User.a.todos`, `User.f.name`, and
// relation helpers inherited from `Base<User>`.
// Ruby output: a normal `ApplicationRecord` subclass with `has_many` macros.
@:railsModel("users")
@:railsTimestamps
class User extends rails.active_record.Base<User> {
	@:railsColumn({primaryKey: true, dbType: "bigint"})
	public var id:Int;

	@:railsColumn({index: true})
	public var name:String;

	@:hasMany({dependent: "destroy", inverseOf: "user"})
	public var todos:rails.ActiveRecord.HasMany<Todo>;

	@:hasMany({through: "todos", source: "user"})
	public var todoOwners:rails.ActiveRecord.HasMany<User>;
}
