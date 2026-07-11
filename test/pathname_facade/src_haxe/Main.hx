/**
	Executable contract for the typed `ruby.Pathname` facade.

	The calls exercise Haxe completion/type checking while the smoke gate verifies
	they emit direct `Pathname.new` and receiver dispatch in generated Ruby.
**/
class Main {
	static function main():Void {
		var relative = new ruby.Pathname("tmp/../typed");
		var clean = relative.clean();
		var joined = clean.join("file.txt");

		Sys.println(clean.toPath());
		Sys.println(joined.toPath());
		Sys.println(joined.baseName().toPath());
		Sys.println(joined.baseName(".txt").toPath());
		Sys.println(joined.extension());
		Sys.println(joined.directoryName().toPath());
		Sys.println(joined.parent().toPath());
		Sys.println(new ruby.Pathname("typed").expand("/tmp").toPath());
		Sys.println(new ruby.Pathname(".").real().isAbsolute());

		var base = new ruby.Pathname("/srv/app");
		var destination = base.joinPath(new ruby.Pathname("lib")).join("entry.rb");
		Sys.println(destination.relativeTo(base).toPath());
		Sys.println(clean.isRelative());

		var root = new ruby.Pathname("/");
		Sys.println(root.isAbsolute());
		Sys.println(root.isRoot());

		var packageFile = new ruby.Pathname("package.json");
		Sys.println(packageFile.exists());
		Sys.println(packageFile.isFile());
		Sys.println(packageFile.isReadable());
		Sys.println(packageFile.isWritable());
		Sys.println(packageFile.isExecutable());
		Sys.println(packageFile.isSymlink());
		Sys.println(packageFile.isEmpty());
		Sys.println(new ruby.Pathname("std").isDirectory());
		Sys.println(new ruby.Pathname("std/ruby").children(false).length > 0);
		Sys.println(packageFile.read(1));
	}
}
