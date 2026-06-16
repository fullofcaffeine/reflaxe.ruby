package rails.action_mailer;

/*
	Typed ActionMailer layout option.

	`layout: "mailer"` and `layout: false` are common Rails shapes. The abstract
	lets those stay Rails-shaped without exposing `Dynamic` as the ordinary field
	type. Use `unchecked(...)` only for legacy/custom Rails layout values.
 */
abstract MailLayout(Dynamic) to Dynamic {
	inline function new(value:Dynamic) {
		this = value;
	}

	@:from
	public static inline function named(value:String):MailLayout {
		return new MailLayout(value);
	}

	public static inline function none():MailLayout {
		return new MailLayout(false);
	}

	public static inline function unchecked(value:Dynamic):MailLayout {
		return new MailLayout(value);
	}
}
