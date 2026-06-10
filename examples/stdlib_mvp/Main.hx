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
		Sys.println(Std.isOfType("ruby", String));
		Sys.println(Std.isOfType(7, Int));
		Sys.println(Std.isOfType(7, Float));
		Sys.println(Std.isOfType(7.5, Int));
		Sys.println(Std.is(true, Bool));
		Sys.println(Std.isOfType([1, 2], Array));
		Sys.println(Std.isOfType(null, Dynamic));
		var stringType:Dynamic = String;
		Sys.println(Std.isOfType("dynamic", stringType));
		var arrayType:Dynamic = Array;
		Sys.println(Std.isOfType([3, 4], arrayType));
		var box:Dynamic = new StdTypeBox();
		Sys.println(Std.isOfType(box, StdTypeBox));
		Sys.println(Std.isOfType("ruby", StdTypeBox));

		var names = new haxe.ds.StringMap<Int>();
		names.set("ruby", 3);
		Sys.println(names.get("ruby"));
		Sys.println(names.exists("ruby"));
		Sys.println(names.remove("ruby"));
		Sys.println(names.exists("ruby"));
		names.set("ruby", 3);
		names.set("haxe", 4);
		var total = 0;
		for (value in names.iterator()) {
			total += value;
		}
		Sys.println(total);
		var keyChars = 0;
		for (key in names.keys()) {
			keyChars += key.length;
		}
		Sys.println(keyChars);
		var namesCopy = names.copy();
		Sys.println(namesCopy.get("haxe"));

		var ids = new haxe.ds.IntMap<String>();
		ids.set(7, "seven");
		Sys.println(ids.get(7));

		var key = {name: "coffee"};
		var objects = new haxe.ds.ObjectMap<{name:String}, String>();
		objects.set(key, "bean");
		Sys.println(objects.get(key));
		objects.clear();
		Sys.println(objects.exists(key));
	}
}

class StdTypeBox {
	public function new() {}
}
