package models;

// Typed ActiveStorage fixture.
//
// Demonstrates: ActiveRecord model metadata for both single and many
// attachments, generated model-owned attachment refs, and typed helper calls.
// Type safety: `@:hasOneAttached` fields must use `rails.ActiveStorage.One<T>`
// and `@:hasManyAttached` fields must use `rails.ActiveStorage.Many<T>`.
// `Profile.attachments.avatar` and `Profile.attachments.gallery` are generated
// from model metadata, so unknown attachment names fail in Haxe.
// IntelliSense: editors should complete `Profile.attachments.avatar` and
// `Profile.attachments.gallery`, with helper methods `attached`, `attach`, and
// `purge`.
// Ruby output: normal Rails `has_one_attached :avatar` and
// `has_many_attached :gallery`, plus direct receiver calls such as
// `profile.avatar.attach(...)`.
@:railsModel("profiles")
class Profile extends rails.active_record.Base<Profile> {
	@:railsColumn({primaryKey: true, dbType: "bigint"})
	public var id:Int;

	@:railsColumn
	public var name:String;

	@:hasOneAttached
	public var avatar:rails.ActiveStorage.One<Profile>;

	@:hasManyAttached
	public var gallery:rails.ActiveStorage.Many<Profile>;
}
