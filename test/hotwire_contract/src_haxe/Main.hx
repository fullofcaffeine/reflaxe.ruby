package;

class Main {
	static function main():Void {
		Sys.println(RoomContract.streamName());
		Sys.println(RoomContract.streamTarget());
		var legacyTarget = rails.turbo.StreamTarget.existing("rooms/legacy", "legacy-room-rows");
		// Keep the typed template accessor in generated Ruby while the no-Rails
		// runtime branch stays inactive in this compiler-level fixture.
		if (Sys.args().length > 0) {
			Sys.println(RoomContract.rowTemplate().templatePath);
			Sys.println(RoomView.render());
			Sys.println(legacyTarget);
		}
		Sys.println(RoomContract.locals("typed").title);
	}
}
