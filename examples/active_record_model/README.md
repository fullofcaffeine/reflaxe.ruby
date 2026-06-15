# ActiveRecord Model And Query Example

This fixture demonstrates the current RailsHx typed ActiveRecord query surface.
It is intentionally small and compiler-focused: the Haxe code should look like
Rails query code, while field names, association ownership, and criteria value
types are checked by Haxe.

Run it with:

```bash
npm run test:active-record-model
```

The smoke compiles the example, checks generated Rails-shaped Ruby, and runs
negative compile tests for invalid fields, invalid value types, wrong association
owners, invalid association metadata, invalid callbacks, and invalid `find` /
`findBy` / `exists` usage, invalid projection specs, and invalid grouped-count
fields.

## Main Query Shapes

`Main.hx` proves relation composition, including `all()` as a typed model
entrypoint when you want to start from a full model relation:

```haxe
import rails.active_record.Aggregate;
import rails.active_record.Association;
import rails.active_record.Expr;
import rails.active_record.Group;
import rails.active_record.Lock;
import rails.active_record.Order;
import rails.active_record.Projection;
import rails.active_record.Sql;
import rails.active_record.TransactionIsolation;

var allOpen = Todo
	.all()
	.where({status: "open"})
	.order(Todo.f.title.asc())
	.limit(3);

var distinctOpen = Todo
	.distinct()
	.where({status: "open"})
	.order(Todo.f.title.asc());

var notDone = Todo
	.whereNot({status: "done"})
	.order(Todo.f.title.asc())
	.limit(8);

var notDoneCount = Todo.whereNot({status: "done"}).count();

var assignedNotDone = Todo
	.where({title: "assigned"})
	.whereNot({status: "done"})
	.limit(2);

var openOrDoneByField = Todo
	.whereIn(Todo.f.status, ["open", "done"])
	.order(Todo.f.title.asc())
	.limit(9);

var openOrDoneCount = Todo.whereIn(Todo.f.status, ["open", "done"]).count();

var assignedNotArchived = Todo
	.where({title: "assigned"})
	.whereNotIn(Todo.f.status, ["archived"])
	.limit(2);

var notArchivedCount = Todo.whereNotIn(Todo.f.status, ["archived"]).count();

var firstTen = Todo.whereBetween(Todo.f.id, 1, 10).order(Todo.f.id.asc());
var outsideFirstTen = Todo.whereNotBetween(Todo.f.id, 1, 10).limit(3);
var assignedOutsideFirstTen = Todo
	.where({title: "assigned"})
	.whereNotBetween(Todo.f.id, 1, 10)
	.limit(2);

var afterFirst = Todo.whereGt(Todo.f.id, 1).order(Todo.f.id.asc());
var notSmall = Todo.whereNotLte(Todo.f.id, 10).limit(3);
var assignedNotSmall = Todo
	.where({title: "assigned"})
	.whereNotLte(Todo.f.id, 10)
	.limit(2);
var lowerTitleOrder = Todo.order(Expr.lower(Todo.f.title).asc()).limit(3);
var lowerShip = Todo.whereExpr(Expr.lower(Todo.f.title).eq("ship")).limit(2);
var unsafeSqlOpen = Todo.whereSql(Sql.unsafeWhere("status <> 'archived'")).limit(2);
var unsafeSqlOrder = Todo.orderSql(Sql.unsafeOrder("LOWER(title) ASC")).limit(2);

var missingNotes = Todo.whereNull(Todo.f.notes).limit(3);
var anyWithNotes = Todo.whereNotNull(Todo.f.notes).limit(3);
var assignedWithNotes = Todo
	.where({title: "assigned"})
	.whereNotNull(Todo.f.notes)
	.limit(2);

var emptyOpen = Todo.none().where({status: "open"});
var emptyAssigned = Todo.where({title: "assigned"}).none().limit(1);
var reverseOpen = Todo.reverseOrder().where({status: "open"}).limit(2);
var reverseAssigned = Todo.where({title: "assigned"}).reverseOrder().limit(2);
var readonlyOpen = Todo.readOnly().where({status: "open"}).limit(2);
var readonlyAssigned = Todo.where({title: "assigned"}).readOnly().limit(2);
var lockedOpen = Todo.lock().where({status: "open"}).limit(1);
var explicitLock = Todo.where({title: "assigned"}).lock(Lock.forUpdate()).first();
var transactionCount:Int = Todo.transaction(function() {
	return Todo.where({status: "open"}).lock(Lock.share()).count();
}, {requiresNew: true, isolation: TransactionIsolation.serializable()});

var openOrDone = Todo
	.where({status: "open"})
	.or(Todo.where({status: "done"}))
	.order(Todo.f.title.asc());

var mergedOpen = Todo
	.where({status: "open"})
	.merge(Todo.where({completed: false}))
	.limit(7);

var staticReordered = Todo.reorder(Todo.f.title.desc()).limit(4);
var multiOrdered = Todo.order(Order.many([Todo.f.title.asc(), Todo.f.id.desc()])).limit(6);
var relationMultiReordered = Todo
	.where({title: "assigned"})
	.reorder(Order.many([Todo.f.id.desc(), Todo.f.title.asc()]));
var reassigned = Todo.where({title: "assigned"}).rewhere({status: "done"});
var staticRewhere = Todo.rewhere({completed: true}).limit(1);
var selected = Todo.select(Todo.f.title).where({status: "open"});

var titles:Array<String> = Todo.pluck(Todo.f.title);
var assignedIds:Array<Int> = Todo.where({title: "assigned"}).pluck(Todo.f.id);
var projected:Array<{id:Int, title:String}> = Projection.pluck(
	Todo.where({status: "open"}),
	{id: Todo.f.id, title: Todo.f.title}
);
var groupedProjection:Array<{status:String, todoCount:Int, userIdSum:Int, averageUserId:Float, minId:Int, maxTitle:String}> = Projection.group(
	Todo.where({status: "open"}),
	Todo.f.status,
	{
		status: Todo.f.status,
		todoCount: Aggregate.count(Todo.f.id),
		userIdSum: Aggregate.sum(Todo.f.userId),
		averageUserId: Aggregate.average(Todo.f.userId),
		minId: Aggregate.minimum(Todo.f.id),
		maxTitle: Aggregate.maximum(Todo.f.title)
	}
);
var statusCounts:haxe.ds.StringMap<Int> = Group.count(
	Todo.where({status: "open"}),
	Todo.f.status
);
var busyStatusCounts:haxe.ds.StringMap<Int> = Group.countHaving(
	Todo.where({status: "open"}),
	Todo.f.status,
	Aggregate.count(Todo.f.id).gt(1)
);
var userCounts:haxe.ds.IntMap<Int> = Group.count(Todo, Todo.f.userId);
var minId:Null<Int> = Todo.minimum(Todo.f.id);
var maxTitle:Null<String> = Todo.maximum(Todo.f.title);
var totalUserIds:Int = Todo.sum(Todo.f.userId);
var averageUserId:Null<Float> = Todo.average(Todo.f.userId);

var found = Todo
	.includes(Todo.associations.user)
	.where({title: "ship", status: "open"})
	.where({completed: false})
	.joins(Todo.associations.user)
	.order(Todo.f.title.asc())
	.limit(10);

var nestedIncludes = Todo
	.includes(Association.nested(Todo.a.user, User.a.todos))
	.where({status: "open"});

var nestedPreload = Todo.preload(Association.nested(Todo.a.user, User.a.todos)).limit(2);
var nestedEagerLoad = Todo
	.where({status: "open"})
	.eagerLoad(Association.nested(Todo.a.user, User.a.todos))
	.limit(2);

var nestedCriteria = Todo
	.joins(Todo.a.user)
	.where({user: {name: "owner"}})
	.limit(3);
var nestedFoundBy:Null<Todo> = Todo.joins(Todo.a.user).findBy({user: {name: "owner"}});
var nestedExists:Bool = Todo.joins(Todo.a.user).exists({user: {id: 1}});
```

