import unitstd_ruby.UpstreamUnitStdMacro;

/**
	Top-level entrypoint for the upstream unitstd Ruby runtime lane.

	A top-level `Main` deliberately exercises the normal pure-Ruby entrypoint
	contract, including generated runtime helper files and the `if __FILE__`
	wrapper that calls `Main.main()`.
**/
class Main {
	static function main():Void {
		UpstreamUnitStdMacro.assertSpec("StringBuf.unit.hx");
		Sys.println("unitstd-ruby ok");
	}
}
