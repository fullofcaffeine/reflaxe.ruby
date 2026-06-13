# RailsHx Typed ActiveRecord Query Guide

RailsHx query code should feel like Rails ActiveRecord with Haxe checking the
parts Rails normally discovers at runtime: model fields, association ownership,
field value types, primary-key types, and relation return shapes.

The rule of thumb is simple:

- Keep query chains Rails-shaped: `all`, `distinct`, `where`, `includes`,
  `joins`, `order`, `limit`, `offset`, `find`, `findBy`, `exists`, `count`,
  `first`, `last`, and `toArray`.
- Put type information at the Haxe boundary: `@:railsColumn`, associations, field
  refs such as `Todo.f.title`, and association refs such as `Todo.a.user`.
- Let the compiler lower Haxe names to Rails names: `externalId` becomes
  `external_id`, `isCompleted` becomes `is_completed`, and `Todo.a.user` becomes
  `:user`.
- Cross from lazy relation to loaded data intentionally with `toArray()` when a
  controller/template needs an `Array<Todo>`.

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

var relation = Todo
	.where({title: "assigned"})
	.distinct()
	.order(Todo.f.title.asc())
	.offset(20)
	.limit(5);

var assigned:Null<Todo> = relation.findBy({externalId: "assigned-1"});
```

Generated Ruby:

```ruby
Models::Todo.all().where(status: "open").order(title: :asc).limit(3)
Models::Todo.distinct().where(status: "open").order(title: :asc)
assigned = Models::Todo.where(title: "assigned").distinct().order(title: :asc).offset(20).limit(5)
assigned.find_by(external_id: "assigned-1")
```

This is still a Rails relation chain. Haxe is only making the relation shape and
field refs visible to the compiler.

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

## Field Refs And Order

Use generated field refs for query helpers that need a column identity:

```haxe
var recent = AuditLog
	.where({eventCount: 1})
	.order(AuditLog.f.eventCount.desc());
```

Generated Ruby:

```ruby
Models::AuditLog.where(event_count: 1).order(event_count: :desc)
```

Prefer `Todo.f.title` over `"title"` for behavior-bearing query code. The string
form may be useful at low-level interop boundaries later, but RailsHx examples
should keep field identity behind generated refs.

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

## Static Scopes

Model-owned static functions are the RailsHx equivalent of small typed scopes:

```haxe
public static function incomplete() {
	return Todo.where({completed: false});
}

var scoped = Todo.incomplete().includes(Todo.a.user).limit(5);
```

Generated Ruby:

```ruby
def self.incomplete()
  return Models::Todo.where(completed: false)
end

Models::Todo.incomplete().includes(:user).limit(5)
```

Keep these methods Rails-shaped: return relations, compose other relations, and
avoid raw Ruby injection in app code.

## Current Limits

The current query slice intentionally covers the common Rails relation path:

- Typed criteria for flat model columns.
- Typed association refs for `includes` and `joins`.
- Typed field refs for `order`.
- `limit`, `offset`, `first`, `find`, `findBy`, `create`, and `toArray`.
- Relation criteria checks that persist through assigned relation variables.

Follow-up work remains for richer scope builders, aggregations, nested
association-aware criteria, select/projection typing, grouped queries, and more
complete Rails query APIs. Until those land, prefer small typed externs or typed
wrapper methods at the boundary rather than raw strings or `__ruby__` in app
code.

## Example And Tests

See `examples/active_record_model` for the focused query fixture and
`examples/todoapp_rails/controllers/TodosController.hx` for controller-boundary
usage with `toArray()`.

Run:

```bash
npm run test:active-record-model
npm run test:todoapp-rails
```
