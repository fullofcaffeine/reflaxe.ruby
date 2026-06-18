package rails.turbo;

import js.Browser;
import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.lib.Promise;

class Turbo {
	public static function on(event:TurboEvent, handler:Event->Void, ?document:Document):Void {
		(document == null ? Browser.document : document).addEventListener(event, handler);
	}

	public static function onTyped<TDetail>(event:TurboEvent, handler:TurboTypedEvent<TDetail>->Void, ?document:Document):Void {
		on(event, function(event:Event):Void {
			handler(cast event);
		}, document);
	}

	public static function onLoad(handler:Event->Void):Void {
		on(Load, handler);
	}

	public static function onBeforeVisit(handler:TurboTypedEvent<TurboVisitDetail>->Void):Void {
		onTyped(BeforeVisit, handler);
	}

	public static function onVisit(handler:TurboTypedEvent<TurboVisitDetail>->Void):Void {
		onTyped(Visit, handler);
	}

	public static function onBeforeRender(handler:TurboTypedEvent<TurboRenderDetail>->Void):Void {
		onTyped(BeforeRender, handler);
	}

	public static function onRender(handler:TurboTypedEvent<TurboRenderDetail>->Void):Void {
		onTyped(Render, handler);
	}

	public static function onBeforeFetchRequest(handler:TurboTypedEvent<TurboFetchRequestDetail>->Void):Void {
		onTyped(BeforeFetchRequest, handler);
	}

	public static function addFetchRequestHeader(event:TurboTypedEvent<TurboFetchRequestDetail>, name:String, value:String):Void {
		if (event.detail.fetchOptions != null) {
			js.Syntax.code("{0}.headers = Object.assign({}, {0}.headers || {}, {1})", event.detail.fetchOptions, headerObject(name, value));
		}
	}

	public static function onBeforeFetchResponse(handler:TurboTypedEvent<TurboFetchResponseDetail>->Void):Void {
		onTyped(BeforeFetchResponse, handler);
	}

	public static function onFrameLoad(handler:Event->Void):Void {
		on(FrameLoad, handler);
	}

	public static function onFrameRender(handler:TurboTypedEvent<TurboFrameRenderDetail>->Void):Void {
		onTyped(FrameRender, handler);
	}

	public static function onBeforeFrameRender(handler:TurboTypedEvent<TurboFrameRenderDetail>->Void):Void {
		onTyped(BeforeFrameRender, handler);
	}

	public static function onBeforeStreamRender(handler:TurboTypedEvent<TurboStreamRenderDetail>->Void):Void {
		onTyped(BeforeStreamRender, handler);
	}

	public static function onSubmitStart(handler:TurboSubmitEvent->Void):Void {
		on(SubmitStart, function(event:Event):Void {
			handler(cast event);
		});
	}

	public static function onSubmitEnd(handler:TurboSubmitEvent->Void):Void {
		on(SubmitEnd, function(event:Event):Void {
			handler(cast event);
		});
	}

	public static function visit(location:String, ?options:TurboVisitOptions):Void {
		if (!isAvailable()) {
			Browser.window.location.assign(location);
			return;
		}
		js.Syntax.code("window.Turbo.visit({0}, {1})", location, options == null ? {} : options);
	}

	public static function renderStreamMessage(html:String):Void {
		if (!isAvailable()) {
			return;
		}
		js.Syntax.code("window.Turbo.renderStreamMessage({0})", html);
	}

	/**
		Fetch a Rails Turbo Stream endpoint and hand the response back to Turbo.

		This keeps Haxe-authored client code on the Rails/Hotwire path: Rails
		renders `<turbo-stream>` markup, Turbo mutates the DOM, and Haxe only
		provides typed orchestration instead of building HTML nodes by hand.
		Genes lowers `@:async` plus `await(...)` to native ES async/await.
	**/
	public static function fetchStream(location:String):Promise<Bool> {
		return
			js.Syntax.code("fetch({0}, { headers: { Accept: 'text/vnd.turbo-stream.html' }, credentials: 'same-origin' }).then(function(response) { if (!response.ok) return false; return response.text().then(function(html) { if (window.Turbo && typeof window.Turbo.renderStreamMessage === 'function') window.Turbo.renderStreamMessage(html); return true; }); })",
			location);
	}

	public static function stream(action:TurboStreamAction, target:String, ?template:String):String {
		if (action == Refresh) {
			return '<turbo-stream action="refresh"></turbo-stream>';
		}
		if (template == null) {
			template = "";
		}
		return '<turbo-stream action="${action}" target="${target}"><template>${template}</template></turbo-stream>';
	}

	public static function frameById(id:String, ?document:Document):Null<Element> {
		return (document == null ? Browser.document : document).getElementById(id);
	}

	public static function setFrameSrc(frame:Element, src:String):Void {
		frame.setAttribute("src", src);
	}

	public static function setFrameLoading(frame:Element, loading:TurboFrameLoading):Void {
		frame.setAttribute("loading", loading);
	}

	public static function setFrameTarget(frame:Element, target:TurboFrameTarget):Void {
		frame.setAttribute("target", target);
	}

	public static function reloadFrame(frame:Element):Void {
		if (Reflect.hasField(frame, "reload")) {
			js.Syntax.code("{0}.reload()", frame);
		} else {
			var src = frame.getAttribute("src");
			if (src != null) {
				frame.setAttribute("src", src);
			}
		}
	}

	public static function isAvailable():Bool {
		return js.Syntax.code("typeof window.Turbo !== 'undefined' && typeof window.Turbo.visit === 'function'");
	}

	static function headerObject(name:String, value:String):{} {
		return js.Syntax.code("({ [{0}]: {1} })", name, value);
	}
}
