package rails.active_storage;

typedef AttachableOptions = {
	/*
		Haxe-facing camelCase lowered by the compiler to Rails' `content_type`
		attachable hash key.
	 */
	@:optional var contentType:String;
}

/*
	Typed ActiveStorage attachable value.

	String conversion keeps the direct-upload/signed-id handoff terse:
	`Profile.attachments.avatar.attach(profile, blob.signedId())`.

	`io(...)` models Rails' common hash attachable shape without letting app code
	pass arbitrary object literals to `attach(...)`. The IO value is supplied by
	the app because Rails accepts several IO-like Ruby objects; RailsHx types the
	filename/content type and lowers the marker to a normal Rails hash.
 */
abstract Attachable(Dynamic) to Dynamic {
	inline function new(value:Dynamic) {
		this = value;
	}

	@:from
	public static function signedId(value:String):Attachable {
		return new Attachable(value);
	}

	@:from
	public static function typedSignedId(value:SignedId):Attachable {
		return new Attachable(value);
	}

	@:from
	public static function blob(value:Blob):Attachable {
		return new Attachable(value);
	}

	public static function io(io:Dynamic, filename:String, ?options:AttachableOptions):Attachable {
		return new Attachable(untyped null);
	}

	public static function unchecked(value:Dynamic):Attachable {
		return new Attachable(value);
	}
}
