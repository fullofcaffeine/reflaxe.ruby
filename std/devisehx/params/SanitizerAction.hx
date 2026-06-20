package devisehx.params;

/**
	Typed Devise parameter sanitizer action.

	Devise's Ruby API uses symbols such as `:sign_up`. RailsHx keeps those as
	typed Haxe values so app code gets completion and avoids repeated strings,
	then the compiler lowers them back to Ruby symbols.
**/
abstract SanitizerAction(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	@:deviseHxSanitizerAction("sign_in")
	public static final signIn:SanitizerAction = new SanitizerAction("sign_in");

	@:deviseHxSanitizerAction("sign_up")
	public static final signUp:SanitizerAction = new SanitizerAction("sign_up");

	@:deviseHxSanitizerAction("account_update")
	public static final accountUpdate:SanitizerAction = new SanitizerAction("account_update");
}