Generated Ruby:

```ruby
Models::Todo.all().where(status: "open").order(title: :asc).limit(3)
Models::Todo.distinct().where(status: "open").order(title: :asc)
Models::Todo.where.not(status: "done").order(title: :asc).limit(8)
Models::Todo.where(title: "assigned").order(title: :asc).limit(5).where.not(status: "done").limit(2)
Models::Todo.where(status: ["open", "done"]).order(title: :asc).limit(9)
Models::Todo.where(title: "assigned").where.not(status: ["archived"]).limit(2)
Models::Todo.none().where(status: "open")
Models::Todo.where(title: "assigned").none().limit(1)
Models::Todo.reverse_order().where(status: "open").limit(2)
Models::Todo.where(title: "assigned").reverse_order().limit(2)
Models::Todo.readonly().where(status: "open").limit(2)
Models::Todo.where(title: "assigned").readonly().limit(2)
Models::Todo.lock().where(status: "open").limit(1)
Models::Todo.where(title: "assigned").lock("FOR UPDATE").first()
Models::Todo.transaction(requires_new: true, isolation: :serializable) { Models::Todo.where(status: "open").lock("FOR SHARE").count() }
Models::Todo.where(status: "open").or(Models::Todo.where(status: "done")).order(title: :asc)
Models::Todo.where(status: "open").merge(Models::Todo.where(completed: false)).limit(7)
Models::Todo.reorder(title: :desc).limit(4)
Models::Todo.order(title: :asc, id: :desc).limit(6)
Models::Todo.where(title: "assigned").reorder(id: :desc, title: :asc)
Models::Todo.where(title: "assigned").rewhere(status: "done")
Models::Todo.rewhere(completed: true).limit(1)
Models::Todo.select(:title).where(status: "open")
Models::Todo.pluck(:title)
Models::Todo.where(title: "assigned").pluck(:id)
HXRuby.active_record_projection(Models::Todo.where(status: "open").pluck(:id, :title), ["id", "title"])
HXRuby.active_record_projection(Models::Todo.where(status: "open").group(:status).pluck(:status, Models::Todo.arel_table[:id].count, Models::Todo.arel_table[:user_id].sum, Models::Todo.arel_table[:user_id].average, Models::Todo.arel_table[:id].minimum, Models::Todo.arel_table[:title].maximum), ["status", "todoCount", "userIdSum", "averageUserId", "minId", "maxTitle"])
HXRuby.active_record_group_count(Models::Todo.where(status: "open").group(:status).count(), :string)
HXRuby.active_record_group_count(Models::Todo.where(status: "open").group(:status).having(Models::Todo.arel_table[:id].count.gt(1)).count(), :string)
HXRuby.active_record_group_count(Models::Todo.group(:user_id).count(), :int)
Models::Todo.minimum(:id)
Models::Todo.maximum(:title)
Models::Todo.sum(:user_id)
Models::Todo.average(:user_id)
Models::Todo
  .includes(:user)
  .where(title: "ship", status: "open")
  .where(completed: false)
  .joins(:user)
  .order(title: :asc)
  .limit(10)
Models::Todo.includes({user: :todos}).where(status: "open")
Models::Todo.preload({user: :todos}).limit(2)
Models::Todo.where(status: "open").eager_load({user: :todos}).limit(2)
Models::Todo.joins(:user).where(user: {name: "owner"}).limit(3)
Models::Todo.joins(:user).find_by(user: {name: "owner"})
Models::Todo.joins(:user).exists?(user: {id: 1})
```

