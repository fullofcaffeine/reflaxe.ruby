package rails.turbo;

typedef TurboSubmitEvent = {
	var target:Dynamic;
	var detail:{
		var ?formSubmission:TurboFormSubmission;
		var ?success:Bool;
		var ?fetchResponse:Dynamic;
	};
}
