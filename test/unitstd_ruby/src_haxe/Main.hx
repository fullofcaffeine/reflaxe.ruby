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
		UpstreamUnitStdMacro.assertSpec("IntIterator.unit.hx");
		UpstreamUnitStdMacro.assertSpec("String.unit.hx");
		UpstreamUnitStdMacro.assertSpec("StringTools.unit.hx");
		UpstreamUnitStdMacro.assertSpec("Math.unit.hx");
		UpstreamUnitStdMacro.assertSpec("Std.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/io/BytesBuffer.unit.hx");
		unitstd_ruby.StdNumericParsing.run();
		Sys.println("unitstd-ruby ok");
	}
}
