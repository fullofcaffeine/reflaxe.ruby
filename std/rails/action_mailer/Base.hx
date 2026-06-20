package rails.action_mailer;

@:autoBuild(rails.macros.MailerMacro.build())
class Base {
	public function new() {}

	/*
		Typed access to Rails parameterized mailer params.

		Haxe code passes a `MailParam<T>` token, so the compiler can type-check
		the returned value and lower the call to Rails' native `params[:key]`
		instead of pretending the params hash is a normal object.
	 */
	public function param<T>(key:MailParam<T>):T {
		return cast null;
	}

	@:rubyKwargs
	public function render(options:MailRenderOptions):Void {}

	@:rubyKwargs
	@:rubyBlockArg
	public function mail(options:MailOptions, ?block:MailFormat->Void):MessageDelivery {
		return cast null;
	}

	@:native("attachments")
	public function attachments():Attachments {
		return cast null;
	}
}
