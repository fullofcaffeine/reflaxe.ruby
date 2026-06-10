import models.Todo;

class Main {
	static function main() {
		var found:Array<Todo> = Todo.where({title: "ship"});
		var made:Todo = Todo.create({title: "ship"});
		Sys.println(found == null);
		Sys.println(made == null);
	}
}
