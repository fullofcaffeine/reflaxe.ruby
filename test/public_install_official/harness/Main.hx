import unit.issues.Issue10098;
import unitstd_ruby.UpstreamUnitStdMacro;

/**
	Runs one provenance-pinned case from each official-source family through the
	installed compiler. Package isolation is enforced by the owning Node harness.
**/
@:access(unit.issues.Issue10098)
class Main {
	static function main():Void {
		switch Sys.args()[0] {
			case "assertion-failure":
				new unit.Test().eq("intentional-actual", "intentional-expected");
				return;
			case "runtime-failure":
				throw "intentional-public-install-runtime-failure";
			case _:
		}
		unit.Test.reset();
		new unit.TestOps().testOps();
		new Issue10098().test();
		UpstreamUnitStdMacro.assertSpec("StringBuf.unit.hx");

		var assertions = unit.Test.assertionCount();
		if (assertions < 50) {
			throw 'official representative assertion accounting regressed: $assertions';
		}
		Sys.println('public-install-official ok families=3 topLevelAssertions=$assertions');
	}
}
