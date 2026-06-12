import models.AuditLog;
import models.Todo;
import models.User;

class Main {
	static function main() {
		var found = Todo.includes(Todo.associations.user).where({title: "ship"}).where({completed: false}).joins(Todo.associations.user).order(Todo.f.title.asc()).limit(10);
		var scoped = Todo.incomplete().includes(Todo.a.user).limit(5);
		var users = User.includes(User.a.todos).joins(User.a.todos).where({name: "owner"});
		var made:Todo = Todo.create({title: "ship", userId: 1});
		var logs = AuditLog.where({eventCount: 1}).order(AuditLog.f.eventCount.desc());
		var loaded:Todo = Todo.find(1);
		var foundBy:Null<Todo> = Todo.findBy({externalId: "ship-1"});
		var relationFoundBy:Null<Todo> = Todo.where({title: "ship"}).findBy({completed: false});
		var assigned = Todo.where({title: "assigned"}).order(Todo.f.title.asc()).limit(5);
		var assignedFoundBy:Null<Todo> = assigned.findBy({externalId: "assigned-1"});
		var first:Null<Todo> = found.first();
		Sys.println(found == null);
		Sys.println(scoped == null);
		Sys.println(users == null);
		Sys.println(made == null);
		Sys.println(logs == null);
		Sys.println(loaded == null);
		Sys.println(foundBy == null);
		Sys.println(relationFoundBy == null);
		Sys.println(assignedFoundBy == null);
		Sys.println(first == null);
	}
}
