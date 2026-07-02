package unitstd_ruby;

/**
	Focused Haxe `Std` parsing parity checks.

	Ruby's native `Integer(...)` and `Float(...)` parse whole strings, while Haxe
	`Std.parseInt`/`Std.parseFloat` return the valid numeric prefix. These cases
	document why the compact `HXRuby` helpers exist instead of lowering every call
	to a direct Ruby core conversion.
**/
class StdNumericParsing {
	public static function run():Void {
		Assert.isTrue(Std.parseInt("100x123") == 100, "Std.parseInt parses decimal prefixes");
		Assert.isTrue(Std.parseInt("23e2") == 23, "Std.parseInt does not parse scientific notation");
		Assert.isTrue(Std.parseInt("0x10z") == 16, "Std.parseInt parses hexadecimal prefixes");
		Assert.isTrue(Std.parseInt("-0xa0") == -160, "Std.parseInt preserves hexadecimal signs");
		Assert.isTrue(Std.parseInt("0b10") == 0, "Std.parseInt does not treat binary notation specially");
		Assert.isTrue(Std.parseInt("++123") == null, "Std.parseInt rejects repeated signs");

		Assert.inDelta(100.0, Std.parseFloat("100x123"), 0.00001, "Std.parseFloat parses decimal prefixes");
		Assert.inDelta(5.3, Std.parseFloat("5.3 1"), 0.00001, "Std.parseFloat stops after the float prefix");
		Assert.inDelta(6.0, Std.parseFloat("6e"), 0.00001, "Std.parseFloat ignores incomplete exponents");
		Assert.isTrue(Math.isNaN(Std.parseFloat("+-12.3")), "Std.parseFloat rejects invalid signs");
	}
}
