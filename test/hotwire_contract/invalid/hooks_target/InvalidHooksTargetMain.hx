class InvalidHooksTargetMain {
	static function main():Void {
		InvalidTargetHooks.targetSelector();
	}
}

@:hotwireHooks
class InvalidTargetHooks {
	static final stream:String = "rooms:updates";
	static final target:String = "room.rows";
	static final ready:String = "turbo-cable-stream-source[connected]";
}
