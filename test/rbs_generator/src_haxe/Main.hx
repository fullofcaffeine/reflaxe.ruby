package;

import generated.rbs.FixtureCatalog;
import ruby.Kernel;

/**
	Exercises a generated strict RBS extern as an executable QA contract.
	Completion exposes only the reviewed nominal methods, while Ruby output calls
	the fixture's ordinary class directly after one generated `require`.
**/
class Main {
	static function main() {
		final catalog = new FixtureCatalog("typed");
		Kernel.puts(catalog.labelFor("item", 2));
		Kernel.puts(catalog.maybeLabel(null));
		Kernel.puts(catalog.empty());
		Kernel.puts(catalog.nestedRows([["a", "b"], ["c"]])[0].join(":"));
		Kernel.puts(FixtureCatalog.normalize("  READY  "));
	}
}
