package models;

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
