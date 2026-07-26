class InvalidTargetMain {
	static function main():Void {
		InvalidTargetContract.streamTarget();
	}
}

@:hotwireContract
class InvalidTargetContract {
	static final stream = "rooms:updates";
	static final target = 42;
	static final row:rails.action_view.Template<{title:String}> = rails.action_view.Template.named("rooms/row");
}
