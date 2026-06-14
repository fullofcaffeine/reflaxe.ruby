package rails.action_mailer;

/*
	Typed facade over Rails' ActionMailer `attachments` proxy.

	`add(...)` covers the common string body case and emits normal Rails Ruby:
	`attachments["name"] = content`. More complex Rails attachment hashes remain
	available through the explicit `addUnchecked(...)` escape until RailsHx grows
	typed builders for those shapes.
*/
abstract Attachments(Dynamic) from Dynamic to Dynamic {
	public function add(name:String, content:String):Void {}

	public function addUnchecked(name:String, value:Dynamic):Void {}
}
