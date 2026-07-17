using rails.active_support.ObjectPresence;
using rails.active_support.StringFilters;

/** Proves non-temporal ActiveSupport facades do not load the temporal slice. **/
class ExtensionsOnly {
	static function main():Void {
		Sys.println("  typed receiver  ".squish().present());
	}
}
