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

	/**
		Builds Turbo's targetless page-refresh stream action.

		Unlike DOM mutation actions, refresh intentionally has no StreamTarget:
		the receiving Turbo session refreshes the current page. Typed options can
		select replace/morph rendering, reset/preserve scrolling, and the request
		ID Turbo uses to suppress a duplicate refresh in the initiating browser.
	**/
	public static function refresh(?options:TurboRefreshOptions):Dynamic {
		return null;
	}

	public static function broadcastAppendTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastPrependTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastBeforeTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastAfterTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastReplaceTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastUpdateTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastRemoveTo<TPayload>(stream:StreamName<TPayload>, target:StreamTarget):Void {}

	/**
		Broadcasts Turbo's targetless refresh action to one typed stream.

		This is the synchronous Rails helper. Typed options become refresh-tag
		attributes; no generic attribute bag reaches Rails. Use
		`broadcastRefreshLaterTo` when Turbo should debounce and enqueue the work.
	**/
	public static function broadcastRefreshTo<TPayload>(stream:StreamName<TPayload>, ?options:TurboRefreshOptions):Void {}

	/**
		Debounces and enqueues a targetless refresh for one typed stream.

		This maps to turbo-rails' ActiveJob-backed `broadcast_refresh_later_to`.
		Turbo owns both the debounce key and job lifecycle; RailsHx only keeps the
		stream and refresh attributes typed before structural Ruby lowering.
	**/
	public static function broadcastRefreshLaterTo<TPayload>(stream:StreamName<TPayload>, ?options:TurboRefreshOptions):Void {}
}
