package sys.io;

import haxe.io.Bytes;

@:rubyRequire("fileutils")
class File {
	public static inline function getContent(path:String):String {
		return untyped __ruby__("::File.read({0})", path);
	}

	public static inline function saveContent(path:String, content:String):Void {
		untyped __ruby__("(::File.write({0}, {1}); nil)", path, content);
	}

	public static inline function getBytes(path:String):Bytes {
		var data:Array<Int> = untyped __ruby__("::File.binread({0}).bytes.to_a", path);
		return new Bytes(data.length, data);
	}

	public static inline function saveBytes(path:String, bytes:Bytes):Void {
		untyped __ruby__("(::File.binwrite({0}, {1}.get_data().pack('C*')); nil)", path, bytes);
	}

	public static inline function read(path:String, binary:Bool = true):FileInput {
		return @:privateAccess new FileInput(untyped __ruby__("::File.open({0}, {1})", path, binary ? "rb" : "r"));
	}

	public static inline function write(path:String, binary:Bool = true):FileOutput {
		return @:privateAccess new FileOutput(untyped __ruby__("::File.open({0}, {1})", path, binary ? "wb" : "w"));
	}

	public static inline function append(path:String, binary:Bool = true):FileOutput {
		return @:privateAccess new FileOutput(untyped __ruby__("::File.open({0}, {1})", path, binary ? "ab" : "a"));
	}

	public static inline function update(path:String, binary:Bool = true):FileOutput {
		if (!sys.FileSystem.exists(path)) {
			untyped __ruby__("(::File.open({0}, 'wb').close; nil)", path);
		}
		return @:privateAccess new FileOutput(untyped __ruby__("::File.open({0}, {1})", path, binary ? "rb+" : "r+"));
	}

	public static inline function copy(srcPath:String, dstPath:String):Void {
		untyped __ruby__("(::FileUtils.copy_file({0}, {1}); nil)", srcPath, dstPath);
	}
}
