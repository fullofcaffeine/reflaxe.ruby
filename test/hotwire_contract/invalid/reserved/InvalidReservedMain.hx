class InvalidReservedMain {
	static function main():Void {
		InvalidReservedContract.streamName();
	}
}

@:hotwireContract
class InvalidReservedContract {
	static final stream = "rooms:updates";
	static final target = "room-rows";
	static final row:rails.action_view.Template<{title:String}> = rails.action_view.Template.named("rooms/row");

	public static function streamName():String {
		return "duplicate";
	}
}
