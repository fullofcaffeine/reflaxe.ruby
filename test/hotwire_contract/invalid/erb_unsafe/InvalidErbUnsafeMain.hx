class InvalidErbUnsafeMain {
	static function main():Void {
		rails.turbo.StreamTarget.existing("../rooms/legacy", "legacy-room-rows");
	}
}
