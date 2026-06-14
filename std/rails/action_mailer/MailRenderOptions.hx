package rails.action_mailer;

typedef MailRenderOptions = {
	var template:String;
	@:optional var locals:Dynamic;
	@:optional var layout:MailLayout;
}
