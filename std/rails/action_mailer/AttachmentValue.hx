package rails.action_mailer;

typedef AttachmentOptions = {
	/*
		Haxe-facing camelCase option lowered by the compiler to Rails'
		attachment-hash key `mime_type`.
	 */
	@:optional var mimeType:String;
	@:optional var encoding:String;
}

/*
	Typed value for Rails ActionMailer attachments.

	`@:from String` keeps the common Rails case terse:
	`attachments().add("readme.txt", body)`.

	`content(...)` is a compiler-recognized marker for Rails' hash form:
	`attachments["readme.txt"] = { content: body, mime_type: "text/plain" }`.
	The marker exists so Haxe can type-check the authoring API while the Ruby
	output stays ordinary ActionMailer code with no RailsHx runtime wrapper.
 */
abstract AttachmentValue(Dynamic) to Dynamic {
	inline function new(value:Dynamic) {
		this = value;
	}

	@:from
	public static function ofString(content:String):AttachmentValue {
		return new AttachmentValue(content);
	}

	public static function content(content:String, ?options:AttachmentOptions):AttachmentValue {
		return new AttachmentValue(untyped null);
	}

	public static function unchecked(value:Dynamic):AttachmentValue {
		return new AttachmentValue(value);
	}
}
