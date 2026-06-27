package models;

import app.auth.UserAuth;
import devisehx.model.DeviseModule.*;
import devisehx.model.DeviseResource;
import models.ChatMessage;

// User ActiveRecord model source of truth.
//
// Demonstrates: a typed Rails model with user-facing profile fields, a role
// column, `has_many` associations, validation metadata, and small app-owned
// helpers that still emit plain Ruby methods.
// Type safety: `User.f.name`, `User.f.email`, `User.f.role`, and `User.a.todos`
// are generated from this class; query helpers inherited from `Base<User>`
// preserve `User` relation types.
// IntelliSense: editors should complete model fields, field refs, association
// refs, and inherited ActiveRecord-style query methods.
// Ruby/Rails output: a normal `ApplicationRecord` model with Rails association
// and validation macros, plus Devise's ordinary `devise :...` class macro.
@:railsModel("users")
@:railsTimestamps
@:devise(UserAuth.scope, [databaseAuthenticatable, validatable])
class User extends rails.active_record.Base<User> implements DeviseResource<User> {
	@:railsColumn({primaryKey: true, dbType: "bigint"})
	public var id:Int;

	@:railsColumn({index: true})
	public var name:String;

	@:railsColumn({index: true})
	public var email:String;

	@:railsColumn({dbType: "string", nullable: false, defaultValue: ""})
	public var encryptedPassword:String;

	@:railsColumn({index: true, defaultValue: "member"})
	public var role:String;

	@:hasMany public var todos:rails.ActiveRecord.HasMany<Todo>;

	@:hasMany public var chatMessages:rails.ActiveRecord.HasMany<ChatMessage>;

	@:validates({presence: true, length: {minimum: 2}})
	public var nameValidation:rails.ActiveRecord.Validation<String>;

	@:validates("name", {exclusion: {within: ["admin", "root", "system"]}})
	public var reservedNameValidation:rails.ActiveRecord.Validation<String>;

	@:validates({presence: true, uniqueness: true})
	public var emailValidation:rails.ActiveRecord.Validation<String>;

	@:validates({inclusion: {within: ["member", "admin", "maintainer", "guest"]}})
	public var roleValidation:rails.ActiveRecord.Validation<String>;

	public function roleLabel():String {
		return role == "admin" ? "Admin" : role == "maintainer" ? "Maintainer" : role == "guest" ? "Guest" : "Member";
	}

	public function canManageUsers():Bool {
		return role == "admin";
	}

	public function initials():String {
		var trimmed = StringTools.trim(name);
		return trimmed == "" ? "?" : trimmed.substr(0, 1).toUpperCase();
	}
}
