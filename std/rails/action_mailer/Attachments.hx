package rails.action_mailer;

/*
	Typed facade over Rails' ActionMailer `attachments` proxy.

	`add(...)` covers the common string body case and emits normal Rails Ruby:
	`attachments["name"] = content`. It also accepts `AttachmentValue` builders
	for Rails' normal attachment hash shapes while keeping arbitrary Dynamic
	values behind the explicit `addUnchecked(...)` escape.
 */
abstract Attachments(Dynamic) from Dynamic to Dynamic {
	public function add(name:String, content:AttachmentValue):Void {}

	@:native("inline")
	public function inlineAttachments():Attachments {
		return cast null;
	}

	public function addUnchecked(name:String, value:Dynamic):Void {}
}
