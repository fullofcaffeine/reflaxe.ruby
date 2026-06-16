package rails.action_mailer;

/*
	Typed ActionMailer address value.

	Rails accepts both a single address and an array for kwargs such as `to`,
	`from`, `cc`, `bcc`, and `reply_to`. The abstract keeps that Rails-native
	shape while preventing arbitrary object-shaped Dynamic values from becoming
	the default mail boundary.
 */
abstract MailAddress(Dynamic) to Dynamic {
	inline function new(value:Dynamic) {
		this = value;
	}

	@:from
	public static inline function one(value:String):MailAddress {
		return new MailAddress(value);
	}

	@:from
	public static inline function many(values:Array<String>):MailAddress {
		return new MailAddress(values);
	}

	public static inline function unchecked(value:Dynamic):MailAddress {
		return new MailAddress(value);
	}
}
