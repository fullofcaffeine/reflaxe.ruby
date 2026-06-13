import models.AuditLog;
import models.Todo;
import models.User;
import rails.active_record.Group;
import rails.active_record.Order;
import rails.active_record.Projection;

// Typed ActiveRecord query smoke.
//
// Demonstrates: Rails-native query chains (`where`, `includes`, `joins`,
// `all`, `distinct`, `select`, `where`, `rewhere`, `or`, `merge`, `order`, `reorder`, `limit`,
// `offset`, `pluck`, `minimum`, `maximum`, `sum`, `average`, `find`, `findBy`,
// `exists`, `count`, `first`, and `last` authored as typed Haxe calls, plus
// typed multi-field orders through `Order.many`, named multi-field projections
// through `Projection.pluck`, and typed grouped counts through `Group.count`.
// Type safety: criteria objects are checked against model fields, `Todo.f.*`
// exposes typed field refs for ordering, and `Todo.a.*` exposes typed
// association refs for `includes`/`joins`.
// IntelliSense: editors should complete `Todo.f.title`, `Todo.a.user`,
// relation methods, and model-owned scopes such as `Todo.incomplete()`.
// Ruby output: ordinary ActiveRecord calls such as `where(...)`,
// `includes(:user)`, `order(title: :asc)`, and `limit(10)`.
class Main {
	static function main() {
		var found = Todo.includes(Todo.associations.user).where({title: "ship", status: "open"}).where({completed: false}).joins(Todo.associations.user).order(Todo.f.title.asc()).limit(10);
		var scoped = Todo.incomplete().includes(Todo.a.user).limit(5);
		var users = User.includes(User.a.todos).joins(User.a.todos).where({name: "owner"});
		var made:Todo = Todo.create({title: "ship", userId: 1});
		var logs = AuditLog.where({eventCount: 1}).order(AuditLog.f.eventCount.desc());
		var loaded:Todo = Todo.find(1);
		var foundBy:Null<Todo> = Todo.findBy({externalId: "ship-1"});
		var relationFoundBy:Null<Todo> = Todo.where({title: "ship"}).findBy({completed: false});
		var assigned = Todo.where({title: "assigned"}).order(Todo.f.title.asc()).limit(5);
		var allOpen = Todo.all().where({status: "open"}).order(Todo.f.title.asc()).limit(3);
		var distinctOpen = Todo.distinct().where({status: "open"}).order(Todo.f.title.asc());
		var relationDistinct = assigned.distinct().limit(2);
		var openOrDone = Todo.where({status: "open"}).or(Todo.where({status: "done"})).order(Todo.f.title.asc());
		var mergedOpen = Todo.where({status: "open"}).merge(Todo.where({completed: false})).limit(7);
		var selected = Todo.select(Todo.f.title).where({status: "open"});
		var relationSelected = assigned.select(Todo.f.id).limit(2);
		var reordered = assigned.reorder(Todo.f.id.desc());
		var staticReordered = Todo.reorder(Todo.f.title.desc()).limit(4);
		var multiOrdered = Todo.order(Order.many([Todo.f.title.asc(), Todo.f.id.desc()])).limit(6);
		var relationMultiReordered = assigned.reorder(Order.many([Todo.f.id.desc(), Todo.f.title.asc()]));
		var reassigned = assigned.rewhere({status: "done"});
		var staticRewhere = Todo.rewhere({completed: true}).limit(1);
		var offsetRelation = Todo.where({status: "open"}).offset(20).limit(10);
		var offsetFromModel = Todo.offset(5).where({completed: false});
		var hasAssigned:Bool = Todo.exists({externalId: "assigned-1"});
		var hasOpenAssigned:Bool = assigned.exists({status: "open"});
		var openCount:Int = Todo.where({status: "open"}).count();
		var totalCount:Int = Todo.count();
		var assignedFoundBy:Null<Todo> = assigned.findBy({externalId: "assigned-1"});
		var first:Null<Todo> = found.first();
		var last:Null<Todo> = Todo.last();
		var relationLast:Null<Todo> = assigned.last();
		var titles:Array<String> = Todo.pluck(Todo.f.title);
		var assignedIds:Array<Int> = assigned.pluck(Todo.f.id);
		var projected:Array<{id:Int, title:String}> = Projection.pluck(
			Todo.where({status: "open"}),
			{id: Todo.f.id, title: Todo.f.title}
		);
		var projectedFromModel:Array<{id:Int, externalId:String}> = Projection.pluck(
			Todo,
			{id: Todo.f.id, externalId: Todo.f.externalId}
		);
		var statusCounts:haxe.ds.StringMap<Int> = Group.count(Todo.where({status: "open"}), Todo.f.status);
		var userCounts:haxe.ds.IntMap<Int> = Group.count(Todo, Todo.f.userId);
		var eventCounts:haxe.ds.IntMap<Int> = Group.count(AuditLog.where({eventCount: 1}), AuditLog.f.eventCount);
		var minId:Null<Int> = Todo.minimum(Todo.f.id);
		var maxTitle:Null<String> = Todo.maximum(Todo.f.title);
		var assignedMaxId:Null<Int> = assigned.maximum(Todo.f.id);
		var totalUserIds:Int = Todo.sum(Todo.f.userId);
		var averageUserId:Null<Float> = Todo.average(Todo.f.userId);
		var assignedUserSum:Int = assigned.sum(Todo.f.userId);
		var assignedAverageUserId:Null<Float> = assigned.average(Todo.f.userId);
		Sys.println(found == null);
		Sys.println(scoped == null);
		Sys.println(users == null);
		Sys.println(made == null);
		Sys.println(logs == null);
		Sys.println(loaded == null);
		Sys.println(foundBy == null);
		Sys.println(relationFoundBy == null);
		Sys.println(hasAssigned);
		Sys.println(hasOpenAssigned);
		Sys.println(openCount >= 0);
		Sys.println(totalCount >= 0);
		Sys.println(assignedFoundBy == null);
		Sys.println(first == null);
		Sys.println(last == null);
		Sys.println(relationLast == null);
		Sys.println(titles.length >= 0);
		Sys.println(assignedIds.length >= 0);
		Sys.println(projected.length >= 0);
		Sys.println(projectedFromModel.length >= 0);
		Sys.println(statusCounts.get("open") == null);
		Sys.println(userCounts.get(1) == null);
		Sys.println(eventCounts.get(1) == null);
		Sys.println(minId == null);
		Sys.println(maxTitle == null);
		Sys.println(assignedMaxId == null);
		Sys.println(totalUserIds >= 0);
		Sys.println(averageUserId == null);
		Sys.println(assignedUserSum >= 0);
		Sys.println(assignedAverageUserId == null);
		Sys.println(allOpen == null);
		Sys.println(distinctOpen == null);
		Sys.println(relationDistinct == null);
		Sys.println(openOrDone == null);
		Sys.println(mergedOpen == null);
		Sys.println(selected == null);
		Sys.println(relationSelected == null);
		Sys.println(reordered == null);
		Sys.println(staticReordered == null);
		Sys.println(multiOrdered == null);
		Sys.println(relationMultiReordered == null);
		Sys.println(reassigned == null);
		Sys.println(staticRewhere == null);
		Sys.println(offsetRelation == null);
		Sys.println(offsetFromModel == null);
	}
}
