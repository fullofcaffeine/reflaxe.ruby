import unitstd_ruby.UpstreamUnitStdMacro;

/**
	Top-level entrypoint for the upstream unitstd Ruby runtime lane.

	A top-level `Main` deliberately exercises the normal pure-Ruby entrypoint
	contract, including generated runtime helper files and the `if __FILE__`
	wrapper that calls `Main.main()`.
**/
class Main {
	static function main():Void {
		UpstreamUnitStdMacro.assertSpec("Array.unit.hx");
		UpstreamUnitStdMacro.assertSpec("Date.unit.hx");
		UpstreamUnitStdMacro.assertSpec("DateTools.unit.hx");
		UpstreamUnitStdMacro.assertSpec("EReg.unit.hx");
		UpstreamUnitStdMacro.assertSpec("StringBuf.unit.hx");
		UpstreamUnitStdMacro.assertSpec("IntIterator.unit.hx");
		UpstreamUnitStdMacro.assertSpec("String.unit.hx");
		UpstreamUnitStdMacro.assertSpec("StringTools.unit.hx");
		UpstreamUnitStdMacro.assertSpec("Lambda.unit.hx");
		UpstreamUnitStdMacro.assertSpec("List.unit.hx");
		UpstreamUnitStdMacro.assertSpec("Map.unit.hx");
		UpstreamUnitStdMacro.assertSpec("Math.unit.hx");
		UpstreamUnitStdMacro.assertSpec("Reflect.unit.hx");
		UpstreamUnitStdMacro.assertSpec("Std.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/DynamicAccess.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/EnumFlags.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/Log.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/Template.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Base64.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Crc32.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Hmac.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Md5.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Sha1.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Sha224.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/crypto/Sha256.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/ds/BalancedTree.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/ds/GenericStack.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/extern/EitherType.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/io/BytesBuffer.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/io/Path.unit.hx");
		unitstd_ruby.ERegSemantics.run();
		unitstd_ruby.MapSemantics.run();
		unitstd_ruby.StdNumericParsing.run();
		Sys.println("unitstd-ruby ok");
	}
}

/**
	Fixture helpers mirrored from upstream unitstd TestSpecification so copied
	expression specs can resolve enum constructors exactly as the upstream lane
	does.
**/
private enum EnumFlagTest {
	EA;
	EB;
	EC;
}

private enum EnumFlagTest2 {
	EF_00;
	EF_01;
	EF_02;
	EF_03;
	EF_04;
	EF_05;
	EF_06;
	EF_07;
	EF_08;
	EF_09;
	EF_10;
	EF_11;
	EF_12;
	EF_13;
	EF_14;
	EF_15;
	EF_16;
	EF_17;
	EF_18;
	EF_19;
	EF_20;
	EF_21;
	EF_22;
	EF_23;
	EF_24;
	EF_25;
	EF_26;
	EF_27;
	EF_28;
	EF_29;
	EF_30;
	EF_31;
}

@:keep
private class C {
	public var v:String;
	public var prop(default, null):String;

	public function new() {
		v = "var";
		prop = "prop";
	}

	public function func():Void {}
}

@:keep
private class C2 {
	public var v:String;
	public var prop(default, null):String;
	@:isVar public var propAcc(get, set):String;

	public function new() {
		v = "var";
		prop = "prop";
		propAcc = "0";
	}

	public function func():String {
		return "foo";
	}

	public function get_propAcc():String {
		return "1";
	}

	public function set_propAcc(value:String):String {
		return this.propAcc = value.toUpperCase();
	}
}

private class CChild extends C {}

private class EmptyClass {
	public function new() {}
}

@:keep
private class ReallyEmptyClass {}

private enum E {
	NoArgs;
	OneArg(value:Int);
}

private enum EVMTest {
	EVMA;
	EVMB(?value:String);
}
