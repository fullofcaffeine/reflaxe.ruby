import controllers.TodosController;

// ActionController smoke entrypoint.
//
// Demonstrates: Rails controller classes generated under Rails mode and visible
// as typed Haxe classes.
// Type safety: `TodosController` is resolved by Haxe before Ruby/Rails output is
// generated; package/class drift fails early.
// IntelliSense: editors should complete controller types and methods from the
// Haxe source.
// Ruby output: a Rails controller class under the Rails output root.
class Main {
	static function main() {
		var controller:TodosController = null;
		Sys.println(controller == null);
	}
}
