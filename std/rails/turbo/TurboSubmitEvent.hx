package rails.turbo;

import js.html.EventTarget;

typedef TurboSubmitEvent = {
	var target:EventTarget;
	var detail:{
		var ?formSubmission:TurboFormSubmission;
		var ?success:Bool;
		var ?fetchResponse:Dynamic;
	};
}
