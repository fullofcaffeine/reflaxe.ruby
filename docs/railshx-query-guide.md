# RailsHx Typed ActiveRecord Query Guide

RailsHx query code should feel like Rails ActiveRecord with Haxe checking the
parts Rails normally discovers at runtime: model fields, association ownership,
field value types, primary-key types, and relation return shapes.

The rule of thumb is simple:

- Keep query chains Rails-shaped: `all`, `distinct`, `select`, `where`, `rewhere`, `includes`,
  `preload`, `joins`, `eagerLoad`, `order`, `reorder`, `limit`, `offset`, `lock`, `pluck`, `minimum`,
  `maximum`, `sum`, `average`, `find`, `findBy`, `exists`, `count`, `first`,
  `last`, and `toArray`.
- Use macro facades for query results whose Haxe return type depends on more
  than one field: `Projection.pluck(...)` for named multi-field rows and
  `Group.count(...)` for typed grouped counts.
- Put type information at the Haxe boundary: `@:railsColumn`, associations, field
  refs such as `Todo.f.title`, and association refs such as `Todo.a.user`.
- Let the compiler lower Haxe names to Rails names: `externalId` becomes
  `external_id`, `isCompleted` becomes `is_completed`, and `Todo.a.user` becomes
  `:user`.
- Cross from lazy relation to loaded data intentionally with `toArray()` when a
  controller/template needs an `Array<Todo>`.

For the rationale behind the implemented multi-field projection and grouped-count
APIs, see [RailsHx Multi-Field Projection And Grouping Design](railshx-projections-grouping-design.md).

## Model Setup

Typed queries start with typed ActiveRecord models:

```haxe
@:railsModel("todos")
class Todo extends rails.active_record.Base<Todo> {
	@:railsColumn({index: true})
	public var title:String;

	@:railsColumn({defaultValue: false})
	public var completed:Bool;

	@:railsColumn({unique: true})
	public var externalId:String;

	@:railsColumn({index: true})
	public var userId:Int;

	@:belongsTo({optional: false, foreignKey: "userId", inverseOf: "todos"})
	public var user:rails.ActiveRecord.BelongsTo<User>;

	public static function incomplete() {
		return Todo.where({completed: false});
	}
}
```

The compiler uses this metadata to generate typed query stubs and Rails-native
Ruby model output. App code does not define a parallel query runtime.

## Criteria Objects

`where({...})` and `findBy({...})` use Haxe object literals checked against
`@:railsColumn` metadata.

```haxe
var relation = Todo.where({
	title: "ship",
	completed: false,
	externalId: "ship-1"
});
```

Generated Ruby stays ordinary ActiveRecord:

```ruby
Models::Todo.where(title: "ship", completed: false, external_id: "ship-1")
```

Invalid fields fail during Haxe compilation:

```haxe
Todo.where({missing: "nope"});
```

Invalid value types fail too:

```haxe
Todo.where({completed: "nope"});
```

## Relation Chaining

Model query methods return `Relation<TModel, TCriteria>`. Relation methods keep
the same criteria type, so checks continue after the first query call:

