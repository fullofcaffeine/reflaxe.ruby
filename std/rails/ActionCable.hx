package rails;

import rails.action_cable.Stream;

class ActionCable {
	public static function broadcast<TPayload>(stream:Stream<TPayload>, payload:TPayload):Void {}
}
