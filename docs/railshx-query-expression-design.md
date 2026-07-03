# RailsHx Query Expression Design

This document defines the RailsHx typed expression layer used by ActiveRecord
query APIs. The public Haxe contract is `Expr<TModel, TValue>` and
`Predicate<TModel>`; Arel is a generated Ruby backend detail, not an app-facing
DSL.

Tracking bead: `haxe.ruby-deg`.

Aggregate/having implementation bead: `haxe.ruby-6ri`.

Policy class: this layer is a typed default. It may consume checked field refs,
but it is not an escape hatch; raw SQL remains behind explicit `Sql.unsafe*`
APIs.

## Goals

- Keep query chains Rails-shaped: `Todo.where(Todo.f.title.lower().eq("ship")).order(...).limit(10)`.
- Preserve model ownership in the type system so expressions from `User` cannot
  flow into a `Todo` relation.
- Preserve value typing so predicate values match field/expression types.
- Emit recognizable Rails/Arel Ruby without asking users to author raw SQL.
- Keep raw fragments behind explicit, searchable `Sql.unsafe*` escape hatches.

## Public API

Field refs remain the starting point:

```haxe
Todo.f.id.expr();      // Expr<Todo, Int>
Todo.f.title.lower();  // Expr<Todo, String>
Todo.f.id.count();     // Expr<Todo, Int>
```

The older explicit forms (`Expr.field(Todo.f.id)`,
`Expr.lower(Todo.f.title)`, and `Aggregate.count(Todo.f.id)`) remain supported
for compatibility and framework internals, but new app-facing examples should
prefer the fluent field helpers.

Expression values can become predicates:

```haxe
Todo.where(Todo.f.id.gt(1));
Todo.whereNot(Todo.f.title.lower().eq("ship"));
Group.countHaving(Todo, Todo.f.status, Todo.f.id.count().gt(1));
Projection.group(Todo, Todo.f.status, {
	status: Todo.f.status,
	todoCount: Todo.f.id.count()
});
```

Expression values can also become typed order tokens:

```haxe
Todo.order(Todo.f.title.lower().asc());
Todo.reorder(Order.many([Todo.f.id.desc(), Todo.f.title.lower().asc()]));
```

Generated Ruby stays Rails/Arel-shaped:

```ruby
Models::Todo.where(Models::Todo.arel_table[:id].gt(1))
Models::Todo.where.not(Models::Todo.arel_table[:title].lower.eq("ship"))
(Models::Todo.group(:status).having(Models::Todo.arel_table[:id].count.gt(1)).count().each_with_object(Haxe::Ds::StringMap.new) { |(key, value), map| map.set(key.to_s, value.to_i) })
(Models::Todo.group(:status).pluck(:status, Models::Todo.arel_table[:id].count).map { |row| values = row.is_a?(Array) ? row : [row]; {"status" => values[0], "todoCount" => values[1]} })
Models::Todo.order(Models::Todo.arel_table[:title].lower.asc)
```

## Type Safety

`Expr<TModel, TValue>` carries two independent pieces of information:

- `TModel` is the relation owner. Relation APIs accept only matching model
  expressions and predicates.
- `TValue` is the expression value type. Predicate methods such as `eq`, `gt`,
  `gte`, `lt`, and `lte` require values of the same Haxe type.

These should fail during Haxe compilation:

```haxe
Todo.order(Expr.lower(User.f.name).asc());
Todo.order(Expr.lower(Todo.f.id).asc());
Todo.whereExpr(Expr.field(Todo.f.id).gt("one"));
Todo.whereExpr(Expr.field(Todo.f.title)); // not a Predicate<Todo>
Todo.where(Todo.f.id.gt("one"));
Todo.where(Todo.f.title.expr()); // not a Predicate<Todo>
```

## Arel Boundary

RailsHx does not expose raw Arel nodes in Haxe. Arel is the Ruby lowering target
because Rails already uses it for typed expression/predicate shapes. The Haxe
API should stay small and typed:

- Add narrow field helpers such as `field.lower()` before adding generic Arel
  access.
- Add aggregate field helpers such as `field.count()` before allowing raw
  `having` strings.
- Keep builder inputs as generated `Field<TModel, TValue>` refs or typed
  RailsHx expressions.
- Lower builders in the compiler to Rails/Arel calls such as
  `Model.arel_table[:column].lower`.

This keeps app code portable at the RailsHx layer while generated Ruby remains
idiomatic Rails.

## SQL Escape Policy

`Expr` and `Predicate` deliberately do not have `from String` conversions.
Strings such as `"LOWER(title) ASC"` are not typed expressions. If RailsHx cannot
model a production query yet, use the explicit SQL escape APIs:

```haxe
Todo.whereSql(Sql.unsafeWhere("status <> 'archived'"));
Todo.orderSql(Sql.unsafeOrder("LOWER(title) ASC"));
```

The escape remains typed by owner and fragment kind:

- `whereSql(...)` requires `Sql<Todo, SqlWhere>`.
- `orderSql(...)` requires `Sql<Todo, SqlOrder>`.
- Plain strings and wrong-kind fragments fail during Haxe compilation.

Every repeated `Sql.unsafe*` use in app code should create a bead for the
missing typed builder.

## Projection, Grouping, And Having

Projection and grouping APIs that depend on result shape should remain macro
facades, not arbitrary expression strings:

- `Projection.pluck(source, {id: Todo.f.id, title: Todo.f.title})` owns
  multi-field result typing.
- `Group.count(source, Todo.f.status)` owns grouped count map typing.
- `Group.countHaving(source, Todo.f.status, Todo.f.id.count().gt(1))`
  owns v1 aggregate `having` predicates.
- `Projection.group(source, Todo.f.status, {status: Todo.f.status, todoCount:
  Todo.f.id.count()})` owns v1 selected aggregate result row shapes.
- Future selected aggregate work should extend the typed projection builders
  rather than introducing raw `select("COUNT(*) AS todo_count")` strings.

Follow-up work should focus on richer grouped keys, joins, and aggregate
expression breadth.

## Implementation Rules

- Prefer typed builders over `Sql.unsafe*`.
- Keep model ownership in all expression/order/predicate/aggregate tokens.
- Keep generated Ruby recognizable to Rails maintainers.
- Add negative tests for wrong model owner, wrong value type, non-predicate
  where expressions, and accidental raw strings.
- Update `docs/railshx-sql-string-policy.md` when a new expression surface adds
  or widens an escape hatch.