```haxe
var allOpen = Todo.all()
	.where({status: "open"})
	.order(Todo.f.title.asc())
	.limit(3);

var distinctOpen = Todo.distinct()
	.where({status: "open"})
	.order(Todo.f.title.asc());

var notDone = Todo
	.whereNot({status: "done"})
	.order(Todo.f.title.asc())
	.limit(8);

var assignedNotDone = Todo
	.where({title: "assigned"})
	.whereNot({status: "done"})
	.limit(2);

var openOrDoneByField = Todo
	.whereIn(Todo.f.status, ["open", "done"])
	.order(Todo.f.title.asc())
	.limit(9);

var assignedNotArchived = Todo
	.where({title: "assigned"})
	.whereNotIn(Todo.f.status, ["archived"])
	.limit(2);

var missingNotes = Todo.whereNull(Todo.f.notes).limit(3);
var assignedWithNotes = Todo
	.where({title: "assigned"})
	.whereNotNull(Todo.f.notes)
	.limit(2);

var emptyOpen = Todo.none()
	.where({status: "open"});

var emptyAssigned = Todo.where({title: "assigned"})
	.none()
	.limit(1);

var reverseOpen = Todo.reverseOrder()
	.where({status: "open"})
	.limit(2);

var reverseAssigned = Todo.where({title: "assigned"})
	.reverseOrder()
	.limit(2);

var readonlyOpen = Todo.readOnly()
	.where({status: "open"})
	.limit(2);

var readonlyAssigned = Todo.where({title: "assigned"})
	.readOnly()
	.limit(2);

var lockedOpen = Todo.lock()
	.where({status: "open"})
	.limit(1);

var lockedAssigned = Todo.where({title: "assigned"})
	.lock(rails.active_record.Lock.forUpdate())
	.first();

var transactionCount:Int = Todo.transaction(function() {
	return Todo.where({status: "open"})
		.lock(rails.active_record.Lock.share())
		.count();
}, {requiresNew: true, isolation: rails.active_record.TransactionIsolation.serializable()});

var nestedIncludes = Todo
	.includes(rails.active_record.Association.nested(Todo.a.user, User.a.todos))
	.where({status: "open"});

var nestedPreload = Todo
	.preload(rails.active_record.Association.nested(Todo.a.user, User.a.todos))
	.limit(2);

var nestedEagerLoad = Todo
	.where({status: "open"})
	.eagerLoad(rails.active_record.Association.nested(Todo.a.user, User.a.todos))
	.limit(2);

var nestedCriteria = Todo
	.joins(Todo.a.user)
	.where({user: {name: "owner"}})
	.limit(3);
var nestedFoundBy:Null<Todo> = Todo.joins(Todo.a.user).findBy({user: {name: "owner"}});
var nestedExists:Bool = Todo.joins(Todo.a.user).exists({user: {id: 1}});

var openOrDone = Todo.where({status: "open"})
	.or(Todo.where({status: "done"}))
	.order(Todo.f.title.asc());

var mergedOpen = Todo.where({status: "open"})
	.merge(Todo.where({completed: false}))
	.limit(7);

var selectedOpen = Todo.select(Todo.f.title)
	.where({status: "open"});

var relation = Todo
	.where({title: "assigned"})
	.rewhere({status: "done"})
	.distinct()
	.order(Todo.f.title.asc())
	.reorder(Todo.f.id.desc())
	.offset(20)
	.limit(5);

var assigned:Null<Todo> = relation.findBy({externalId: "assigned-1"});
```

Generated Ruby:

```ruby
Models::Todo.all().where(status: "open").order(title: :asc).limit(3)
Models::Todo.distinct().where(status: "open").order(title: :asc)
Models::Todo.where.not(status: "done").order(title: :asc).limit(8)
Models::Todo.where(title: "assigned").where.not(status: "done").limit(2)
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
Models::Todo.includes({user: :todos}).where(status: "open")
Models::Todo.preload({user: :todos}).limit(2)
Models::Todo.where(status: "open").eager_load({user: :todos}).limit(2)
Models::Todo.joins(:user).where(user: {name: "owner"}).limit(3)
Models::Todo.joins(:user).find_by(user: {name: "owner"})
Models::Todo.joins(:user).exists?(user: {id: 1})
Models::Todo.where(status: "open").or(Models::Todo.where(status: "done")).order(title: :asc)
Models::Todo.where(status: "open").merge(Models::Todo.where(completed: false)).limit(7)
Models::Todo.select(:title).where(status: "open")
assigned = Models::Todo.where(title: "assigned").rewhere(status: "done").distinct().order(title: :asc).reorder(id: :desc).offset(20).limit(5)
assigned.find_by(external_id: "assigned-1")
```

This is still a Rails relation chain. Haxe is only making the relation shape and
field refs visible to the compiler.

`whereNot({...})` is the typed RailsHx spelling for Rails `where.not(...)`.
It reuses the same criteria object as `where({...})`, so common negative
predicates do not need raw SQL strings:

```haxe
var notDone = Todo.whereNot({status: "done"});
```

`whereIn(field, values)` and `whereNotIn(field, values)` cover Rails `IN` /
`NOT IN` predicates without raw SQL strings. The field owner and array element
type are checked by Haxe:

```haxe
Todo.whereIn(Todo.f.status, ["open", "done"]);
Todo.whereNotIn(Todo.f.status, ["archived"]);
```

`whereNull(field)` and `whereNotNull(field)` cover Rails `nil` predicates
without raw `IS NULL` strings. The field must be typed as `Null<T>`, so
non-nullable fields are rejected by Haxe before Ruby is generated:

```haxe
Todo.whereNull(Todo.f.notes);
Todo.whereNotNull(Todo.f.notes);
```

Generated Ruby:

```ruby
Models::Todo.where(notes: nil)
Models::Todo.where.not(notes: nil)
```

`rewhere({...})` uses the same typed criteria object as `where({...})`, so field
names and field value types are still checked while Rails receives a normal
`rewhere(...)` call:

