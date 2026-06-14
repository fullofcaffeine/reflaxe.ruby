# RailsHx SQL And String-Bearing API Policy

Tracking beads: `haxe.ruby-bjv.3.7`, `haxe.ruby-bjv.10`, and
`haxe.ruby-bjv.4.1`.

RailsHx should emit normal Rails and Ruby, but Haxe authors should not have to
guess whether a string is safe. Every app-facing string/SQL-bearing surface must
belong to one of three classes before it is added.

## Policy Classes

| Class | Rule | Examples | Test expectation |
| --- | --- | --- | --- |
| Typed default | Normal RailsHx app code uses typed refs, builders, externs, macros, or generated constants. No raw strings are needed for known behavior-bearing names. | `Todo.where({status: "open"})`, `Todo.f.title.asc()`, `Todo.a.user`, `Projection.pluck(...)`, `Template.of(View)`, typed Turbo targets. | Positive examples use the typed API; wrong fields/owners/types fail at Haxe compile time. |
| Checked literal | A literal string is accepted because Rails owns the value, but RailsHx checks shape, path, owner, or filesystem state where practical. | `Template.existing("legacy/badge")`, route dump paths, RBS/source paths, `externalTables: ["legacy_events"]`. | Missing/unsafe literals fail closed unless the API name explicitly says unchecked/external. |
| Explicit escape hatch | The value is intentionally raw, dynamic, or not fully statically knowable. The API name must make that risk searchable. | `@:railsAllowRawErb`, future `Sql.raw(...)`, future `Sql.fragment(...)`, `Template.external(...)`, `Lock.custom(...)`. | Canonical examples do not use it casually; docs link the escape to the safer typed alternative or a follow-up bead. |

If an API cannot be classified, do not add it yet. File a bead or design note
instead.

## ActiveRecord Query Policy

Default query authoring should stay Rails-shaped and Haxe-typed:

```haxe
Todo.where({status: "open"}).order(Todo.f.title.asc()).limit(10);
Todo.joins(Todo.a.user).where({user: {name: "owner"}});
Projection.pluck(Todo.where({status: "open"}), {id: Todo.f.id, title: Todo.f.title});
Group.count(Todo, Todo.f.status);
```

These lower to ordinary ActiveRecord calls such as `where(status: "open")`,
`order(title: :asc)`, `joins(:user)`, `pluck(:id, :title)`, and
`group(:status).count`.

Do not add these as casual string overloads:

```haxe
Todo.where("status = 'open'"); // railshx:allow-raw-sql-example
Todo.order("LOWER(title) ASC"); // railshx:allow-raw-sql-example
Todo.select("todos.*, COUNT(*) AS count"); // railshx:allow-raw-sql-example
Todo.group("DATE(created_at)"); // railshx:allow-raw-sql-example
Todo.having("COUNT(*) > 1"); // railshx:allow-raw-sql-example
Todo.joins("INNER JOIN users ..."); // railshx:allow-raw-sql-example
```

The approved path is:

- Use typed criteria objects for equality and nested association filters.
- Use `Field<TModel, TValue>` refs for order/select/pluck/group/aggregate APIs.
- Add typed builders for common predicates before adding raw SQL. Examples:
  `Predicate.not(...)`, `Predicate.inList(...)`, `Predicate.range(...)`,
  `Order.lower(Todo.f.title).asc()`, or typed aggregate aliases.
- If Rails needs a true SQL fragment, add a named escape hatch such as
  `Sql.raw(...)` or `Sql.fragment(...)`, document why a typed builder is not
  sufficient, and cover it with strict-boundary tests.

## Surface Classification

| Surface | Default class | Approved default | Escape hatch policy |
| --- | --- | --- | --- |
| ActiveRecord `where` / `rewhere` / `findBy` / `exists` | Typed default | Criteria object generated from `@:railsColumn` and association metadata; expression predicates through `whereExpr(Expr.field(Todo.f.id).gt(1))` and `whereNotExpr(...)`. | Raw SQL uses explicit `whereSql(Sql.unsafeWhere(...))` / `whereNotSql(...)`, not string overloads. |
| ActiveRecord `order` / `reorder` | Typed default | `Todo.f.title.asc()`, `Order.many([...])`, `Expr.lower(Todo.f.title).asc()`. | Raw ordering uses explicit `orderSql(Sql.unsafeOrder(...))` / `reorderSql(...)`. Additional SQL ordering functions should be typed builders first. |
| ActiveRecord `select` / `pluck` / projections | Typed default | `select(Todo.f.title)`, `Projection.pluck(...)`. | SQL aliases/functions need a typed projection/alias design before raw SQL. |
| ActiveRecord `group` / `having` / aggregates | Typed default | `Group.count(source, Todo.f.status)`, typed aggregates. | `having` and SQL functions require a design bead and either builders or explicit raw fragments. |
| ActiveRecord `joins` / `includes` / `preload` / `eager_load` | Typed default | `Todo.a.user`, `Association.nested(...)`. | Raw join strings are escape hatches only. Prefer association refs or future typed join builders. |
| Migrations | Typed default plus checked literals | Known models, columns, indexes, FKs, reversible operations; `externalTables` for Rails-owned schema. | Raw SQL/data migrations need explicit operation names and rollback policy. |
| Templates, layouts, and partials | Typed default plus checked literals | HHX, `Template.of(...)`, `Template.layout(...)`, `Template.existing(...)`, `Layout.named(...)` for explicit lower-level layout literals. | Raw ERB requires `@:railsAllowRawErb`; unchecked external paths use `Template.external(...)`. |
| Routes | Checked literal source, typed generated output | Rails route dump/generator input, generated route helper externs with `RouteParam` for required segments. | Hand-authored route helper strings are not canonical; model/object route params should cross via `RouteParam.model(...)` rather than app-facing `Dynamic`. |
| Turbo, ActionCable streams, DOM hooks | Typed default | `StreamTarget.named(...)`, `StreamName.named(...)`, `Stream.named(...)`, `SubscriptionParam.named(...)`, shared hook constants/abstracts. Plain strings do not satisfy server-side stream, broadcast, or channel-param APIs. | Literal CSS classes are fine for local styling; behavior hooks should be typed when repeated. |
| Ruby/Rails extension interop | Typed default plus checked source | Externs, RBS/source-backed contracts, mixin/patch contracts. | `Dynamic`/raw Ruby only in explicit interop islands with strict-boundary coverage. |

## Implementation Requirements

Any bead that adds or widens a string/SQL-bearing API must:

- State which policy class it uses.
- Prefer typed defaults over checked literals and checked literals over raw
  escape hatches.
- Add positive examples showing the typed RailsHx API and generated Rails shape.
- Add negative compile/generator tests for wrong fields, wrong owners, missing
  files, unsafe paths, or casual raw strings where applicable.
- Update `docs/railshx-escape-hatch-security-audit.md` if an escape hatch is
  added or widened.
- Include `npm run test:sql-string-policy` when canonical examples, ActiveRecord
  query APIs, migration operations, templates, Turbo targets, or escape hatches
  are touched.

## Current Decision

RailsHx currently forbids raw SQL/string query fragments in canonical examples.
That is intentional. `haxe.ruby-bjv.10` should keep adding typed ActiveRecord
builders such as `Expr.lower(...)`, `whereExpr(...)`, typed aggregates, and
typed escape hatches for common missing query shapes first, and only introduce
explicit SQL escape hatches where typed builders cannot reasonably model Rails
behavior.
