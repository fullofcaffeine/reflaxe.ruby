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
`findBy` usage.

## Main Query Shapes

`Main.hx` proves relation composition:

```haxe
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
- `Todo.associations.user` / `Todo.a.user` must belong to `Todo`.
- `Todo.f.title.asc()` produces a typed `Order<Todo>`.
- The chain remains a typed relation after `where`, `joins`, `order`, and
  `limit`.

## Scopes

`Todo.incomplete()` is a typed static scope:

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
	.limit(10)
	.toArray();
```

Generated Ruby:

```ruby
Models::Todo.incomplete().includes(:user).order(title: :asc).limit(10).to_a()
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
```

The goal is not to hide Rails. The goal is to keep the Rails API shape while
moving common query mistakes from runtime to compile time.