```haxe
var reassigned = Todo
	.where({title: "assigned"})
	.rewhere({status: "done"});
```

Generated Ruby:

```ruby
Models::Todo.where(title: "assigned").rewhere(status: "done")
```

`distinct()` is intentionally just the Rails relation helper. It returns the
same typed `Relation<TModel, TCriteria>` shape, so criteria and field checks
continue after it:

```haxe
var distinctPage = Todo.distinct()
	.where({completed: false})
	.offset(10)
	.limit(10);
```

Generated Ruby:

```ruby
Models::Todo.distinct().where(completed: false).offset(10).limit(10)
```

`none()` creates or keeps a Rails null relation while preserving the typed
relation shape for subsequent calls:

```haxe
var emptyOpen = Todo.none().where({status: "open"});
var emptyAssigned = Todo.where({title: "assigned"}).none().limit(1);
```

Generated Ruby:

```ruby
Models::Todo.none().where(status: "open")
Models::Todo.where(title: "assigned").none().limit(1)
```

`reverseOrder()` maps to Rails `reverse_order`. RailsHx uses the Haxe-style
method name at the authoring layer and emits the Rails-native snake_case call:

```haxe
var reverseOpen = Todo.reverseOrder().where({status: "open"}).limit(2);
var reverseAssigned = Todo.where({title: "assigned"}).reverseOrder().limit(2);
```

Generated Ruby:

```ruby
Models::Todo.reverse_order().where(status: "open").limit(2)
Models::Todo.where(title: "assigned").reverse_order().limit(2)
```

`readOnly()` maps to Rails `readonly` and keeps the relation typed for further
composition:

```haxe
var readonlyOpen = Todo.readOnly().where({status: "open"}).limit(2);
var readonlyAssigned = Todo.where({title: "assigned"}).readOnly().limit(2);
```

Generated Ruby:

```ruby
Models::Todo.readonly().where(status: "open").limit(2)
Models::Todo.where(title: "assigned").readonly().limit(2)
```

`or(...)` composes two typed relations for the same model and criteria shape.
The generated Ruby is the normal Rails call, while Haxe rejects a relation from
another model:

```haxe
var openOrDone = Todo.where({status: "open"})
	.or(Todo.where({status: "done"}));
```

Generated Ruby:

```ruby
Models::Todo.where(status: "open").or(Models::Todo.where(status: "done"))
```

`merge(...)` follows the same conservative v1 rule: merge another typed relation
for the same model and criteria shape, and let Rails do the actual scope merge:

```haxe
var mergedOpen = Todo.where({status: "open"})
	.merge(Todo.where({completed: false}));
```

Generated Ruby:

```ruby
Models::Todo.where(status: "open").merge(Models::Todo.where(completed: false))
```

## Field Refs And Order

Use generated field refs for query helpers that need a column identity:

```haxe
import rails.active_record.Group;
import rails.active_record.Order;
import rails.active_record.Projection;

var recent = AuditLog
	.where({eventCount: 1})
	.order(AuditLog.f.eventCount.desc());

var rewritten = Todo.reorder(Todo.f.title.desc()).limit(4);
var stablePage = Todo.order(Order.many([Todo.f.title.asc(), Todo.f.id.desc()])).limit(20);
var stableRewrite = Todo
	.where({status: "open"})
	.reorder(Order.many([Todo.f.id.desc(), Todo.f.title.asc()]));
var selected = Todo.select(Todo.f.title).where({status: "open"});

var titles:Array<String> = Todo.pluck(Todo.f.title);
var ids:Array<Int> = Todo.where({status: "open"}).pluck(Todo.f.id);
var rows:Array<{id:Int, title:String}> = Projection.pluck(
	Todo.where({status: "open"}),
	{id: Todo.f.id, title: Todo.f.title}
);
var statusCounts:haxe.ds.StringMap<Int> = Group.count(
	Todo.where({status: "open"}),
	Todo.f.status
);
var userCounts:haxe.ds.IntMap<Int> = Group.count(Todo, Todo.f.userId);
var minId:Null<Int> = Todo.minimum(Todo.f.id);
var latestTitle:Null<String> = Todo.where({status: "open"}).maximum(Todo.f.title);
var totalUserIds:Int = Todo.sum(Todo.f.userId);
var averageUserId:Null<Float> = Todo.where({status: "open"}).average(Todo.f.userId);
```

Generated Ruby:

