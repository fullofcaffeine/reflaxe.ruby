import models.AuditLog;
import models.Todo;

class Main {
	static function main() {
		var found:Array<Todo> = Todo.where({title: "ship"});
		var made:Todo = Todo.create({title: "ship"});
		var logs:Array<AuditLog> = AuditLog.where({eventCount: 1});
		Sys.println(found == null);
		Sys.println(made == null);
		Sys.println(logs == null);
	}
}
