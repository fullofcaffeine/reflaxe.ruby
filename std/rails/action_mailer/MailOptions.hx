package rails.action_mailer;

typedef MailOptions = {
	@:optional var to:MailAddress;
	@:optional var from:MailAddress;
	@:optional var subject:String;
	@:optional var cc:MailAddress;
	@:optional var bcc:MailAddress;
	@:optional var replyTo:MailAddress;
	@:optional var templateName:String;
	@:optional var templatePath:String;
	@:optional var layout:MailLayout;
}