```ruby
Models::AuditLog.where(event_count: 1).order(event_count: :desc)
Models::Todo.reorder(title: :desc).limit(4)
Models::Todo.order(title: :asc, id: :desc).limit(20)
Models::Todo.where(status: "open").reorder(id: :desc, title: :asc)
Models::Todo.select(:title).where(status: "open")
Models::Todo.pluck(:title)
Models::Todo.where(status: "open").pluck(:id)
HXRuby.active_record_projection(Models::Todo.where(status: "open").pluck(:id, :title), ["id", "title"])
HXRuby.active_record_group_count(Models::Todo.where(status: "open").group(:status).count(), :string)
HXRuby.active_record_group_count(Models::Todo.group(:user_id).count(), :int)
Models::Todo.minimum(:id)
Models::Todo.where(status: "open").maximum(:title)
Models::Todo.sum(:user_id)
Models::Todo.where(status: "open").average(:user_id)
```

Prefer `Todo.f.title` over `"title"` for behavior-bearing query code. The string
form may be useful at low-level interop boundaries later, but RailsHx examples
should keep field identity behind generated refs.

`reorder(...)` uses the same typed `Order<TModel>` tokens as `order(...)`, so an
order from another model is rejected before Rails runs. Use `Order.many([...])`
when a stable Rails order needs more than one column; every item in the array
must be an `Order<TModel>`, so mixed-model order lists fail during Haxe
compilation while generated Ruby remains `order(title: :asc, id: :desc)`.

`select(...)` uses generated field refs too. It returns a typed relation and
lowers to Rails `select(:field)`, while fields from another model are rejected.

`pluck(...)` preserves the field value type in the returned array. A string
column becomes `Array<String>`, an integer primary key becomes `Array<Int>`, and
fields from another model are rejected by Haxe before Rails runs.

`Projection.pluck(...)` is for named multi-field projections. The spec must be a
non-empty object literal of generated field refs from the source model; the
return type is inferred from the object keys and field value types, such as
`Array<{id:Int, title:String}>`. Generated Ruby still uses Rails `pluck(:id,
:title)` and a small `HXRuby` row shaper so app code sees named rows instead of
positional arrays.

`Group.count(...)` is for typed grouped counts. `String` fields return
`haxe.ds.StringMap<Int>`, `Int` fields return `haxe.ds.IntMap<Int>`, and fields
from another model are rejected before Rails runs. v1 deliberately rejects other
key types, such as `Bool`, until the target has a clear map representation for
those keys.

Invalid projection/grouping examples fail during Haxe compilation:

```haxe
Projection.pluck(Todo, {id: User.f.id});
Projection.pluck(Todo.where({status: "open"}), {id: Todo.f.id, name: User.f.name});
Projection.pluck(Todo, {});
Group.count(Todo, User.f.name);
Group.count(Todo, Todo.f.completed);
```

`minimum(...)` and `maximum(...)` use the same field refs and return nullable
field values because Rails may not find a row. For example, an integer field
returns `Null<Int>` and a string field returns `Null<String>`.

`sum(...)` and `average(...)` are v1 numeric aggregations for `Int` field refs.
`sum(Todo.f.userId)` returns `Int`; `average(Todo.f.userId)` returns
`Null<Float>` because Rails may not find a row. Non-`Int` fields, such as
`Todo.f.title`, are rejected during Haxe compilation.

## Association Refs

Use generated association refs for `includes` and `joins`:

```haxe
var found = Todo
	.includes(Todo.a.user)
	.where({title: "ship", status: "open"})
	.joins(Todo.a.user)
	.order(Todo.f.title.asc())
	.limit(10);
```

Generated Ruby:

```ruby
Models::Todo
  .includes(:user)
  .where(title: "ship", status: "open")
  .joins(:user)
  .order(title: :asc)
  .limit(10)
```

Association refs are owner-typed. `Todo.includes(User.a.todos)` is rejected
because the association belongs to `User`, not `Todo`.

## Find Boundaries

`find(...)` uses the typed primary-key shape and returns the model:

```haxe
var loaded:Todo = Todo.find(1);
```

`findBy({...})` uses typed criteria and returns `Null<Todo>`:

```haxe
var foundBy:Null<Todo> = Todo.findBy({externalId: "ship-1"});
var relationFoundBy:Null<Todo> = Todo.where({title: "ship"}).findBy({completed: false});
```

Generated Ruby:

```ruby
Models::Todo.find(1)
Models::Todo.find_by(external_id: "ship-1")
Models::Todo.where(title: "ship").find_by(completed: false)
```

## Existence And Counts

Use `exists({...})` when you need a typed Rails `exists?` check without loading a
record:

```haxe
var hasAssigned = Todo.exists({externalId: "assigned-1"});
var hasOpenAssigned = Todo
	.where({title: "assigned"})
	.exists({status: "open"});
```

