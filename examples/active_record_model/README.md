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
import rails.active_record.Group;
import rails.active_record.Projection;

var allOpen = Todo
	.all()
	.where({status: "open"})
	.order(Todo.f.title.asc())
	.limit(3);

var distinctOpen = Todo
	.distinct()
	.where({status: "open"})
	.order(Todo.f.title.asc());

var staticReordered = Todo.reorder(Todo.f.title.desc()).limit(4);
var reassigned = Todo.where({title: "assigned"}).rewhere({status: "done"});
var staticRewhere = Todo.rewhere({completed: true}).limit(1);
var selected = Todo.select(Todo.f.title).where({status: "open"});

var titles:Array<String> = Todo.pluck(Todo.f.title);
var assignedIds:Array<Int> = Todo.where({title: "assigned"}).pluck(Todo.f.id);
var projected:Array<{id:Int, title:String}> = Projection.pluck(
	Todo.where({status: "open"}),
	{id: Todo.f.id, title: Todo.f.title}
);
var statusCounts:haxe.ds.StringMap<Int> = Group.count(
	Todo.where({status: "open"}),
	Todo.f.status
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
```

Generated Ruby:

```ruby
Models::Todo.all().where(status: "open").order(title: :asc).limit(3)
Models::Todo.distinct().where(status: "open").order(title: :asc)
Models::Todo.reorder(title: :desc).limit(4)
Models::Todo.where(title: "assigned").rewhere(status: "done")
Models::Todo.rewhere(completed: true).limit(1)
Models::Todo.select(:title).where(status: "open")
Models::Todo.pluck(:title)
Models::Todo.where(title: "assigned").pluck(:id)
HXRuby.active_record_projection(Models::Todo.where(status: "open").pluck(:id, :title), ["id", "title"])
HXRuby.active_record_group_count(Models::Todo.where(status: "open").group(:status).count(), :string)
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
```

Type-safety features used here:

- `where({...})` object keys must be `@:railsColumn` fields.
- `where({...})` values must match those field types.
- `rewhere({...})` uses the same typed criteria object while lowering to Rails `rewhere`.
- `Todo.associations.user` / `Todo.a.user` must belong to `Todo`.
- `Todo.f.title.asc()` produces a typed `Order<Todo>`.
- `Todo.select(Todo.f.title)` returns a relation and lowers to Rails `select(:title)`.
- `Todo.reorder(Todo.f.title.desc())` uses the same owner-typed order token.
- `Todo.pluck(Todo.f.title)` returns `Array<String>` from the field value type.
- `Projection.pluck(Todo.where(...), {id: Todo.f.id, title: Todo.f.title})`
  returns named rows such as `Array<{id:Int, title:String}>`, rejects empty
  specs, and rejects fields from another model before Rails runs.
- `Group.count(Todo.where(...), Todo.f.status)` returns `StringMap<Int>` for
  string keys, `Group.count(Todo, Todo.f.userId)` returns `IntMap<Int>` for
  integer keys, and unsupported key types fail during Haxe compilation.
- `Todo.maximum(Todo.f.id)` returns `Null<Int>` and rejects fields from other models.
- `Todo.sum(Todo.f.userId)` returns `Int`, `Todo.average(Todo.f.userId)`
  returns `Null<Float>`, and non-`Int` fields fail during Haxe compilation.
- The chain remains a typed relation after `all`, `distinct`, `where`, `joins`,
  `order`, `limit`, and `offset`.

Invalid projection/grouping examples fail during Haxe compilation:

```haxe
Projection.pluck(Todo, {id: User.f.id});
Projection.pluck(Todo.where({status: "open"}), {id: Todo.f.id, name: User.f.name});
Projection.pluck(Todo, {});
Group.count(Todo, User.f.name);
Group.count(Todo, Todo.f.completed);
```

## Scopes

`Todo.incomplete()` is a typed static scope:

```haxe
public static function incomplete() {
	return Todo.where({completed: false});
}

var scoped = Todo.incomplete().includes(Todo.a.user).limit(5);
```

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

Generated Ruby:

```ruby
def self.incomplete()
  return Models::Todo.where(completed: false)
end

Models::Todo.incomplete().includes(:user).limit(5)
```

Use static model methods for small Rails-shaped scopes. They keep IntelliSense
on the Haxe side and still generate ordinary Ruby methods.

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
```

`findBy` is criteria typed and returns `Null<Todo>`:

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
Todo.includes(User.a.todos);
Todo.find("nope");
Todo.findBy({missing: "nope"});
Todo.exists({missing: "nope"});
Todo.where({status: "open"}).offset("nope");
```

The goal is not to hide Rails. The goal is to keep the Rails API shape while
moving common query mistakes from runtime to compile time.
