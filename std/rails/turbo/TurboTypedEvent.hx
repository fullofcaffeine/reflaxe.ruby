package rails.turbo;

import js.html.EventTarget;

typedef TurboTypedEvent<TDetail> = {
	var target:EventTarget;
	var detail:TDetail;
	function preventDefault():Void;
}
