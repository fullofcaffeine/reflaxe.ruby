package models;

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
