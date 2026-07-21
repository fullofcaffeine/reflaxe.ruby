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

## Typed Writes And External Attributes

`create`, `createBang`, `build`, and instance `update` use a schema-derived
optional attribute carrier rather than `Dynamic`. Known model columns are
completed and type-checked in Haxe, then emitted as ordinary Rails keyword
attributes with Ruby column names:

```haxe
var todo = Todo.create({title: "ship", completed: false});
todo.update({completed: true});
```

```ruby
todo = Todo.create(title: "ship", completed: false)
todo.update(completed: true)
```

Checked strong params use a separate nominal path. `ParamsMacro.requirePermit`
returns `PermittedParams<Todo>` backed by the original Rails
`ActionController::Parameters`, and the generated write overload keeps it as a
single positional value:

```haxe
var attrs = ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title]);
Todo.create(attrs);
```

```ruby
attrs = params.require("todo").permit([:title])
Todo.create(attrs)
```

This distinction is intentional: inline Haxe attribute objects are projected
to typed Ruby keywords, while Rails-owned permitted params retain Rails'
indifferent-access keys and permitted-state behavior. Neither path uses
`Dynamic` in the public Haxe contract.

Some gems or framework modules install writable virtual attributes that are not
database columns. Declare those as precisely typed `@:railsExternalAttribute`
fields. They participate in create/build/update completion but do not emit an
accessor, schema fact, query field ref, or migration; the named Ruby/gem owner
must provide the runtime reader/writer. Field-level `@:native` maps a different
Ruby spelling:

```haxe
@:railsExternalAttribute
public var password:String;

@:native("password_confirmation")
@:railsExternalAttribute
public var passwordConfirmation:String;
```

This is an explicit interop boundary, not permission to add arbitrary keys. A
missing runtime owner remains a Ruby integration error, while a missing, extra,
or incorrectly typed Haxe attribute is rejected during compilation.

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

var firstTen = Todo.whereBetween(Todo.f.id, 1, 10)
	.order(Todo.f.id.asc());

var assignedOutsideFirstTen = Todo
	.where({title: "assigned"})
	.whereNotBetween(Todo.f.id, 1, 10)
	.limit(2);

var afterFirst = Todo.whereGt(Todo.f.id, 1)
	.order(Todo.f.id.asc());

var assignedNotSmall = Todo
	.where({title: "assigned"})
	.whereNotLte(Todo.f.id, 10)
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

`whereBetween(field, min, max)` and `whereNotBetween(field, min, max)` cover
Rails range predicates without raw SQL strings. The field owner and endpoint
types are checked by Haxe:

```haxe
Todo.whereBetween(Todo.f.id, 1, 10);
Todo.whereNotBetween(Todo.f.id, 1, 10);
```

Generated Ruby:

```ruby
Models::Todo.where(id: 1..10)
Models::Todo.where.not(id: 1..10)
```

`whereGt`, `whereGte`, `whereLt`, and `whereLte` cover strict and inclusive
comparisons. Their `whereNot*` forms keep negation typed. These lower through
Rails/Arel predicates because strict `>` / `<` comparisons cannot be expressed
faithfully with ordinary Rails hash equality:

```haxe
Todo.whereGt(Todo.f.id, 1);
Todo.whereNotLte(Todo.f.id, 10);
```

Generated Ruby:

```ruby
Models::Todo.where(Models::Todo.arel_table[:id].gt(1))
Models::Todo.where.not(Models::Todo.arel_table[:id].lteq(10))
```

These convenience methods and fluent field predicates use the same compiler
predicate backend as `whereExpr(Expr.field(Todo.f.id).gt(1))`. Prefer the
field-shaped DSL for handwritten code:

```haxe
Todo.where(Todo.f.id.gt(1));
Todo.where(Todo.f.title.lower().eq("ship"));
assigned.whereNot(Todo.f.title.lower().eq("ship"));
```

