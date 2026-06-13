// Rails autoload smoke entrypoint.
//
// Demonstrates: Rails mode output under `app/haxe_gen` and Zeitwerk-friendly
// constants/packages.
// Type safety: `admin.TodoItem` is resolved as a Haxe package/class, so package
// or class renames fail before Rails boots.
// IntelliSense: editors should complete `admin.TodoItem` from the Haxe package.
// Ruby output: `Admin::TodoItem` in the generated Rails autoload tree.
class Main {
	static function main() {
		var todo:admin.TodoItem = null;
		Sys.println(todo == null);
	}
}
