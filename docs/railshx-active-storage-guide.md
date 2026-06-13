# RailsHx ActiveStorage Guide

RailsHx ActiveStorage support starts at the model boundary: Haxe metadata emits
normal Rails attachment declarations, and generated typed refs make attachment
usage discoverable and checked.

## Model Metadata

Use `@:hasOneAttached` and `@:hasManyAttached` on `@:railsModel` fields:

```haxe
@:railsModel("profiles")
class Profile extends rails.active_record.Base<Profile> {
	@:railsColumn({primaryKey: true, dbType: "bigint"})
	public var id:Int;

	@:hasOneAttached
	public var avatar:rails.ActiveStorage.One<Profile>;

	@:hasManyAttached
	public var gallery:rails.ActiveStorage.Many<Profile>;
}
```

Generated Ruby stays Rails-shaped:

```ruby
class Profile < ::ApplicationRecord
  has_one_attached :avatar
  has_many_attached :gallery
end
```

The metadata validates one/many shape at compile time:
`@:hasOneAttached` requires `rails.ActiveStorage.One<TModel>`, and
`@:hasManyAttached` requires `rails.ActiveStorage.Many<TModel>`.

## Typed Attachment Refs

`ModelMacro` generates `Profile.attachments.*` refs:

```haxe
var profile = new Profile();
Profile.attachments.avatar.attach(profile, "avatar.png");
Profile.attachments.gallery.attach(profile, ["one.png", "two.png"]);
var hasAvatar = Profile.attachments.avatar.attached(profile);
Profile.attachments.avatar.purge(profile);
```

Those calls lower to the Rails receiver API:

```ruby
profile.avatar.attach("avatar.png")
profile.gallery.attach(["one.png", "two.png"])
profile.avatar.attached?
profile.avatar.purge
```

Unknown refs such as `Profile.attachments.missing` fail in Haxe before Rails
runs.

## Runtime Strategy

`npm run test:active-storage` is the fast compiler/static lane. It checks:

- `has_one_attached` and `has_many_attached` generation.
- generated model-owned attachment refs.
- single vs many metadata type validation.
- helper lowering for `attached`, `attach`, and `purge`.
- unknown attachment refs failing during Haxe compilation.

Rails runtime execution should use the Rails test storage service in the
generated app lane. When Rails gems are installed,
`REQUIRE_RAILS=1 npm run test:rails-runtime` must make missing Rails runtime
dependencies fail instead of silently skipping.
