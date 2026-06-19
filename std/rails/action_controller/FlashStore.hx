package rails.action_controller;

/**
	Typed facade for Rails `flash`.

	Rails exposes `flash` as a controller helper and stores messages with
	`flash[:notice] = ...` / `flash[:alert] = ...`. RailsHx keeps the generic
	`KeyValueStore.set(...)` API for uncommon keys, but these intent-named
	methods make application controllers read like the Rails concept they use
	while the compiler still emits the normal flash hash assignment.
**/
extern class FlashStore extends KeyValueStore<String> {
	public function notice(value:String):String;
	public function alert(value:String):String;
}
