class InvalidDynamicMain {
	public static function unchecked():Dynamic {
		return "rooms:updates";
	}

	static function main():Void {
		InvalidDynamicContract.streamName();
	}
}

@:hotwireContract
class InvalidDynamicContract {
	static final stream = InvalidDynamicMain.unchecked();
	static final target = "room-rows";
	static final row:rails.action_view.Template<{title:String}> = rails.action_view.Template.named("rooms/row");
}
