package models;

// User ActiveRecord model source of truth.
//
// Demonstrates: a typed Rails model with a `has_many` association and
// validation metadata.
// Type safety: `User.f.name` and `User.a.todos` are generated from this class;
// query helpers inherited from `Base<User>` preserve `User` relation types.
// IntelliSense: editors should complete model fields, field refs, association
// refs, and inherited ActiveRecord-style query methods.
// Ruby/Rails output: a normal `ApplicationRecord` model with Rails association
// and validation macros.
@:railsModel("users")
@:railsTimestamps
class User extends rails.active_record.Base<User> {
	@:railsColumn({primaryKey: true, dbType: "bigint"})
	public var id:Int;

	@:railsColumn({index: true})
	public var name:String;

	@:hasMany public var todos:rails.ActiveRecord.HasMany<Todo>;

	@:validates({presence: true})
	public var nameValidation:rails.ActiveRecord.Validation<String>;
}