Type-safety features used here:

- `where({...})` object keys must be `@:railsColumn` fields.
- `where({...})` values must match those field types.
- `whereNot({...})` uses the same typed criteria object while lowering to
  Rails `where.not(...)`, so common negative predicates do not need raw SQL
  strings.
- `whereIn(Todo.f.status, ["open", "done"])` and `whereNotIn(...)` use typed
  field refs and `Array<TValue>` values while lowering to Rails array-valued
  hash criteria, avoiding raw `IN (...)` SQL fragments.
- `whereBetween(Todo.f.id, 1, 10)` and `whereNotBetween(...)` use typed field
  refs plus same-typed range endpoints while lowering to Rails hash range
  criteria such as `where(id: 1..10)`.
- `whereGt(Todo.f.id, 1)` / `whereLte(...)` and their negated forms use typed
  field refs plus same-typed values while lowering to Rails/Arel comparison
  predicates, avoiding raw `id > ?` SQL fragments. They share the same compiler
  lowering backend as `whereExpr(Expr.field(Todo.f.id).gt(1))`.
- `Expr.lower(Todo.f.title).asc()` and
  `whereExpr(Expr.lower(Todo.f.title).eq("ship"))` use the typed RailsHx
  expression layer for SQL functions while lowering to Rails/Arel
  `Models::Todo.arel_table[:title].lower...` calls. Raw strings such as
  `Todo.order("LOWER(title) ASC")` are intentionally rejected.
