import models.AuditLog;
import models.Todo;

class Main {
	static function main() {
		var found:rails.active_record.Relation<Todo> = Todo.where({title: "ship"}).where({completed: false}).order(Todo.f.title.asc()).limit(10);
		var made:Todo = Todo.create({title: "ship"});
		var logs:rails.active_record.Relation<AuditLog> = AuditLog.where({eventCount: 1}).order(AuditLog.f.eventCount.desc());
		var loaded:Todo = Todo.find(1);
		var foundBy:Null<Todo> = Todo.findBy({externalId: "ship-1"});
		var relationFoundBy:Null<Todo> = Todo.where({title: "ship"}).findBy({completed: false});
		var first:Null<Todo> = found.first();
		Sys.println(found == null);
		Sys.println(made == null);
		Sys.println(logs == null);
		Sys.println(loaded == null);
		Sys.println(foundBy == null);
		Sys.println(relationFoundBy == null);
		Sys.println(first == null);
	}
}
