package rails.turbo;

/**
	Closed rendering strategy for a Turbo page refresh.

	`Replace` performs the ordinary page-body replacement. `Morph` asks Turbo to
	diff the incoming page so compatible DOM state can survive the refresh.
**/
enum abstract TurboRefreshMethod(String) to String {
	var Replace = "replace";
	var Morph = "morph";
}
