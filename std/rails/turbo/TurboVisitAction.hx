package rails.turbo;

enum abstract TurboVisitAction(String) to String {
	var Advance = "advance";
	var Replace = "replace";
	var Restore = "restore";
}
