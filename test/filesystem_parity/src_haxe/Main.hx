import haxe.io.Bytes;
import haxe.io.Eof;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileSeek;

/**
	Broader-suite filesystem parity runner for Ruby.

	Directory/path cases are adapted from upstream `tests/sys/src/TestFileSystem.hx`;
	copy cases from `tests/sys/src/io/TestFile.hx`; streaming and EOF cases from
	`tests/sys/src/io/TestFileInput.hx`; missing-delete catches from Issue5742.
**/
class Main {
	static final root = "test/.generated/filesystem_parity_probe";

	static function main():Void {
		removeTree(root);
		var nested = root + "/one/two";
		FileSystem.createDirectory(nested);
		FileSystem.createDirectory(nested);
		FilesystemParityAssert.isTrue(FileSystem.exists(nested), "nested directory exists");
		FilesystemParityAssert.isTrue(FileSystem.isDirectory(nested), "nested path is directory");
		FilesystemParityAssert.isTrue(FileSystem.exists("/"), "root exists");
		FilesystemParityAssert.isTrue(FileSystem.stat("/") != null, "root stat");

		var names = FileSystem.readDirectory(root);
		FilesystemParityAssert.equal(1, names.length, "root entry count");
		FilesystemParityAssert.isTrue(names.indexOf("one") >= 0, "root entry name");

		var textPath = nested + "/note.txt";
		File.saveContent(textPath, "first\nsecond\n");
		FilesystemParityAssert.equal("first\nsecond\n", File.getContent(textPath), "text newline round trip");
		var textStat = FileSystem.stat(textPath);
		FilesystemParityAssert.equal(13, textStat.size, "file stat size");
		FilesystemParityAssert.isTrue(textStat.mtime.getTime() > 0, "file stat mtime");

		var sourceAbsolute = FileSystem.absolutePath("./filesystem-source.txt");
		FilesystemParityAssert.isTrue(sourceAbsolute.indexOf("/./filesystem-source.txt") >= 0, "absolutePath preserves dot segment");
		FilesystemParityAssert.equal("/filesystem-source.txt", FileSystem.absolutePath("/filesystem-source.txt"), "absolute path unchanged");
		FilesystemParityAssert.isTrue(FileSystem.fullPath(textPath).indexOf("filesystem_parity_probe/one/two/note.txt") >= 0,
			"fullPath resolves existing path");

		var copyPath = nested + "/copy.txt";
		File.saveContent(copyPath, "old");
		File.copy(textPath, copyPath);
		FilesystemParityAssert.equal("first\nsecond\n", File.getContent(copyPath), "copy overwrites destination");
		var renamedPath = nested + "/renamed.txt";
		FileSystem.rename(copyPath, renamedPath);
		FilesystemParityAssert.isTrue(FileSystem.exists(renamedPath), "rename destination exists");
		FilesystemParityAssert.isFalse(FileSystem.exists(copyPath), "rename source removed");

		var binary = Bytes.alloc(4);
		for (index => value in [0, 127, 128, 255]) {
			binary.set(index, value);
		}
		var binaryPath = nested + "/bytes.bin";
		File.saveBytes(binaryPath, binary);
		assertBytes(binary, File.getBytes(binaryPath), "binary save/get");

		var input = File.read(binaryPath);
		FilesystemParityAssert.equal(0, input.tell(), "input initial position");
		FilesystemParityAssert.equal(0, input.readByte(), "input first byte");
		FilesystemParityAssert.equal(1, input.tell(), "input position after byte");
		input.seek(2, FileSeek.SeekBegin);
		FilesystemParityAssert.equal(128, input.readByte(), "input seek begin");
		input.seek(-1, FileSeek.SeekEnd);
		FilesystemParityAssert.equal(255, input.readByte(), "input seek end");
		FilesystemParityAssert.isFalse(input.eof(), "EOF is false before failed read");
		FilesystemParityAssert.raises(function() input.readByte(), "read past EOF raises");
		FilesystemParityAssert.isTrue(input.eof(), "EOF latches after failed read");
		input.seek(0, FileSeek.SeekBegin);
		FilesystemParityAssert.isFalse(input.eof(), "seek resets EOF");
		var readBuffer = Bytes.alloc(4);
		FilesystemParityAssert.equal(4, input.readBytes(readBuffer, 0, 4), "input readBytes length");
		assertBytes(binary, readBuffer, "input readBytes contents");
		input.close();

		var outputPath = nested + "/stream.bin";
		var output = File.write(outputPath);
		output.write(binary);
		FilesystemParityAssert.equal(4, output.tell(), "output position");
		output.close();
		assertBytes(binary, File.getBytes(outputPath), "stream output bytes");

		FilesystemParityAssert.raises(function() File.copy(root + "/missing", root + "/missing-copy"), "copy missing source raises");
		FilesystemParityAssert.raises(function() File.getContent(root + "/missing"), "getContent missing file raises");
		FilesystemParityAssert.raises(function() FileSystem.stat(root + "/missing"), "stat missing path raises");
		FilesystemParityAssert.raises(function() FileSystem.isDirectory(root + "/missing"), "isDirectory missing path raises");
		FilesystemParityAssert.raises(function() FileSystem.readDirectory(textPath), "readDirectory file path raises");
		FilesystemParityAssert.raises(function() FileSystem.deleteFile(root + "/missing"), "delete missing file raises");
		FilesystemParityAssert.raises(function() FileSystem.deleteDirectory(root + "/missing"), "delete missing directory raises");

		removeTree(root);
		Sys.println("filesystem-parity ok");
	}

	static function assertBytes(expected:Bytes, actual:Bytes, label:String):Void {
		FilesystemParityAssert.equal(expected.length, actual.length, label + " length");
		for (index in 0...expected.length) {
			FilesystemParityAssert.equal(expected.get(index), actual.get(index), label + " byte " + index);
		}
	}

	static function removeTree(path:String):Void {
		if (!FileSystem.exists(path)) {
			return;
		}
		if (!FileSystem.isDirectory(path)) {
			FileSystem.deleteFile(path);
			return;
		}
		for (entry in FileSystem.readDirectory(path)) {
			removeTree(haxe.io.Path.join([path, entry]));
		}
		FileSystem.deleteDirectory(path);
	}
}

/** Small assertion surface owned by the standalone broader-suite fixture. */
private class FilesystemParityAssert {
	public static function equal<T>(expected:T, actual:T, label:String):Void {
		if (actual != expected) {
			throw 'filesystem parity failed: ${label}; expected ${expected}, got ${actual}';
		}
	}

	public static function isTrue(condition:Bool, label:String):Void {
		if (!condition) {
			throw 'filesystem parity failed: ${label}';
		}
	}

	public static function isFalse(condition:Bool, label:String):Void {
		isTrue(!condition, label);
	}

	public static function raises(action:Void->Void, label:String):Void {
		var raised = false;
		try {
			action();
		} catch (_:Dynamic) {
			raised = true;
		}
		isTrue(raised, label);
	}
}
