package rails.turbo;

import rails.action_view.Template;

@:rubyRequire("turbo-rails")
class TurboStreams {
	public static function append<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function prepend<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function before<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function after<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function replace<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function update<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function remove(target:StreamTarget):Void {}

	public static function broadcastAppendTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastPrependTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastBeforeTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastAfterTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastReplaceTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastUpdateTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastRemoveTo<TPayload>(stream:StreamName<TPayload>, target:StreamTarget):Void {}
}
