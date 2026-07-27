class InvalidHooksMissingMain {
	static function main():Void {
		InvalidMissingHooks.targetSelector();
	}
}

@:hotwireHooks
class InvalidMissingHooks {
	static final stream:String = "rooms:updates";
	static final target:String = "room-rows";
}
