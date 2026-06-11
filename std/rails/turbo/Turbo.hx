package rails.turbo;

import js.Browser;
import js.html.Document;
import js.html.Event;

enum abstract TurboEvent(String) to String {
	var BeforeCache = "turbo:before-cache";
	var BeforeRender = "turbo:before-render";
	var BeforeVisit = "turbo:before-visit";
	var Load = "turbo:load";
	var SubmitEnd = "turbo:submit-end";
	var SubmitStart = "turbo:submit-start";
}

typedef TurboVisitOptions = {
	var ?action:String;
	var ?acceptsStreamResponse:Bool;
	var ?frame:String;
}

typedef TurboSubmitEvent = {
	var target:Dynamic;
	var detail:Dynamic;
}

class Turbo {
	public static function on(event:TurboEvent, handler:Event->Void, ?document:Document):Void {
		(document == null ? Browser.document : document).addEventListener(event, handler);
	}

	public static function onLoad(handler:Event->Void):Void {
		on(Load, handler);
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

	public static function isAvailable():Bool {
		return js.Syntax.code("typeof window.Turbo !== 'undefined' && typeof window.Turbo.visit === 'function'");
	}
}
