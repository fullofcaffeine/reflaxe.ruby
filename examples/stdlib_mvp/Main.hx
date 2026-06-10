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
		Sys.println(Math.PI > 3);
		Sys.println(Math.abs(-4));
		Sys.println(Math.min(3, -2));
		Sys.println(Math.max(3, -2));
		Sys.println(Math.floor(3.8));
		Sys.println(Math.ceil(3.2));
		Sys.println(Math.round(-0.5));
		Sys.println(Math.round(0.5));
		Sys.println(Math.sqrt(9));
		Sys.println(Math.pow(2, 3));
		Sys.println(Math.isNaN(Math.sqrt(-1)));
		Sys.println(Math.isFinite(Math.POSITIVE_INFINITY));
		Sys.println(Std.random(10) >= 0);
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
		var boxClass = Type.getClass(box);
		Sys.println(Type.getClassName(boxClass));
		Sys.println(Type.getClassName(Type.resolveClass("StdTypeBox")));
		var createdBox = Type.createInstance(cast boxClass, []);
		Sys.println(Std.isOfType(createdBox, StdTypeBox));
		var colorEnum = Type.getEnum(StdTypeColor.Red);
		Sys.println(Type.getEnumName(colorEnum));
		Sys.println(Type.getEnumConstructs(colorEnum).join("|"));
		var rgb = Type.createEnum(colorEnum, "Rgb", [1, 2, 3]);
		Sys.println(Type.enumConstructor(rgb));
		Sys.println(Type.enumIndex(rgb));
		var rgbParams = Type.enumParameters(rgb);
		Sys.println(Std.string(rgbParams.length) + ":" + Std.string(rgbParams[0]) + ":" + Std.string(rgbParams[1]) + ":" + Std.string(rgbParams[2]));
		Sys.println(Type.enumEq(rgb, StdTypeColor.Rgb(1, 2, 3)));
		Sys.println(Type.enumEq(rgb, StdTypeColor.Rgb(1, 2, 4)));
		Sys.println(Type.enumConstructor(Type.allEnums(colorEnum)[0]));
		Sys.println(Type.enumConstructor(Type.typeof(null)));
		Sys.println(Type.enumConstructor(Type.typeof(1)));
		Sys.println(Type.enumConstructor(Type.typeof(1.5)));
		Sys.println(Type.enumConstructor(Type.typeof(true)));
		Sys.println(Type.enumConstructor(Type.typeof(StdTypeColor.Red)));

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

enum StdTypeColor {
	Red;
	Rgb(r:Int, g:Int, b:Int);
}