Use explicit `Expr.*` builders when you need a lower-level compatibility form
or are building framework internals.

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
var caseFolded = Todo.order(Todo.f.title.lower().asc()).limit(20);
var lowerShip = Todo.where(Todo.f.title.lower().eq("ship")).limit(2);
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
var groupedRows:Array<{status:String, todoCount:Int, userIdSum:Int, averageUserId:Float, minId:Int, maxTitle:String}> = Projection.group(
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
var statusCounts:haxe.ds.StringMap<Int> = Group.count(
	Todo.where({status: "open"}),
	Todo.f.status
);
var busyStatusCounts:haxe.ds.StringMap<Int> = Group.countHaving(
	Todo.where({status: "open"}),
	Todo.f.status,
	Todo.f.id.count().gt(1)
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
Models::Todo.order(Models::Todo.arel_table[:title].lower.asc).limit(20)
Models::Todo.where(Models::Todo.arel_table[:title].lower.eq("ship")).limit(2)
Models::Todo.where(status: "open").reorder(id: :desc, title: :asc)
Models::Todo.select(:title).where(status: "open")
Models::Todo.pluck(:title)
Models::Todo.where(status: "open").pluck(:id)
Models::Todo.where(status: "open").pluck(:id, :title).map do |projection_row|
  projection_values = (projection_row.is_a?(Array) ? projection_row : [projection_row])
  {"id" => projection_values[0], "title" => projection_values[1]}
end
Models::Todo.where(status: "open").group(:status).pluck(:status, Models::Todo.arel_table[:id].count, Models::Todo.arel_table[:user_id].sum, Models::Todo.arel_table[:user_id].average, Models::Todo.arel_table[:id].minimum, Models::Todo.arel_table[:title].maximum).map do |projection_row__hx2|
  projection_values__hx2 = (projection_row__hx2.is_a?(Array) ? projection_row__hx2 : [projection_row__hx2])
  {"status" => projection_values__hx2[0], "todoCount" => projection_values__hx2[1], "userIdSum" => projection_values__hx2[2], "averageUserId" => projection_values__hx2[3], "minId" => projection_values__hx2[4], "maxTitle" => projection_values__hx2[5]}
end
Models::Todo.where(status: "open").group(:status).count().each_with_object(Haxe::Ds::StringMap.new()) { |grouped_count_entry, grouped_count_map| grouped_count_map.set(grouped_count_entry[0].to_s(), grouped_count_entry[1].to_i()) }
Models::Todo.where(status: "open").group(:status).having(Models::Todo.arel_table[:id].count.gt(1)).count().each_with_object(Haxe::Ds::StringMap.new()) { |grouped_count_entry__hx1, grouped_count_map__hx1| grouped_count_map__hx1.set(grouped_count_entry__hx1[0].to_s(), grouped_count_entry__hx1[1].to_i()) }
Models::Todo.group(:user_id).count().each_with_object(Haxe::Ds::IntMap.new()) { |grouped_count_entry__hx2, grouped_count_map__hx2| grouped_count_map__hx2.set(grouped_count_entry__hx2[0].to_i(), grouped_count_entry__hx2[1].to_i()) }
Models::Todo.minimum(:id)
Models::Todo.where(status: "open").maximum(:title)
Models::Todo.sum(:user_id)
Models::Todo.where(status: "open").average(:user_id)
```

The block-local names are allocated by the compiler. The readable base names
shown above gain `__hxN` suffixes whenever necessary, so result conversion
cannot capture or overwrite a Haxe local with the same name.

Prefer `Todo.f.title` over `"title"` for behavior-bearing query code. The string
form may be useful at low-level interop boundaries later, but RailsHx examples
should keep field identity behind generated refs.

`reorder(...)` uses the same typed `Order<TModel>` tokens as `order(...)`, so an
order from another model is rejected before Rails runs. Use `Order.many([...])`
when a stable Rails order needs more than one column; every item in the array
must be an `Order<TModel>`, so mixed-model order lists fail during Haxe
compilation while generated Ruby remains `order(title: :asc, id: :desc)`.

`Expr<TModel, TValue>` is the typed RailsHx expression layer behind field
helpers such as `Todo.f.id.gt(1)`, `Todo.f.title.lower()`, and
`Todo.f.id.count()`. It is intentionally narrower than Arel: app code starts
from generated field refs, while the compiler lowers them to
`Models::Todo.arel_table[:id]` and
`Models::Todo.arel_table[:title].lower`. `lower()` only exists for `String`
fields from the owning model, so `Todo.f.id.lower()` and
`Todo.order(User.f.name.lower().asc())` fail during Haxe compilation.
For the expression, aggregate, and having design contract, see
[RailsHx Query Expression Design](railshx-query-expression-design.md).

`where(predicate)` and `whereNot(predicate)` accept `Predicate<TModel>` values
produced by typed field/expression methods:

```haxe
Todo.where(Todo.f.id.gt(1));
Todo.whereNot(Todo.f.title.lower().eq("ship"));
```

Generated Ruby:

```ruby
Models::Todo.where(Models::Todo.arel_table[:id].gt(1))
Models::Todo.where.not(Models::Todo.arel_table[:title].lower.eq("ship"))
```

This is not a raw SQL escape hatch. Plain strings such as
`Todo.order("LOWER(title) ASC")` remain rejected; future truly raw fragments
must go through explicit `Sql.*` APIs covered by the SQL/string policy.

## Explicit SQL Escape Hatches

Prefer typed builders first. When Rails needs a fragment RailsHx cannot model
yet, use the explicit, searchable `Sql.unsafe*` APIs plus matching relation
methods:

```haxe
import rails.active_record.Sql;

var active = Todo.whereSql(Sql.unsafeWhere("status <> 'archived'")).limit(2);
var notDone = Todo
	.where({title: "assigned"})
	.whereNotSql(Sql.unsafeWhere("status = 'done'"));
var legacyOrder = Todo.orderSql(Sql.unsafeOrder("LOWER(title) ASC")).limit(2);
```

Generated Ruby:

```ruby
Models::Todo.where("status <> 'archived'").limit(2) # railshx:allow-raw-sql-example
Models::Todo.where(title: "assigned").where.not("status = 'done'") # railshx:allow-raw-sql-example
Models::Todo.order("LOWER(title) ASC").limit(2) # railshx:allow-raw-sql-example
```

The escape hatch is still typed around the risky string:

- `whereSql(...)` requires `Sql<Todo, SqlWhere>`.
- `orderSql(...)` requires `Sql<Todo, SqlOrder>`.
- Fragments from another model, the wrong SQL kind, or plain strings such as
  `Todo.whereSql("status = 'open'")` fail during Haxe compilation.

Use this for migration/interop gaps and file a bead for the missing typed
builder when a fragment appears in application code.

`select(...)` uses generated field refs too. It returns a typed relation and
lowers to Rails `select(:field)`, while fields from another model are rejected.

`pluck(...)` preserves the field value type in the returned array. A string
column becomes `Array<String>`, an integer primary key becomes `Array<Int>`, and
fields from another model are rejected by Haxe before Rails runs.

`Projection.pluck(...)` is for named multi-field projections. The spec must be a
non-empty object literal of generated field refs from the source model; the
return type is inferred from the object keys and field value types, such as
`Array<{id:Int, title:String}>`. Generated Ruby still uses Rails `pluck(:id,
:title)` plus an inline `map` block that returns named rows instead of
positional arrays.

`Projection.group(...)` is for selected grouped aggregate result rows. The spec
must be a non-empty object literal made from the grouped field and typed
aggregate expressions from the same model, usually field helpers such as
`Todo.f.id.count()`. The object keys become the Haxe row field names and the
aggregate expression types become the row value types, so editors can complete
`row.todoCount` as `Int` and `row.maxTitle` as `String`. Generated Ruby remains
Rails-shaped:
`group(:status).pluck(:status, Model.arel_table[:id].count, ...)` plus the same
inline row shaper. v1 rejects arbitrary non-grouped fields to avoid generating
invalid SQL.

`Group.count(...)` is for typed grouped counts. `String` fields return
`haxe.ds.StringMap<Int>`, `Int` fields return `haxe.ds.IntMap<Int>`, and fields
from another model are rejected before Rails runs. v1 deliberately rejects other
key types, such as `Bool`, until the target has a clear map representation for
those keys.

`Group.countHaving(...)` adds a typed aggregate `having` predicate to grouped
counts. The predicate must be a `Predicate<TModel>` produced by typed field or
expression builders such as `Todo.f.id.count().gt(1)`, so raw strings like
`"COUNT(*) > 1"` and predicates from another model are rejected before Ruby is
emitted. The generated Ruby remains ordinary Rails/Arel:
`group(:status).having(Model.arel_table[:id].count.gt(1)).count()`.

Invalid projection/grouping examples fail during Haxe compilation:

```haxe
Projection.pluck(Todo, {id: User.f.id});
Projection.pluck(Todo.where({status: "open"}), {id: Todo.f.id, name: User.f.name});
Projection.pluck(Todo, {});
Projection.group(Todo, Todo.f.status, {status: Todo.f.status, userCount: User.f.id.count()});
Projection.group(Todo, Todo.f.status, {status: Todo.f.status, todoCount: "COUNT(*)"});
Projection.group(Todo, Todo.f.status, {title: Todo.f.title, todoCount: Todo.f.id.count()});
Group.count(Todo, User.f.name);
Group.count(Todo, Todo.f.completed);
Group.countHaving(Todo, Todo.f.status, User.f.id.count().gt(1));
Group.countHaving(Todo, Todo.f.status, "COUNT(*) > 1");
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

For relation values, `find(...)` accepts a typed scalar Rails ID:

```haxe
var relationLoaded:Todo = Todo.where({status: "open"}).find(1);
```

Static model `find(...)` remains the strongest path because the model macro can
infer the primary-key field type. Relation-level `find(...)` intentionally uses
`Int`/`String` overloads instead of `Dynamic`: it supports common Rails scalar
IDs while rejecting accidental object-shaped arguments and still emits direct
Rails `find(...)` calls without helper runtime. Carrying the exact primary-key
type through
`Relation<TModel, TCriteria>` is future work.

`findBy({...})` uses typed criteria and returns `Null<Todo>`:

```haxe
var foundBy:Null<Todo> = Todo.findBy({externalId: "ship-1"});
var relationFoundBy:Null<Todo> = Todo.where({title: "ship"}).findBy({completed: false});
```

Generated Ruby:

```ruby
Models::Todo.find(1)
Models::Todo.where(status: "open").find(1)
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

- Typed criteria for flat model columns and nested association filters.
- Typed association refs for `includes`, `preload`, `joins`, and `eagerLoad`.
- Typed null relations through `none`.
- Typed Rails query helpers through Haxe casing, such as `reverseOrder()` and `readOnly()`.
- Typed relation composition through `or` and `merge`.
- Typed field refs and fluent expressions for `order`, predicates, aggregates, and `having`.
- Typed transactions and pessimistic locks.
- Typed Rails scope/default-scope declarations.
- `limit`, `offset`, `first`, `find`, `findBy`, `create`, and `toArray`.
- Relation criteria checks that persist through assigned relation variables.

Follow-up breadth remains for multi-model joins/projections, richer grouped-query
key types, and less common Rails query APIs such as `unscope`, `only`, `except`,
`references`, and `strict_loading`. Until those land, prefer small
typed externs or typed wrapper methods at the boundary rather than raw strings
or `__ruby__` in app code.

## Example And Tests

See `examples/active_record_model` for the focused query fixture and
`examples/todoapp_rails/src/controllers/TodosController.hx` for controller-boundary
usage with `toArray()`.

Run:

```bash
npm run test:active-record-model
npm run test:todoapp-rails
```
