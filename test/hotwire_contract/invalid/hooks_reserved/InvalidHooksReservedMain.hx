class InvalidHooksReservedMain {
	static function main():Void {
		InvalidReservedHooks.readySelector();
	}
}

@:hotwireHooks
class InvalidReservedHooks {
	static final stream:String = "rooms:updates";
	static final target:String = "room-rows";
	static final ready:String = "turbo-cable-stream-source[connected]";

	public static function readySelector():String {
		return "duplicate";
	}
}