- `whereSql(Sql.unsafeWhere(...))` and `orderSql(Sql.unsafeOrder(...))` are the
  explicit raw SQL escape hatches. They remain model/kind typed and searchable,
  so plain strings, wrong model owners, and wrong SQL fragment kinds fail before
  Rails runs.
- `whereNull(Todo.f.notes)` and `whereNotNull(Todo.f.notes)` require nullable
  typed field refs and lower to Rails `nil` hash criteria, avoiding ad-hoc
  `IS NULL` / `IS NOT NULL` strings.
- `rewhere({...})` uses the same typed criteria object while lowering to Rails `rewhere`.
- `Todo.none()` and `relation.none()` keep a typed null relation that can still
  be chained before Rails runs.
- `Todo.reverseOrder()` and `relation.reverseOrder()` keep Haxe camelCase at the
  authoring layer and lower to Rails `reverse_order`.
- `Todo.readOnly()` and `relation.readOnly()` keep the read-only relation
  intent typed and lower to Rails `readonly`.
- `Todo.lock()` and `relation.lock(Lock.forUpdate())` keep pessimistic locking
  Rails-shaped while avoiding ad-hoc lock strings in normal app code.
- `Todo.transaction(function() return value, options)` preserves the block
  return type and checks transaction options such as `requiresNew` and
  `TransactionIsolation.serializable()` before lowering to Rails kwargs.
- `relation.or(otherRelation)` requires another `Relation<Todo, ...>` operand
  and lowers to Rails-native `.or(...)`.
- `relation.merge(otherRelation)` uses the same typed same-model operand rule
  and lowers to Rails-native `.merge(...)`.
- `Todo.associations.user` / `Todo.a.user` must belong to `Todo`.
- `Association.nested(Todo.a.user, User.a.todos)` validates the chain from
  `Todo` to `User` to `Todo` and lowers to Rails `{user: :todos}` for
  `includes`, `preload`, `joins`, and `eagerLoad`.
- Nested criteria such as `{user: {name: "owner"}}` validate both the `Todo`
  association key and the target `User` column keys/types before lowering to
  Rails nested hash criteria.
- `Todo.f.title.asc()` produces a typed `Order<Todo>`.
- `Order.many([Todo.f.title.asc(), Todo.f.id.desc()])` produces one typed
  multi-field `Order<Todo>` and lowers to Rails `order(title: :asc, id: :desc)`.
- `Todo.select(Todo.f.title)` returns a relation and lowers to Rails `select(:title)`.
- `Todo.reorder(Todo.f.title.desc())` uses the same owner-typed order token.
- `Todo.pluck(Todo.f.title)` returns `Array<String>` from the field value type.
- `Projection.pluck(Todo.where(...), {id: Todo.f.id, title: Todo.f.title})`
  returns named rows such as `Array<{id:Int, title:String}>`, rejects empty
  specs, and rejects fields from another model before Rails runs.
- `Projection.group(Todo.where(...), Todo.f.status, {status: Todo.f.status, todoCount: Aggregate.count(Todo.f.id)})`
  returns selected grouped aggregate rows such as
  `Array<{status:String, todoCount:Int}>`, rejects raw string aliases, rejects
  aggregate expressions from another model, and rejects non-grouped field
  selections before Rails runs.
