package models;

import models.User;

@:railsModel("todos")
@:railsTimestamps
class Todo extends rails.active_record.Base<Todo> {
	@:railsColumn({primaryKey: true, dbType: "bigint"})
	public var id:Int;

	@:railsColumn({index: true})
	public var title:String;

	@:railsColumn({dbType: "text", defaultValue: ""})
	public var notes:String;

	@:railsColumn({defaultValue: false})
	public var isCompleted:Bool;

	@:railsColumn({index: true})
	public var userId:Int;

	@:belongsTo public var user:rails.ActiveRecord.BelongsTo<User>;

	@:validates({presence: true})
	public var titleValidation:rails.ActiveRecord.Validation<String>;

	public static function incomplete() {
		return Todo.where({isCompleted: false});
	}
}
