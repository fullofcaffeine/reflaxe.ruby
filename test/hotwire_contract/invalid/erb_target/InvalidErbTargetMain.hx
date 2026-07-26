class InvalidErbTargetMain {
	static function main():Void {
		rails.turbo.StreamTarget.existing("rooms/legacy", "comment-only-room-rows");
	}
}
