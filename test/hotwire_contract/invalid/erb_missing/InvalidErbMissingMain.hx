class InvalidErbMissingMain {
	static function main():Void {
		rails.turbo.StreamTarget.existing("rooms/missing", "room-rows");
	}
}