- `Group.count(Todo.where(...), Todo.f.status)` returns `StringMap<Int>` for
  string keys, `Group.count(Todo, Todo.f.userId)` returns `IntMap<Int>` for
  integer keys, and unsupported key types fail during Haxe compilation.
- `Group.countHaving(Todo.where(...), Todo.f.status, Aggregate.count(Todo.f.id).gt(1))`
  adds a typed aggregate `having` predicate and rejects raw strings or
  predicates from another model before Rails runs.
- `Todo.maximum(Todo.f.id)` returns `Null<Int>` and rejects fields from other models.
- `Todo.sum(Todo.f.userId)` returns `Int`, `Todo.average(Todo.f.userId)`
  returns `Null<Float>`, and non-`Int` fields fail during Haxe compilation.
- The chain remains a typed relation after `all`, `distinct`, `where`, `joins`,
  `none`, `reverseOrder`, `readOnly`, `or`, `merge`, `order`, `limit`, and
  `offset`.

Invalid projection/grouping examples fail during Haxe compilation:

```haxe
Projection.pluck(Todo, {id: User.f.id});
Projection.pluck(Todo.where({status: "open"}), {id: Todo.f.id, name: User.f.name});
Projection.pluck(Todo, {});
Projection.group(Todo, Todo.f.status, {status: Todo.f.status, userCount: Aggregate.count(User.f.id)});
Projection.group(Todo, Todo.f.status, {status: Todo.f.status, todoCount: "COUNT(*)"});
Projection.group(Todo, Todo.f.status, {title: Todo.f.title, todoCount: Aggregate.count(Todo.f.id)});
Group.count(Todo, User.f.name);
Group.count(Todo, Todo.f.completed);
Group.countHaving(Todo, Todo.f.status, Aggregate.count(User.f.id).gt(1));
Group.countHaving(Todo, Todo.f.status, "COUNT(*) > 1");
```

## Scopes

`Todo.incomplete()` and `Todo.withStatus(...)` are typed Rails scopes:

```haxe
@:railsScope
public static function incomplete() {
	return Todo.where({completed: false});
}

@:railsScope
public static function withStatus(status:String) {
	return Todo.where({status: status});
}

@:railsDefaultScope
public static function orderedByTitle() {
	return Todo.order(Todo.f.title.asc());
}

var scoped = Todo.incomplete().includes(Todo.a.user).limit(5);
var statusScoped = Todo.withStatus("open").order(Todo.f.title.asc()).limit(4);
```

Generated model Ruby uses Rails-native scope macros:

```ruby
scope :incomplete, -> { where(completed: false) }
scope :with_status, ->(status__hx0) { where(status: status__hx0) }
default_scope -> { order(title: :asc) }
```

Generated Ruby:

```ruby
Models::Todo.incomplete().includes(:user).limit(5)
Models::Todo.with_status("open").order(title: :asc).limit(4)
```

Use `@:railsScope` when the method is part of the model's Rails query API and
should appear as `scope :name, -> { ... }` in `app/models`. Use an ordinary
static method when it is just a Ruby class helper. Both paths are typed in Haxe,
but `@:railsScope` gives Rails tools and Rails developers the familiar scope
shape.

`offset` is typed as `Int` and preserves the relation shape for pagination:

```haxe
var page = Todo.where({status: "open"}).offset(20).limit(10);
var fromModel = Todo.offset(5).where({completed: false});
```

Generated Ruby:

```ruby
Models::Todo.where(status: "open").offset(20).limit(10)
Models::Todo.offset(5).where(completed: false)
```

## Field And Association Aliases

RailsHx generates both descriptive and terse refs:

```haxe
Todo.fields.title      // same field ref as Todo.f.title
Todo.associations.user // same association ref as Todo.a.user
```

Use the terse aliases in app query code when it reads better:

```haxe
Todo.incomplete().includes(Todo.a.user).order(Todo.f.title.asc());
```

These refs are not model instances. They are typed tokens the compiler lowers to
Rails symbols and hash keys.

