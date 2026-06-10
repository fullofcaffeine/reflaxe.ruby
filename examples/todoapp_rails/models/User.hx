package models;

@:railsModel("users")
class User extends rails.active_record.Base<User> {
	@:railsColumn public var name:String;
	@:hasMany public var todos:rails.ActiveRecord.HasMany<Todo>;

	@:validates({presence: true})
	public var nameValidation:rails.ActiveRecord.Validation<String>;
}
