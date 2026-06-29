package models;

import models.User;

// Todo ActiveRecord model source of truth.
//
// Demonstrates: typed Rails columns, belongs-to association metadata,
// validation metadata, timestamps, and a model-owned scope.
// Type safety: `@:railsColumn` drives generated field refs (`Todo.f.title`,
// `Todo.f.userId`), `@:belongsTo` drives association refs (`Todo.a.user`), and
// `Base<Todo>` makes query chains return typed `Relation<Todo>`.
// IntelliSense: editors should complete fields, `Todo.f.*`, `Todo.a.user`,
// `Todo.where`, `Todo.incomplete`, and relation methods.
// Ruby/Rails output: a normal `ApplicationRecord` model with Rails macros and
// compiler-emitted schema metadata.
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

	@:belongsTo({optional: false, foreignKey: "userId", inverseOf: "todos"})
	public var user:rails.ActiveRecord.BelongsTo<User>;

	@:validates({presence: true})
	public var titleValidation:rails.ActiveRecord.Validation<String>;

	@:validates({length: {maximum: 500}, allowBlank: true})
	public var notesValidation:rails.ActiveRecord.Validation<String>;

	@:validates({numericality: {onlyInteger: true, greaterThan: 0}})
	public var userIdValidation:rails.ActiveRecord.Validation<Int>;

	@:beforeValidation
	public function normalizeTitle():Void {
		if (title != null) {
			title = StringTools.trim(title);
		}
		if (notes != null) {
			notes = StringTools.trim(notes);
		}
	}

	public static function incomplete() {
		return Todo.where({isCompleted: false});
	}
}
