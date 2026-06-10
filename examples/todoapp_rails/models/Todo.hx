package models;

import models.User;

@:railsModel("todos")
class Todo extends rails.active_record.Base<Todo> {
	@:railsColumn public var title:String;
	@:railsColumn public var isCompleted:Bool;
	@:railsColumn public var userId:Int;
	@:belongsTo public var user:rails.ActiveRecord.BelongsTo<User>;

	@:validates({presence: true})
	public var titleValidation:rails.ActiveRecord.Validation<String>;

	public static function incomplete():Array<Todo> {
		return Todo.where({isCompleted: false});
	}
}
