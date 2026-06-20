package rails.action_mailer;

/*
	Typed token for Rails parameterized mailer params.

	`MailParam.named("user")` is intentionally a checked token instead of a raw
	string at call sites. The Ruby compiler recognizes the token when passed to
	`Base.param(...)` and emits the Rails-native `params[:user]` hash access.
 */
abstract MailParam<T>(String) {
	inline function new(value:String) {
		this = value;
	}

	@:from
	public static inline function ofString<T>(name:String):MailParam<T> {
		return new MailParam<T>(name);
	}

	public static inline function named<T>(name:String):MailParam<T> {
		return new MailParam<T>(name);
	}
}
