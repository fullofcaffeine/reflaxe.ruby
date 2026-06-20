package devisehx.hhx;

/**
	Compiler-erased Devise form field refs for Rails HHX templates.

	Each static field carries `@:railsField`, the same metadata RailsHx model
	field refs use. That lets HHX authoring avoid repeated strings such as
	"passwordConfirmation" while the compiler still emits ordinary Rails form
	keys like `:password_confirmation`. These refs are intentionally tiny marker
	values, not a Devise runtime abstraction.
**/
extern class DeviseFormFields {
	@:railsField("email")
	public static final email:String;

	@:railsField("password")
	public static final password:String;

	@:railsField("password_confirmation")
	public static final passwordConfirmation:String;

	@:railsField("reset_password_token")
	public static final resetPasswordToken:String;
}
