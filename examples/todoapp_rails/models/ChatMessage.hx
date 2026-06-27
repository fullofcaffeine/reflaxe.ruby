package models;

import models.User;

// Chat message ActiveRecord model source of truth.
//
// Demonstrates: a second typed domain model with association-backed ownership
// and a model-owned scope for newest-first chat rendering.
// Type safety: `ChatMessage.f.body`, `ChatMessage.f.userId`, and
// `ChatMessage.a.user` are generated from this class and shared by controllers,
// params, HHX forms, and tests.
// IntelliSense: editors should complete chat fields, association refs, and the
// inherited ActiveRecord relation methods.
// Ruby/Rails output: a normal `ApplicationRecord` model with `belongs_to`,
// validation, and schema metadata.
@:railsModel("chat_messages")
@:railsTimestamps
class ChatMessage extends rails.active_record.Base<ChatMessage> {
	@:railsColumn({primaryKey: true, dbType: "bigint"})
	public var id:Int;

	@:railsColumn({dbType: "text"})
	public var body:String;

	@:railsColumn({index: true})
	public var userId:Int;

	@:belongsTo({optional: false, foreignKey: "userId", inverseOf: "chatMessages"})
	public var user:rails.ActiveRecord.BelongsTo<User>;

	@:validates({presence: true})
	public var bodyValidation:rails.ActiveRecord.Validation<String>;

	@:beforeValidation
	public function normalizeBody():Void {
		if (body != null) {
			body = StringTools.trim(body);
		}
	}

	public static function latest() {
		return ChatMessage.includes(ChatMessage.a.user).order(ChatMessage.f.id.desc()).limit(6);
	}
}
