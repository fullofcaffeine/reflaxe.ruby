class InvalidMissingMain {
	static function main():Void {
		InvalidMissingContract.streamName();
	}
}

@:hotwireContract
class InvalidMissingContract {
	static final stream = "rooms:updates";
	static final target = "room-rows";
}
