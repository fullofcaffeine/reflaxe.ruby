class InvalidHooksDynamicMain {
	public static function unchecked():Dynamic {
		return "turbo-cable-stream-source[connected]";
	}

	static function main():Void {
		InvalidDynamicHooks.readySelector();
	}
}

@:hotwireHooks
class InvalidDynamicHooks {
	static final stream:String = "rooms:updates";
	static final target:String = "room-rows";
	static final ready:Dynamic = InvalidHooksDynamicMain.unchecked();
}
