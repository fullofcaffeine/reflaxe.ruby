package rails.action_mailer;

class MailFormat {
	@:rubyBlockArg
	public function html(block:Void->Void):Void {}

	@:rubyBlockArg
	public function text(block:Void->Void):Void {}
}
