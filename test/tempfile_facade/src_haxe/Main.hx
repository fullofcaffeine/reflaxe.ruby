/**
	Executable lifecycle contract for typed `ruby.Tempfile` and `ruby.File` IO.

	The scoped calls prove Haxe callbacks lower to Ruby blocks with automatic
	cleanup. The explicit value stays inside a generated test directory and uses
	`closeAndUnlink()` so the fixture never relies on GC finalization.
**/
class Main {
	static function main():Void {
		var scopedPath = ruby.Tempfile.create("hxruby-scoped-", function(file) {
			Sys.println(ruby.File.exists(file.path()));
			Sys.println(file.write("scoped tempfile"));
			file.flush();
			Sys.println(file.size());
			Sys.println(file.rewind());
			Sys.println(file.readAll());
			return file.path();
		});
		Sys.println(!ruby.File.exists(scopedPath));

		var defaultSize = ruby.Tempfile.createDefault(function(file) {
			file.write("default");
			return file.size();
		});
		Sys.println(defaultSize);

		var namedCallback:ruby.File->Int = function(file) {
			file.write("named");
			return file.size();
		};
		Sys.println(ruby.Tempfile.create("hxruby-named-", namedCallback));

		var runtimeDirectory = "test/.generated/tempfile_facade/runtime";
		var createdInPath = ruby.Tempfile.createIn("hxruby-in-", runtimeDirectory, function(file) {
			return file.path();
		});
		Sys.println(!ruby.File.exists(createdInPath));

		var explicit = new ruby.Tempfile("hxruby-explicit-", runtimeDirectory);
		var explicitPath = explicit.path();
		if (explicitPath == null) {
			throw "new Tempfile must expose its path before unlink";
		}
		Sys.println(ruby.File.exists(explicitPath));
		Sys.println(explicit.write("explicit tempfile"));
		explicit.flush();
		Sys.println(explicit.size());
		Sys.println(explicit.rewind());
		Sys.println(explicit.readAll());
		Sys.println(explicit.isClosed());
		explicit.closeAndUnlink();
		Sys.println(explicit.isClosed());
		Sys.println(explicit.path() == null);
		Sys.println(!ruby.File.exists(explicitPath));
	}
}
