/**
	Executable contract for the typed `ruby.FileUtils` facade.

	Every mutation stays below a generated test-only directory. The snapshot and
	smoke gates prove that typed Haxe calls become ordinary `FileUtils.*` Ruby
	without a facade wrapper, while the fixture exercises the security-first
	recursive removal contract.
**/
class Main {
	static function main():Void {
		var root = "test/.generated/fileutils_facade/runtime";
		var workspace = root + "/workspace";
		var nested = workspace + "/nested";
		var source = "test/fileutils_facade/fixtures/source.txt";
		var sourceTree = "test/fileutils_facade/fixtures/tree";

		ruby.FileUtils.secureRemoveTree(root, true);

		var made = ruby.FileUtils.makeDirectories(nested);
		Sys.println(made.length == 1);
		Sys.println(made[0] == nested);

		var empty = workspace + "/empty";
		Sys.println(ruby.FileUtils.makeDirectory(empty)[0] == empty);

		var copied = workspace + "/copied.txt";
		ruby.FileUtils.copyFile(source, copied);
		Sys.println(ruby.FileUtils.sameContents(source, copied));
		Sys.println(ruby.File.read(copied) == "typed fileutils facade\n");

		var moved = workspace + "/moved.txt";
		ruby.FileUtils.move(copied, moved);
		Sys.println(ruby.FileUtils.sameContents(source, moved));

		var copiedTree = workspace + "/tree-copy";
		ruby.FileUtils.copyTree(sourceTree, copiedTree);
		Sys.println(ruby.File.read(copiedTree + "/nested.txt") == "typed recursive copy\n");

		var touched = workspace + "/touched.txt";
		Sys.println(ruby.FileUtils.touch(touched)[0] == touched);
		Sys.println(ruby.FileUtils.isUpToDate(moved, []));
		Sys.println(ruby.FileUtils.removeFile(touched)[0] == touched);
		Sys.println(ruby.FileUtils.forceRemoveFile(workspace + "/missing.txt")[0] == workspace + "/missing.txt");
		Sys.println(ruby.FileUtils.removeDirectory(empty)[0] == empty);

		ruby.FileUtils.secureRemoveTree(copiedTree);
		Sys.println(!ruby.Dir.exists(copiedTree));
		ruby.FileUtils.secureRemoveTree(root);
		Sys.println(!ruby.Dir.exists(root));
	}
}
