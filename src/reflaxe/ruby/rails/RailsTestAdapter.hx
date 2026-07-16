package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
/** Selects the native Rails test framework shape emitted for `@:railsTest`. **/
enum RailsTestAdapter {
	RailsMinitest;
	RailsRspec;
}
#end
