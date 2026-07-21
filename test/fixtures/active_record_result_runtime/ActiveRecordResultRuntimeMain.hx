import models.Todo;
import rails.active_record.Group;
import rails.active_record.Projection;

/**
	Executes the structural ActiveRecord result adapters against populated data.

	The local source closure makes relation evaluation observable. Each projection
	or grouped-count operation must invoke it exactly once while preserving scalar
	and multi-column pluck rows plus string-keyed and integer-keyed counts.
**/
class ActiveRecordResultRuntimeMain {
	static function main() {
		var sourceEvaluations = 0;
		var openTodos = function() {
			sourceEvaluations++;
			return Todo.where({status: "open"});
		};

		var scalarRows:Array<{id:Int}> = Projection.pluck(openTodos(), {id: Todo.f.id});
		var namedRows:Array<{id:Int, title:String}> = Projection.pluck(openTodos(), {id: Todo.f.id, title: Todo.f.title});
		var statusCounts:haxe.ds.StringMap<Int> = Group.count(openTodos(), Todo.f.status);
		var userCounts:haxe.ds.IntMap<Int> = Group.count(openTodos(), Todo.f.userId);
		var statusCopy = statusCounts.copy();
		statusCopy.set("done", 1);
		var copiedKeys = [for (key in statusCopy.keys()) key];
		var copiedValues = 0;
		for (value in statusCopy.iterator())
			copiedValues += value;
		var copiedEntries = 0;
		for (entry in statusCopy.keyValueIterator())
			copiedEntries += entry.value;
		var removedDone = statusCopy.remove("done");
		var copiedString = statusCopy.toString();
		statusCopy.clear();

		Sys.println(scalarRows.length == 2 && scalarRows[0].id == 1 && scalarRows[1].id == 2);
		Sys.println(namedRows.length == 2 && namedRows[0].id == 1 && namedRows[0].title == "alpha" && namedRows[1].id == 2 && namedRows[1].title == "beta");
		Sys.println(statusCounts.get("open") == 2);
		Sys.println(userCounts.get(1) == 1 && userCounts.get(2) == 1);
		Sys.println(statusCounts.exists("open") && copiedKeys.indexOf("open") != -1 && copiedKeys.indexOf("done") != -1 && copiedValues == 3
			&& copiedEntries == 3 && removedDone && copiedString.indexOf("open") != -1 && !statusCopy.exists("open"));
		Sys.println(sourceEvaluations == 4);
	}
}
