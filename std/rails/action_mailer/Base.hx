package rails.action_mailer;

class Base {
	public function new() {}

	@:rubyKwargs
	public function render(options:MailRenderOptions):Void {}

	@:rubyKwargs
	@:rubyBlockArg
	public function mail(options:MailOptions, ?block:MailFormat->Void):Void {}

	@:native("attachments")
	public function attachments():Attachments {
		return cast null;
	}
}
