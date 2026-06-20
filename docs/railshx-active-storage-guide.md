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
Profile.attachments.avatar.attach(profile,
	Attachable.io(File.open("avatar.png"), "avatar.png", {contentType: "image/png"}));
var hasAvatar = Profile.attachments.avatar.attached(profile);
Profile.attachments.avatar.purge(profile);
```

Those calls lower to the Rails receiver API:

```ruby
profile.avatar.attach("avatar.png")
profile.gallery.attach(["one.png", "two.png"])
profile.avatar.attach({"io" => File.open("avatar.png"),
  "filename" => "avatar.png", "content_type" => "image/png"})
profile.avatar.attached?
profile.avatar.purge
```

Unknown refs such as `Profile.attachments.missing` fail in Haxe before Rails
runs.

The default `attach(...)` path is intentionally typed: single attachments accept
a `String`, and many attachments accept `Array<String>`. In Rails runtime use,
that string path is primarily for signed blob IDs such as `blob.signed_id`; it
is not a promise that arbitrary filenames are valid attachables. Keeping this
path typed prevents accidental object-shaped `Dynamic` values from flowing into
Rails while preserving the common direct-upload/signed-id handoff.

For `has_many_attached`, use `Attachables.of(...)` when the array contains typed
hash attachables instead of only signed IDs:

```haxe
Profile.attachments.gallery.attach(profile, Attachables.of([
	Attachable.io(File.open("one.png"), "one.png", {contentType: "image/png"}),
	Attachable.io(File.open("two.png"), "two.png", {contentType: "image/png"})
]));
```

For Rails attachable shapes RailsHx has not modeled yet, use the explicit escape
hatch:

```haxe
Profile.attachments.avatar.attachUnchecked(profile, {io: "raw", filename: "avatar.png"});
```

That still lowers to normal Rails:

```ruby
profile.avatar.attach({"io" => "raw", "filename" => "avatar.png"})
```

Use `attachUnchecked(...)` only at reviewed interop boundaries. Common
`io`/`filename`/`content_type` hashes should use `Attachable.io(...)` instead.

## Runtime Strategy

`npm run test:active-storage` is both the fast compiler/static lane and, when a
Rails bundle is available, a generated Rails runtime lane. The static pass
checks:

- `has_one_attached` and `has_many_attached` generation.
- generated model-owned attachment refs.
- single vs many metadata type validation.
- helper lowering for `attached`, `attach`, and `purge`.
- typed `Attachable.io(...)` and `Attachables.of(...)` hash attachable lowering.
- unknown attachment refs failing during Haxe compilation.
- object-shaped values failing on typed `attach(...)`, with
  `attachUnchecked(...)` reserved as the explicit raw Rails attachable escape.

The runtime pass materializes a tiny Rails app with ActiveRecord, ActiveStorage,
SQLite, and the Rails test disk service. It installs the ActiveStorage tables,
migrates the generated `Profile` model, and asserts:

- `has_one_attached :avatar` can attach a real blob by `signed_id`.
- `avatar.download` reads the stored body.
- `avatar.purge` removes the single attachment.
- `has_many_attached :gallery` can attach an array of real blob signed IDs.
- each gallery attachment can be read back and the collection can be purged.
- a normal Rails hash attachable with `io`, `filename`, and `content_type` can
  attach a file through the same Rails receiver API.

If the generated app bundle is unavailable, the local fast lane prints a staged
skip so compiler work stays lightweight. `REQUIRE_RAILS=1 npm run
test:rails-runtime` includes `test:active-storage` and makes missing Rails
runtime dependencies fail instead of silently skipping.

## Current Production Boundary

The supported production path today is model metadata for one/many attachments,
typed attachment refs, `attached`, signed-ID `attach`, and `purge` over the
normal Rails ActiveStorage receiver API. `Attachable.io(...)` and
`Attachables.of(...)` cover the common Rails hash attachable path without raw
object literals.

Direct-upload helper generation, variants/previews, blob metadata facades,
attachment validations, analyzer hooks, and richer attachable builders remain
production follow-up work. Use `attachUnchecked(...)` only at reviewed Rails
interop boundaries.
