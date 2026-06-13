package rails.turbo;

typedef TurboTypedEvent<TDetail> = {
	var target:Dynamic;
	var detail:TDetail;
	function preventDefault():Void;
}
