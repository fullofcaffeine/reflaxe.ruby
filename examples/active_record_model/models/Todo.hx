package models;

import models.User;

@:railsModel("todos")
@:railsTimestamps
class Todo extends rails.active_record.Base<Todo> {
	@:railsColumn({primaryKey: true, dbType: "bigint"})
	public var id:Int;

	@:railsColumn({index: true})
	public var title:String;

	@:railsColumn({defaultValue: false})
	public var completed:Bool;

	@:railsColumn({defaultValue: "open"})
	@:railsEnum({open: "open", done: "done"})
	public var status:String;

	@:railsColumn({nullable: true, dbType: "text"})
	public var notes:Null<String>;

	@:railsColumn({unique: true})
	public var externalId:String;

	@:railsColumn({index: true})
	public var userId:Int;

	@:belongsTo({optional: false, foreignKey: "userId", inverseOf: "todos"})
	public var user:rails.ActiveRecord.BelongsTo<User>;

	public static function incomplete() {
		return Todo.where({completed: false});
	}

	@:beforeValidation
	public function normalizeTitle():Void {}

	@:railsCallback("after_commit")
	public function publishLifecycleEvent():Void {}
}
