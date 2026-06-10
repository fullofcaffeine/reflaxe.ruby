class Main {
	static function main() {
		Sys.println(Std.string(null));
		Sys.println(Std.parseInt("41") + 1);
		Sys.println(Std.parseFloat("3.5") + 0.5);
		Sys.println(StringTools.trim("  typed rails  "));
		Sys.println(StringTools.startsWith("reflaxe.ruby", "reflaxe"));
		Sys.println(StringTools.endsWith("reflaxe.ruby", "ruby"));
		Sys.println(StringTools.contains("haxe to ruby", "ruby"));
		Sys.println(StringTools.replace("typed rails", "rails", "ruby"));
		Sys.println(StringTools.hex(255, 4));
		Sys.println(StringTools.urlDecode("typed+ruby"));
		Sys.putEnv("HXRUBY_STDLIB_MVP", "typed");
		Sys.println(Sys.getEnv("HXRUBY_STDLIB_MVP"));
		Sys.println(Sys.getCwd().length > 0);
		Sys.println(Sys.args().length >= 0);
	}
}