## Find And FindBy

`find` is primary-key typed and returns `Todo`:

```haxe
var loaded:Todo = Todo.find(1);
var assigned = Todo.where({title: "assigned"});
var relationLoaded:Todo = assigned.find(1);
```

Static model `find(...)` is stricter because RailsHx infers the primary-key
field type from `@:railsColumn`. Relation-level `find(...)` uses a typed
`Int`/`String` overload instead of `Dynamic`, so common scalar IDs remain
ergonomic while object-shaped accidental IDs are rejected and generated Ruby
stays a direct `find(1)` call.

`findBy` is criteria typed and returns `Null<Todo>`:

```haxe
var foundBy:Null<Todo> = Todo.findBy({externalId: "ship-1"});
var relationFoundBy:Null<Todo> = Todo.where({title: "ship"}).findBy({completed: false});
```

Generated Ruby:

```ruby
Models::Todo.find(1)
Models::Todo.where(title: "assigned").find(1)
Models::Todo.find_by(external_id: "ship-1")
Models::Todo.where(title: "ship").find_by(completed: false)
```

## Exists And Count

`exists` is criteria typed and lowers to Rails `exists?`:

```haxe
var hasAssigned = Todo.exists({externalId: "assigned-1"});
var hasOpenAssigned = assigned.exists({status: "open"});
```

Generated Ruby:

```ruby
Models::Todo.exists?(external_id: "assigned-1")
assigned.exists?(status: "open")
```

`count()` stays Rails-shaped on both models and relations:

```haxe
var openCount = Todo.where({status: "open"}).count();
var totalCount = Todo.count();
```

Generated Ruby:

```ruby
Models::Todo.where(status: "open").count()
Models::Todo.count()
```

`first()` and `last()` load one nullable typed model:

```haxe
var first:Null<Todo> = Todo.where({status: "open"}).first();
var last:Null<Todo> = Todo.last();
var relationLast:Null<Todo> = Todo.where({title: "assigned"}).last();
```

Generated Ruby:

```ruby
Models::Todo.where(status: "open").first()
Models::Todo.last()
Models::Todo.where(title: "assigned").last()
```

## Different Models

The fixture includes `AuditLog` to show snake_case lowering for non-trivial Haxe
field names:

```haxe
var logs = AuditLog.where({eventCount: 1}).order(AuditLog.f.eventCount.desc());
```

Generated Ruby:

```ruby
Models::AuditLog.where(event_count: 1).order(event_count: :desc)
```

It also includes `User` to prove owner-typed association refs:

```haxe
var users = User.includes(User.a.todos).joins(User.a.todos).where({name: "owner"});
```

Generated Ruby:

```ruby
Models::User.includes(:todos).joins(:todos).where(name: "owner")
```

## Boundary Rule

Stay lazy while composing relations. Use `toArray()` at controller/template
boundaries when you need loaded records:

```haxe
var todos = Todo.incomplete()
	.includes(Todo.a.user)
	.order(Todo.f.title.asc())
	.offset(20)
	.limit(10)
	.toArray();
```

Generated Ruby:

```ruby
Models::Todo.incomplete().includes(:user).order(title: :asc).offset(20).limit(10).to_a()
```

See `examples/todoapp_rails/controllers/TodosController.hx` for this pattern in
a Rails controller render flow.

## What Should Fail

These are intentionally rejected by Haxe:

```haxe
Todo.where({missing: "nope"});
Todo.where({completed: "nope"});
Todo.where({title: "ship"}).where({missing: "nope"});
Todo.where({status: "open"}).or(User.where({name: "owner"}));
Todo.where({status: "open"}).merge(User.where({name: "owner"}));
Todo.includes(User.a.todos);
Todo.find("nope");
Todo.where({status: "open"}).find({id: 1});
Todo.findBy({missing: "nope"});
Todo.exists({missing: "nope"});
Todo.where({status: "open"}).offset("nope");
```

The goal is not to hide Rails. The goal is to keep the Rails API shape while
moving common query mistakes from runtime to compile time.
