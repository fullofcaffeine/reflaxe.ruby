package rails.turbo;

enum abstract TurboStreamAction(String) to String {
	var After = "after";
	var Append = "append";
	var Before = "before";
	var Prepend = "prepend";
	var Refresh = "refresh";
	var Remove = "remove";
	var Replace = "replace";
	var Update = "update";
}