Generated Ruby:

```ruby
Models::Todo.exists?(external_id: "assigned-1")
Models::Todo.where(title: "assigned").exists?(status: "open")
```

`exists(...)` uses the same criteria type as `where(...)` and `findBy(...)`, so
unknown fields and wrong value types fail during Haxe compilation.

Use `count()` for Rails-native counts on models or composed relations:

```haxe
var openCount = Todo.where({status: "open"}).count();
var totalCount = Todo.count();
```

Generated Ruby:

```ruby
Models::Todo.where(status: "open").count()
Models::Todo.count()
```

Use `first()` and `last()` when the query intentionally loads one nullable
record:

```haxe
var first:Null<Todo> = Todo.where({status: "open"}).first();
var last:Null<Todo> = Todo.last();
var assignedLast:Null<Todo> = Todo.where({title: "assigned"}).last();
```

Generated Ruby:

```ruby
Models::Todo.where(status: "open").first()
Models::Todo.last()
Models::Todo.where(title: "assigned").last()
```

Use `offset(...)` when composing paginated Rails relations. It preserves the
same typed `Relation<TModel, TCriteria>` shape and requires an `Int`:

```haxe
var page = Todo.where({status: "open"}).offset(20).limit(10);
var fromModel = Todo.offset(5).where({completed: false});
```

Generated Ruby:

```ruby
Models::Todo.where(status: "open").offset(20).limit(10)
Models::Todo.offset(5).where(completed: false)
```

## Loading For Controllers And Templates

Keep relations lazy while composing query scopes. Convert to arrays only at the
boundary where RailsHx needs loaded records, such as controller locals:

```haxe
var todos = Todo
	.incomplete()
	.includes(Todo.a.user)
	.order(Todo.f.title.asc())
	.offset(20)
	.limit(10)
	.toArray();

ViewMacro.renderTemplate(this, template, {
	todos: todos,
	todoCount: todos.length
});
```

Generated Ruby:

```ruby
todos = Models::Todo.incomplete().includes(:user).order(title: :asc).offset(20).limit(10).to_a()
```

That boundary is intentional: query code stays ActiveRecord-shaped, while
templates receive typed Haxe arrays.

## Typed Rails Scopes

Annotate a static model method with `@:railsScope` when it is part of the
model's Rails query API:

```haxe
@:railsScope
public static function incomplete() {
	return Todo.where({completed: false});
}

@:railsScope
public static function withStatus(status:String) {
	return Todo.where({status: status});
}

var scoped = Todo.incomplete().includes(Todo.a.user).limit(5);
var statusScoped = Todo.withStatus("open").order(Todo.f.title.asc()).limit(4);
```

The Haxe method body is type-checked like any other query code. Generated model
Ruby uses Rails-native scope macros:

```ruby
scope :incomplete, -> { where(completed: false) }
scope :with_status, ->(status__hx0) { where(status: status__hx0) }

Models::Todo.incomplete().includes(:user).limit(5)
Models::Todo.with_status("open").order(title: :asc).limit(4)
```

Use `@:railsDefaultScope` only for deliberate Rails default scopes:

```haxe
@:railsDefaultScope
public static function orderedByTitle() {
	return Todo.order(Todo.f.title.asc());
}
```

Generated Ruby:

```ruby
default_scope -> { order(title: :asc) }
```

Use ordinary static methods for class helpers that should remain `def self.*`.
Use `@:railsScope` for composable query scopes that Rails developers should see
as `scope :name`.

## Current Limits

The current query slice intentionally covers the common Rails relation path:

- Typed criteria for flat model columns.
- Typed association refs for `includes` and `joins`.
- Typed null relations through `none`.
- Typed Rails query helpers through Haxe casing, such as `reverseOrder()` and `readOnly()`.
- Typed relation composition through `or` and `merge`.
- Typed field refs for `order`.
- `limit`, `offset`, `first`, `find`, `findBy`, `create`, and `toArray`.
- Relation criteria checks that persist through assigned relation variables.

Follow-up work remains for richer scope builders, aggregations, nested
association-aware criteria, multi-model joins/projections, richer grouped-query
key types, and more complete Rails query APIs. Until those land, prefer small
typed externs or typed wrapper methods at the boundary rather than raw strings
or `__ruby__` in app code.

## Example And Tests

See `examples/active_record_model` for the focused query fixture and
`examples/todoapp_rails/controllers/TodosController.hx` for controller-boundary
usage with `toArray()`.

Run:

```bash
npm run test:active-record-model
npm run test:todoapp-rails
```
