package rails.turbo;

import rails.action_view.Template;

@:rubyRequire("turbo-rails")
class TurboStreams {
	// These methods return `Dynamic` so app code can pass a typed stream action
	// into `render({turboStream: ...})`. The Haxe body is never the Rails
	// runtime: reflaxe.ruby lowers these calls directly to `turbo_stream.*`.
	public static function append<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Dynamic {
		return null;
	}

	public static function prepend<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Dynamic {
		return null;
	}

	public static function before<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Dynamic {
		return null;
	}

	public static function after<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Dynamic {
		return null;
	}

	public static function replace<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Dynamic {
		return null;
	}

	public static function update<TLocals>(target:StreamTarget, template:Template<TLocals>, locals:TLocals):Dynamic {
		return null;
	}

	public static function remove(target:StreamTarget):Dynamic {
		return null;
	}

	public static function broadcastAppendTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastPrependTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastBeforeTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastAfterTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastReplaceTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastUpdateTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastRemoveTo<TPayload>(stream:StreamName<TPayload>, target:StreamTarget):Void {}
}
