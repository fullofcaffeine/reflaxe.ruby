package models;

import models.User;

// Full typed ActiveRecord model fixture.
//
// Demonstrates: table naming, timestamps, typed columns, defaults, enum
// metadata, nullable fields, indexes, uniqueness, associations, scopes, and
// lifecycle callbacks.
// Type safety: `Base<Todo>` makes static query APIs return `Relation<Todo>`;
// `@:railsColumn` generates field refs such as `Todo.f.title`; `@:belongsTo`
// generates association refs such as `Todo.a.user`; callbacks reference typed
// instance methods.
// IntelliSense: editors should complete model fields, generated refs/scopes,
// relation methods, and association helpers directly from this class.
// Ruby output: a normal Rails model with `self.table_name`, association macros,
// validation/schema metadata, enum declarations, and callbacks.
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
