package sys;

@:rubyRequire("fileutils")
class FileSystem {
	public static inline function exists(path:String):Bool {
		return untyped __ruby__("(::File.exist?({0}) || ::File.symlink?({0}))", path);
	}

	public static inline function rename(path:String, newPath:String):Void {
		untyped __ruby__("(::File.rename({0}, {1}); nil)", path, newPath);
	}

	public static inline function stat(path:String):FileStat {
		var stat:Dynamic = untyped __ruby__("::File.stat({0})", path);
		return {
			gid: untyped __ruby__("{0}.gid", stat),
			uid: untyped __ruby__("{0}.uid", stat),
			atime: rubyTimeToDate(untyped __ruby__("{0}.atime", stat)),
			mtime: rubyTimeToDate(untyped __ruby__("{0}.mtime", stat)),
			ctime: rubyTimeToDate(untyped __ruby__("{0}.ctime", stat)),
			size: untyped __ruby__("{0}.size", stat),
			dev: untyped __ruby__("{0}.dev", stat),
			ino: untyped __ruby__("{0}.ino", stat),
			nlink: untyped __ruby__("{0}.nlink", stat),
			rdev: untyped __ruby__("{0}.rdev", stat),
			mode: untyped __ruby__("{0}.mode", stat)
		};
	}

	public static inline function fullPath(relPath:String):String {
		return untyped __ruby__("::File.realpath({0})", relPath);
	}

	public static inline function absolutePath(relPath:String):String {
		return untyped __ruby__("::File.expand_path({0})", relPath);
	}

	public static inline function isDirectory(path:String):Bool {
		return untyped __ruby__("(raise Errno::ENOENT, {0} unless (::File.exist?({0}) || ::File.symlink?({0})); ::File.directory?({0}))", path);
	}

	public static inline function createDirectory(path:String):Void {
		untyped __ruby__("(::FileUtils.mkdir_p({0}); nil)", path);
	}

	public static inline function deleteFile(path:String):Void {
		untyped __ruby__("(::File.delete({0}); nil)", path);
	}

	public static inline function deleteDirectory(path:String):Void {
		untyped __ruby__("(::Dir.rmdir({0}); nil)", path);
	}

	public static inline function readDirectory(path:String):Array<String> {
		return untyped __ruby__("(raise Errno::ENOENT, {0} unless ::File.directory?({0}); ::Dir.children({0}))", path);
	}

	static inline function rubyTimeToDate(value:Dynamic):Date {
		return new Date(untyped __ruby__("{0}.year", value), untyped __ruby__("{0}.month - 1", value), untyped __ruby__("{0}.day", value),
			untyped __ruby__("{0}.hour", value), untyped __ruby__("{0}.min", value), untyped __ruby__("{0}.sec", value));
	}
}
