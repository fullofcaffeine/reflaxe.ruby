package rails.action_mailer;

typedef MailOptions = {
	@:optional var to:Dynamic;
	@:optional var from:Dynamic;
	@:optional var subject:String;
	@:optional var cc:Dynamic;
	@:optional var bcc:Dynamic;
	@:optional var replyTo:Dynamic;
	@:optional var templateName:String;
	@:optional var templatePath:String;
	@:optional var layout:Dynamic;
}
