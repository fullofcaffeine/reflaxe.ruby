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

- Keep query chains Rails-shaped: `Todo.whereExpr(...).order(...).limit(10)`.
- Preserve model ownership in the type system so expressions from `User` cannot
  flow into a `Todo` relation.
- Preserve value typing so predicate values match field/expression types.
- Emit recognizable Rails/Arel Ruby without asking users to author raw SQL.
- Keep raw fragments behind explicit, searchable `Sql.unsafe*` escape hatches.

## Public API

Field refs remain the starting point:

```haxe
Expr.field(Todo.f.id);      // Expr<Todo, Int>
Expr.lower(Todo.f.title);   // Expr<Todo, String>
Aggregate.count(Todo.f.id); // Expr<Todo, Int>
```

Expression values can become predicates:

```haxe
Todo.whereExpr(Expr.field(Todo.f.id).gt(1));
Todo.whereNotExpr(Expr.lower(Todo.f.title).eq("ship"));
Group.countHaving(Todo, Todo.f.status, Aggregate.count(Todo.f.id).gt(1));
```

Expression values can also become typed order tokens:

```haxe
Todo.order(Expr.lower(Todo.f.title).asc());
Todo.reorder(Order.many([Todo.f.id.desc(), Expr.lower(Todo.f.title).asc()]));
```

Generated Ruby stays Rails/Arel-shaped:

```ruby
Models::Todo.where(Models::Todo.arel_table[:id].gt(1))
Models::Todo.where.not(Models::Todo.arel_table[:title].lower.eq("ship"))
HXRuby.active_record_group_count(Models::Todo.group(:status).having(Models::Todo.arel_table[:id].count.gt(1)).count(), :string)
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
```

## Arel Boundary

RailsHx does not expose raw Arel nodes in Haxe. Arel is the Ruby lowering target
because Rails already uses it for typed expression/predicate shapes. The Haxe
API should stay small and typed:

- Add narrow builders such as `Expr.lower(field)` before adding generic Arel
  access.
- Add aggregate builders such as `Aggregate.count(field)` before allowing raw
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
- `Group.countHaving(source, Todo.f.status, Aggregate.count(Todo.f.id).gt(1))`
  owns v1 aggregate `having` predicates.
- Future selected aggregate aliases should be typed projection builders with an
  inferred result shape, not raw `select("COUNT(*) AS todo_count")` strings.

Follow-up work should focus on named selected aggregate row shapes.

## Implementation Rules

- Prefer typed builders over `Sql.unsafe*`.
- Keep model ownership in all expression/order/predicate/aggregate tokens.
- Keep generated Ruby recognizable to Rails maintainers.
- Add negative tests for wrong model owner, wrong value type, non-predicate
  where expressions, and accidental raw strings.
- Update `docs/railshx-sql-string-policy.md` when a new expression surface adds
  or widens an escape hatch.
