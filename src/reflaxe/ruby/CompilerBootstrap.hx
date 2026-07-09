package reflaxe.ruby;

#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.FileSystem;
#end

class CompilerBootstrap {
	#if macro
	static var bootstrapped = false;

	public static function Start():Void {
		if (bootstrapped) {
			return;
		}
		bootstrapped = true;

		var root = findLibraryRoot();
		var stagedStd = Path.normalize(Path.join([root, "std", "ruby", "_std"]));
		var standardLibrary = Path.normalize(Path.join([root, "std"]));
		var vendoredReflaxe = Path.normalize(Path.join([root, "vendor", "reflaxe", "src"]));

		if (BuildDetection.isRubyBuild()) {
			injectClassPathsFirst(filterExistingPaths([stagedStd, standardLibrary, vendoredReflaxe]));
			return;
		}

		injectClassPathsFirst(filterExistingPaths([vendoredReflaxe]));
	}

	static function filterExistingPaths(paths:Array<String>):Array<String> {
		var out = new Array<String>();
		for (path in paths) {
			var normalized = Path.normalize(path);
			if (FileSystem.exists(normalized) && FileSystem.isDirectory(normalized)) {
				out.push(normalized);
			}
		}
		return out;
	}

	static function injectClassPathsFirst(paths:Array<String>):Void {
		if (paths == null || paths.length == 0) {
			return;
		}

		var config = Compiler.getConfiguration();
		if (config == null) {
			for (path in paths) {
				Compiler.addClassPath(path);
			}
			return;
		}

		var classPathField = "classPath";
		var existingDynamic:Dynamic = null;
		if (Reflect.hasField(config, "classPath")) {
			existingDynamic = Reflect.field(config, "classPath");
		} else if (Reflect.hasField(config, "classPaths")) {
			classPathField = "classPaths";
			existingDynamic = Reflect.field(config, "classPaths");
		}

		if (existingDynamic == null || !Std.isOfType(existingDynamic, Array)) {
			for (path in paths) {
				Compiler.addClassPath(path);
			}
			return;
		}

		var existing:Array<String> = cast existingDynamic;
		var injected = new Map<String, Bool>();
		var deduped = new Array<String>();
		for (path in paths) {
			var normalized = Path.normalize(path);
			if (!injected.exists(normalized)) {
				injected.set(normalized, true);
				deduped.push(normalized);
			}
		}

		var keep = new Array<String>();
		for (path in existing) {
			var normalized = Path.normalize(path);
			if (!injected.exists(normalized)) {
				keep.push(path);
			}
		}

		Reflect.setField(config, classPathField, deduped.concat(keep));
	}

	static function findLibraryRoot():String {
		var thisFile = Context.resolvePath("reflaxe/ruby/CompilerBootstrap.hx");
		var srcDir = Path.normalize(Path.directory(thisFile));
		return Path.normalize(Path.join([srcDir, "..", "..", ".."]));
	}
	#else
	public static function Start():Void {}
	#end
}
