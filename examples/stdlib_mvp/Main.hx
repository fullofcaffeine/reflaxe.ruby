// Standard-library MVP coverage.
//
// Demonstrates: the currently supported Haxe std surface for `Std`,
// `StringTools`, `Math`, `Sys`, reflection-ish `Type`, arrays, and maps.
// Type safety: calls use normal Haxe std signatures, so wrong argument types
// fail before Ruby is emitted; runtime helpers only exist where Ruby semantics
// need adaptation to Haxe behavior.
// IntelliSense: editors should complete the same Haxe std APIs users would
// expect on other targets, with inferred result types for chained expressions.
// Ruby output: direct Ruby methods where semantics match and `HXRuby` runtime
// helpers where Haxe compatibility requires extra behavior.
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
		Sys.println(StringTools.replace("a", "a", "\\1"));
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
		var parsedJson:Dynamic = haxe.Json.parse("{\"name\":\"ruby\",\"count\":2,\"items\":[1,null,true]}");
		Sys.println(Reflect.field(parsedJson, "name"));
		Sys.println(Reflect.field(parsedJson, "count") + 1);
		Sys.println(Reflect.field(parsedJson, "items")[1] == null);
		Sys.println(haxe.Json.stringify({name: "ruby", count: 2}));
		Sys.println(haxe.Json.stringify(["ruby", null, true]));
		Sys.println(StringTools.contains(haxe.Json.stringify({nested: {ok: true}}, null, "  "), "\n  \"nested\""));
		// Strict snapshot builds focus on app-authored raw-boundary checks. The
		// runtime smoke below still exercises sys.* direct Ruby std lowering.
		#if !reflaxe_ruby_strict_examples
		var fsRoot = "test/.generated/stdlib_mvp/fs_probe";
		var fsNested = fsRoot + "/nested";
		var fsFile = fsNested + "/note.txt";
		var fsCopy = fsNested + "/copy.txt";
		var fsRenamed = fsNested + "/renamed.txt";
		var fsBytes = fsNested + "/bytes.bin";
		if (sys.FileSystem.exists(fsRenamed)) {
			sys.FileSystem.deleteFile(fsRenamed);
		}
		if (sys.FileSystem.exists(fsCopy)) {
			sys.FileSystem.deleteFile(fsCopy);
		}
		if (sys.FileSystem.exists(fsFile)) {
			sys.FileSystem.deleteFile(fsFile);
		}
		if (sys.FileSystem.exists(fsBytes)) {
			sys.FileSystem.deleteFile(fsBytes);
		}
		if (sys.FileSystem.exists(fsNested)) {
			sys.FileSystem.deleteDirectory(fsNested);
		}
		if (sys.FileSystem.exists(fsRoot)) {
			sys.FileSystem.deleteDirectory(fsRoot);
		}
		sys.FileSystem.createDirectory(fsNested);
		sys.io.File.saveContent(fsFile, "typed fs");
		Sys.println(sys.FileSystem.exists(fsFile));
		Sys.println(sys.FileSystem.isDirectory(fsNested));
		Sys.println(sys.io.File.getContent(fsFile));
		var fsStat = sys.FileSystem.stat(fsFile);
		Sys.println(fsStat.size);
		Sys.println(sys.FileSystem.absolutePath(fsFile).length > fsFile.length);
		Sys.println(sys.FileSystem.fullPath(fsFile).length > fsFile.length);
		sys.io.File.copy(fsFile, fsCopy);
		Sys.println(sys.io.File.getContent(fsCopy));
		sys.io.File.saveBytes(fsBytes, haxe.io.Bytes.ofString("bin"));
		Sys.println(sys.io.File.getBytes(fsBytes).toString());
		var fsEntries = sys.FileSystem.readDirectory(fsNested);
		Sys.println(fsEntries.indexOf("note.txt") >= 0);
		sys.FileSystem.rename(fsFile, fsRenamed);
		Sys.println(sys.FileSystem.exists(fsRenamed));
		Sys.println(!sys.FileSystem.exists(fsFile));
		sys.FileSystem.deleteFile(fsRenamed);
		sys.FileSystem.deleteFile(fsCopy);
		sys.FileSystem.deleteFile(fsBytes);
		sys.FileSystem.deleteDirectory(fsNested);
		sys.FileSystem.deleteDirectory(fsRoot);
		Sys.println(!sys.FileSystem.exists(fsRoot));
		#end
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
		Sys.println(Std.string(rgbParams.length)
			+ ":"
			+ Std.string(rgbParams[0])
			+ ":"
			+ Std.string(rgbParams[1])
			+ ":"
			+ Std.string(rgbParams[2]));
		Sys.println(Type.enumEq(rgb, StdTypeColor.Rgb(1, 2, 3)));
		Sys.println(Type.enumEq(rgb, StdTypeColor.Rgb(1, 2, 4)));
		Sys.println(Type.enumConstructor(Type.allEnums(colorEnum)[0]));
		Sys.println(Type.enumConstructor(Type.typeof(null)));
		Sys.println(Type.enumConstructor(Type.typeof(1)));
		Sys.println(Type.enumConstructor(Type.typeof(1.5)));
		Sys.println(Type.enumConstructor(Type.typeof(true)));
		Sys.println(Type.enumConstructor(Type.typeof(StdTypeColor.Red)));
		var reflected:Dynamic = {name: "ruby", count: 2};
		Sys.println(Reflect.hasField(reflected, "name"));
		Sys.println(Reflect.field(reflected, "name"));
		Reflect.setField(reflected, "count", 3);
		Sys.println(Reflect.field(reflected, "count"));
		Sys.println(Reflect.fields(reflected).join("|"));
		var reflectedCopy:Dynamic = Reflect.copy(reflected);
		Reflect.setField(reflectedCopy, "name", "haxe");
		Sys.println(Reflect.field(reflected, "name") + ":" + Reflect.field(reflectedCopy, "name"));
		Sys.println(Reflect.deleteField(reflected, "count"));
		Sys.println(Reflect.hasField(reflected, "count"));
		var reflectedBox:Dynamic = new StdReflectBox("typed");
		Sys.println(Reflect.hasField(reflectedBox, "label"));
		Sys.println(Reflect.field(reflectedBox, "label"));
		Reflect.setField(reflectedBox, "label", "updated");
		Sys.println(Reflect.getProperty(reflectedBox, "label"));
		Reflect.setProperty(reflectedBox, "label", "property");
		Sys.println(reflectedBox.label);
		Sys.println(Reflect.callMethod(reflectedBox, Reflect.field(reflectedBox, "describe"), ["box"]));
		Sys.println(Reflect.callMethod(reflectedBox, Reflect.field(reflectedBox, "ping"), []));
		var varArgs = Reflect.makeVarArgs(function(values:Array<Dynamic>) return values.length);
		Sys.println(varArgs(1, 2, 3));
		Sys.println(Reflect.isFunction(varArgs));
		Sys.println(Reflect.compare(1, 2) < 0);
		Sys.println(Reflect.compareMethods(Reflect.field(reflectedBox, "describe"), Reflect.field(reflectedBox, "describe")));
		Sys.println(Reflect.isObject(reflectedBox));
		Sys.println(Reflect.isObject("yes"));
		Sys.println(Reflect.isEnumValue(StdTypeColor.Red));
		Sys.println(Type.getInstanceFields(StdReflectBox).indexOf("describe") >= 0);
		Sys.println(Type.getClassFields(StdReflectStatics).indexOf("answer") >= 0);

		var numbers = [1, 2, 3];
		Sys.println(numbers.push(4));
		Sys.println(numbers.join(":"));
		Sys.println(numbers.pop());
		Sys.println(numbers.shift());
		numbers.unshift(0);
		Sys.println(Std.string(numbers));
		Sys.println(Std.string(numbers.concat([4, 5])));
		Sys.println(Std.string(numbers));
		numbers.insert(-99, -1);
		numbers.insert(99, 4);
		Sys.println(Std.string(numbers));
		Sys.println(Std.string(numbers.slice(-3, 99)));
		Sys.println(Std.string(numbers.slice(99)));
		var removedNumbers = numbers.splice(-3, 2);
		Sys.println(Std.string(removedNumbers));
		Sys.println(Std.string(numbers));
		Sys.println(numbers.remove(0));
		Sys.println(numbers.remove(8));
		Sys.println(numbers.contains(4));
		Sys.println(numbers.indexOf(4));
		Sys.println(numbers.indexOf(-1, -99));
		Sys.println(numbers.lastIndexOf(4, 99));
		var copiedNumbers = numbers.copy();
		copiedNumbers.push(9);
		Sys.println(Std.string(numbers));
		Sys.println(Std.string(copiedNumbers));
		Sys.println(Std.string(numbers.map(function(value) return value * 2)));
		Sys.println(Std.string(numbers.filter(function(value) return value > 0)));
		var nullableNumbers:Array<Null<Int>> = [1, 2];
		nullableNumbers.resize(4);
		Sys.println(nullableNumbers.length);
		Sys.println(nullableNumbers[2] == null);
		nullableNumbers.resize(1);
		Sys.println(Std.string(nullableNumbers));
		var sorted = [3, 1, 2];
		sorted.sort(function(left, right) return left - right);
		Sys.println(Std.string(sorted));
		sorted.reverse();
		Sys.println(sorted.toString());

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

class StdReflectBox {
	public var label:String;

	public function new(label:String) {
		this.label = label;
	}

	public function get_label():String {
		return "get:" + label;
	}

	public function set_label(value:String):String {
		label = "set:" + value;
		return label;
	}

	public function describe(prefix:String):String {
		return prefix + ":" + label;
	}

	public function ping():String {
		return "pong:" + label;
	}
}

class StdReflectStatics {
	public static function answer():Int {
		return 42;
	}
}

enum StdTypeColor {
	Red;
	Rgb(r:Int, g:Int, b:Int);
}
