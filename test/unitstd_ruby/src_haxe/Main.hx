import haxe.macro.Expr;
import unit.spec.C;
import unit.spec.C.C2;
import unit.spec.C.CChild;
import unit.spec.C.ClassWithCtorDefaultValues;
import unit.spec.C.ClassWithCtorDefaultValues2;
import unit.spec.C.ClassWithCtorDefaultValuesChild;
import unit.spec.C.EmptyClass;
import unit.spec.C.ReallyEmptyClass;
import unit.spec.RttiFixtures.NonRttiClass;
import unit.spec.RttiFixtures.RttiClass1;
import unit.spec.RttiFixtures.RttiClass2;
import unit.spec.RttiFixtures.RttiClass3;
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
		UpstreamUnitStdMacro.assertSpec("Type.unit.hx");
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
		UpstreamUnitStdMacro.assertSpec("haxe/rtti/Rtti.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/zip/Compress.unit.hx");
		UpstreamUnitStdMacro.assertSpec("haxe/zip/Uncompress.unit.hx");
		UpstreamUnitStdMacro.assertSpec("sys/io/File.unit.hx");
		unitstd_ruby.ERegSemantics.run();
		unitstd_ruby.MapSemantics.run();
		unitstd_ruby.StdNumericParsing.run();
		unitstd_ruby.ZipSemantics.run();
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

private enum E {
	NoArgs;
	OneArg(value:Int);
	RecArg(value:E);
	MultipleArgs(value:Int, text:String);
}

private enum EVMTest {
	EVMA;
	EVMB(?value:String);
}
