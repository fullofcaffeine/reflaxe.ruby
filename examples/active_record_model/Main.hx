import models.AuditLog;
import models.Todo;
import models.User;
import rails.active_record.Association;
import rails.active_record.Expr;
import rails.active_record.Group;
import rails.active_record.Lock;
import rails.active_record.Order;
import rails.active_record.Projection;
import rails.active_record.Sql;
import rails.active_record.TransactionIsolation;

// Typed ActiveRecord query smoke.
//
// Demonstrates: Rails-native query chains (`where`, `includes`, `joins`,
// `all`, `distinct`, `none`, `reverseOrder`, `readOnly`, `lock`, `transaction`, `select`, `where`, `whereNot`, `whereIn`, `whereNotIn`, `whereBetween`, `whereNotBetween`, `whereGt`, `whereLte`, `whereNull`, `whereNotNull`, `rewhere`, `or`, `merge`, `includes`, `preload`, `joins`, `eagerLoad`, `order`, `reorder`, `limit`,
// `offset`, `pluck`, `minimum`, `maximum`, `sum`, `average`, `find`, `findBy`,
// `exists`, `count`, `first`, and `last` authored as typed Haxe calls, plus
// typed multi-field orders through `Order.many`, named multi-field projections
// through `Projection.pluck`, typed grouped counts through `Group.count`, and
// aggregate `having` predicates through `Group.countHaving`.
// Type safety: criteria objects are checked against model fields, `Todo.f.*`
// exposes typed field refs for ordering, and `Todo.a.*` exposes typed
// association refs for `includes`/`joins`.
// IntelliSense: editors should complete `Todo.f.title`, `Todo.a.user`,
// relation methods, and model-owned Rails scopes such as `Todo.incomplete()`
// and `Todo.withStatus(...)`.
// Ruby output: ordinary ActiveRecord calls such as `where(...)`,
// `includes(:user)`, `order(title: :asc)`, and `limit(10)`.
class Main {
	static function main() {
		var found = Todo.includes(Todo.associations.user).where({title: "ship", status: "open"}).where({completed: false}).joins(Todo.associations.user).order(Todo.f.title.asc()).limit(10);
		var nestedIncludes = Todo.includes(Association.nested(Todo.a.user, User.a.todos)).where({status: "open"});
		var nestedPreload = Todo.preload(Association.nested(Todo.a.user, User.a.todos)).limit(2);
		var nestedEagerLoad = Todo.where({status: "open"}).eagerLoad(Association.nested(Todo.a.user, User.a.todos)).limit(2);
		var nestedCriteria = Todo.joins(Todo.a.user).where({user: {name: "owner"}}).limit(3);
		var nestedFoundBy:Null<Todo> = Todo.joins(Todo.a.user).findBy({user: {name: "owner"}});
		var nestedExists:Bool = Todo.joins(Todo.a.user).exists({user: {id: 1}});
		var scoped = Todo.incomplete().includes(Todo.a.user).limit(5);
		var statusScoped = Todo.withStatus("open").order(Todo.f.title.asc()).limit(4);
		var users = User.includes(User.a.todos).joins(User.a.todos).where({name: "owner"});
		var made:Todo = Todo.create({title: "ship", userId: 1});
		var logs = AuditLog.where({eventCount: 1}).order(AuditLog.f.eventCount.desc());
		var loaded:Todo = Todo.find(1);
		var foundBy:Null<Todo> = Todo.findBy({externalId: "ship-1"});
		var relationFoundBy:Null<Todo> = Todo.where({title: "ship"}).findBy({completed: false});
		var assigned = Todo.where({title: "assigned"}).order(Todo.f.title.asc()).limit(5);
		var allOpen = Todo.all().where({status: "open"}).order(Todo.f.title.asc()).limit(3);
		var distinctOpen = Todo.distinct().where({status: "open"}).order(Todo.f.title.asc());
		var notDone = Todo.whereNot({status: "done"}).order(Todo.f.title.asc()).limit(8);
		var assignedNotDone = assigned.whereNot({status: "done"}).limit(2);
		var openOrDoneByField = Todo.whereIn(Todo.f.status, ["open", "done"]).order(Todo.f.title.asc()).limit(9);
		var assignedNotArchived = assigned.whereNotIn(Todo.f.status, ["archived"]).limit(2);
		var firstTen = Todo.whereBetween(Todo.f.id, 1, 10).order(Todo.f.id.asc());
		var assignedOutsideFirstTen = assigned.whereNotBetween(Todo.f.id, 1, 10).limit(2);
		var afterFirst = Todo.whereGt(Todo.f.id, 1).order(Todo.f.id.asc());
		var assignedNotSmall = assigned.whereNotLte(Todo.f.id, 10).limit(2);
		var lowerTitleOrder = Todo.order(Expr.lower(Todo.f.title).asc()).limit(3);
		var lowerTitleOrderViaOrder = Todo.order(Order.lower(Todo.f.title).asc()).limit(3);
		var lowerShip = Todo.whereExpr(Expr.lower(Todo.f.title).eq("ship")).limit(2);
		var relationLowerNotShip = assigned.whereNotExpr(Expr.lower(Todo.f.title).eq("ship")).limit(2);
		var exprAfterFirst = Todo.whereExpr(Expr.field(Todo.f.id).gt(1)).limit(2);
		var fluentLowerTitleOrder = Todo.order(Todo.f.title.lower().asc()).limit(3);
		var fluentLowerShip = Todo.where(Todo.f.title.lower().eq("ship")).limit(2);
		var relationFluentLowerNotShip = assigned.whereNot(Todo.f.title.lower().eq("ship")).limit(2);
		var fluentAfterFirst = Todo.where(Todo.f.id.gt(1)).limit(2);
		var unsafeSqlOpen = Todo.whereSql(Sql.unsafeWhere("status <> 'archived'")).limit(2);
		var unsafeSqlNotDone = assigned.whereNotSql(Sql.unsafeWhere("status = 'done'")).limit(2);
		var unsafeSqlOrder = Todo.orderSql(Sql.unsafeOrder("LOWER(title) ASC")).limit(2);
		var missingNotes = Todo.whereNull(Todo.f.notes).limit(3);
		var assignedWithNotes = assigned.whereNotNull(Todo.f.notes).limit(2);
		var relationDistinct = assigned.distinct().limit(2);
		var emptyOpen = Todo.none().where({status: "open"});
		var emptyAssigned = assigned.none().limit(1);
		var reverseOpen = Todo.reverseOrder().where({status: "open"}).limit(2);
		var reverseAssigned = assigned.reverseOrder().limit(2);
		var readonlyOpen = Todo.readOnly().where({status: "open"}).limit(2);
		var readonlyAssigned = assigned.readOnly().limit(2);
		var lockedOpen = Todo.lock().where({status: "open"}).limit(1);
		var explicitLock = assigned.lock(Lock.forUpdate()).first();
		var noWaitLock = Todo.where({status: "open"}).lock(Lock.noWait()).first();
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
		var relationLoaded:Todo = assigned.find(1);
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
		var groupedProjection:Array<{status:String, todoCount:Int, userIdSum:Int, averageUserId:Float, minId:Int, maxTitle:String}> = Projection.group(
			Todo.where({status: "open"}),
			Todo.f.status,
			{
				status: Todo.f.status,
				todoCount: Todo.f.id.count(),
				userIdSum: Todo.f.userId.sum(),
				averageUserId: Todo.f.userId.average(),
				minId: Todo.f.id.minimum(),
				maxTitle: Todo.f.title.maximum()
			}
		);
		var statusCounts:haxe.ds.StringMap<Int> = Group.count(Todo.where({status: "open"}), Todo.f.status);
		var busyStatusCounts:haxe.ds.StringMap<Int> = Group.countHaving(
			Todo.where({status: "open"}),
			Todo.f.status,
			Todo.f.id.count().gt(1)
		);
		var userCounts:haxe.ds.IntMap<Int> = Group.count(Todo, Todo.f.userId);
		var eventCounts:haxe.ds.IntMap<Int> = Group.count(AuditLog.where({eventCount: 1}), AuditLog.f.eventCount);
		var minId:Null<Int> = Todo.minimum(Todo.f.id);
		var maxTitle:Null<String> = Todo.maximum(Todo.f.title);
		var assignedMaxId:Null<Int> = assigned.maximum(Todo.f.id);
		var totalUserIds:Int = Todo.sum(Todo.f.userId);
		var averageUserId:Null<Float> = Todo.average(Todo.f.userId);
		var assignedUserSum:Int = assigned.sum(Todo.f.userId);
		var assignedAverageUserId:Null<Float> = assigned.average(Todo.f.userId);
		var transactionCreated:Todo = Todo.transaction(function() {
			return Todo.create({title: "inside transaction", userId: 1});
		});
		var transactionCount:Int = Todo.transaction(function() {
			return Todo.where({status: "open"}).lock(Lock.share()).count();
		}, {requiresNew: true, isolation: TransactionIsolation.serializable()});
		Sys.println(found == null);
		Sys.println(nestedIncludes == null);
		Sys.println(nestedPreload == null);
		Sys.println(nestedEagerLoad == null);
		Sys.println(nestedCriteria == null);
		Sys.println(nestedFoundBy == null);
		Sys.println(nestedExists);
		Sys.println(scoped == null);
		Sys.println(statusScoped == null);
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
		Sys.println(groupedProjection.length >= 0);
		Sys.println(statusCounts.get("open") == null);
		Sys.println(busyStatusCounts.get("open") == null);
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
		Sys.println(notDone == null);
		Sys.println(assignedNotDone == null);
		Sys.println(openOrDoneByField == null);
		Sys.println(assignedNotArchived == null);
		Sys.println(firstTen == null);
		Sys.println(assignedOutsideFirstTen == null);
		Sys.println(afterFirst == null);
		Sys.println(assignedNotSmall == null);
		Sys.println(lowerTitleOrder == null);
		Sys.println(lowerTitleOrderViaOrder == null);
		Sys.println(lowerShip == null);
		Sys.println(relationLowerNotShip == null);
		Sys.println(exprAfterFirst == null);
		Sys.println(fluentLowerTitleOrder == null);
		Sys.println(fluentLowerShip == null);
		Sys.println(relationFluentLowerNotShip == null);
		Sys.println(fluentAfterFirst == null);
		Sys.println(unsafeSqlOpen == null);
		Sys.println(unsafeSqlNotDone == null);
		Sys.println(unsafeSqlOrder == null);
		Sys.println(missingNotes == null);
		Sys.println(assignedWithNotes == null);
		Sys.println(relationDistinct == null);
		Sys.println(emptyOpen == null);
		Sys.println(emptyAssigned == null);
		Sys.println(reverseOpen == null);
		Sys.println(reverseAssigned == null);
		Sys.println(readonlyOpen == null);
		Sys.println(readonlyAssigned == null);
		Sys.println(lockedOpen == null);
		Sys.println(explicitLock == null);
		Sys.println(noWaitLock == null);
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
		Sys.println(transactionCreated == null);
		Sys.println(transactionCount >= 0);
	}
}
