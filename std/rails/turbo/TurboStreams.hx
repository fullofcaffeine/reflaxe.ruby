package rails.turbo;

import rails.action_view.Template;

/**
	Typed server-side Turbo Stream actions and broadcasts.

	The compiler lowers this facade to ordinary turbo-rails helpers; it does not
	emit a RailsHx runtime wrapper. Generic stream, target, template, and locals
	types keep rendering contracts aligned before Ruby or ActiveJob executes.
**/
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
		Enqueues Rails-native rendering broadcasts for one typed stream.

		These six methods mirror turbo-rails' named `*_later_to` helpers. They
		keep the stream, DOM target, partial, and locals tied to one `TLocals`
		contract while `Turbo::Streams::ActionBroadcastJob` owns rendering and
		delivery. There is intentionally no `broadcastRemoveLaterTo`: turbo-rails
		2.0.23 exposes no named delayed-remove convenience method.
	**/
	public static function broadcastAppendLaterTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastPrependLaterTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastBeforeLaterTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastAfterLaterTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastReplaceLaterTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

	public static function broadcastUpdateLaterTo<TLocals>(stream:StreamName<TLocals>, target:StreamTarget, template:Template<TLocals>, locals:TLocals):Void {}

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
