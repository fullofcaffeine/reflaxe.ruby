package rails.turbo;

/**
	Closed scroll strategy for a Turbo page refresh.

	`Reset` uses the normal top-left refresh position. `Preserve` retains the
	current horizontal and vertical scroll position.
**/
enum abstract TurboRefreshScroll(String) to String {
	var Reset = "reset";
	var Preserve = "preserve";
}
