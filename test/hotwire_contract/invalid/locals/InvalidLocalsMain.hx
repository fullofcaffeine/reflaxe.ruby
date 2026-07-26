class InvalidLocalsMain {
	static function main():Void {
		InvalidLocalsContract.rowTemplate();
	}
}

@:hotwireContract
class InvalidLocalsContract {
	static final stream = "rooms:updates";
	static final target = "room-rows";
	static final row:rails.action_view.Template<Dynamic> = rails.action_view.Template.named("rooms/row");
}
