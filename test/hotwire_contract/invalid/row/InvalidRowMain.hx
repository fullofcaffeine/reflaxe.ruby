class InvalidRowMain {
	static function main():Void {
		InvalidRowContract.rowTemplate();
	}
}

@:hotwireContract
class InvalidRowContract {
	static final stream = "rooms:updates";
	static final target = "room-rows";
	static final row = rails.action_view.Template.named("rooms/row");
}
