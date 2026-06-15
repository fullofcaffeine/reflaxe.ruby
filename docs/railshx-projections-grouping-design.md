# RailsHx Multi-Field Projection And Grouping Design

This design locks the v1 direction for typed ActiveRecord multi-field
projection, selected grouped aggregate projections, and grouped counts. It
follows the existing RailsHx query contract: Haxe authoring stays typed,
generated Ruby stays Rails-shaped, and field identity flows through generated
`Field<TModel, TValue>` refs plus typed `Aggregate.*` expressions.
For the underlying expression/predicate/Arel boundary, see
[RailsHx Query Expression Design](railshx-query-expression-design.md).

## Goals

- Keep app code Rails-shaped, but replace string/symbol column lists with typed
  field refs.
- Preserve Haxe IntelliSense and compile-time owner checks for projection and
  grouping fields and aggregate expressions.
- Emit normal ActiveRecord query calls such as `pluck(:id, :title)`,
  `group(:status).pluck(:status, arel_table[:id].count)`, and
  `group(:status).count`.
- Keep v1 narrow: one model owner, generated field refs and typed aggregate
  expressions only, no arbitrary SQL expression DSL, no joins-across-models
  projection typing.

## Chosen Public API

Use macro facades instead of relation methods for multi-field features whose
return types depend on object-literal keys or field value types.

```haxe
import rails.active_record.Aggregate;
import rails.active_record.Group;
import rails.active_record.Projection;

var rows:Array<{id:Int, title:String}> = Projection.pluck(
	Todo.where({status: "open"}),
	{id: Todo.f.id, title: Todo.f.title}
);

var rowsFromModel:Array<{id:Int, title:String}> = Projection.pluck(
	Todo,
	{id: Todo.f.id, title: Todo.f.title}
);

var counts:haxe.ds.StringMap<Int> = Group.count(Todo.all(), Todo.f.status);

var groupedRows:Array<{status:String, todoCount:Int}> = Projection.group(
	Todo.where({status: "open"}),
	Todo.f.status,
	{status: Todo.f.status, todoCount: Aggregate.count(Todo.f.id)}
);
```

### Projection API

`Projection.pluck(source, spec)` is the v1 multi-field projection API.

- `source` accepts either a `@:railsModel` class expression such as `Todo` or a
  `Relation<TModel, TCriteria>`.
- `spec` must be an object literal whose values are generated field refs owned
  by the same model.
- The returned row type is an anonymous object matching the spec keys and field
  value types.
- Spec keys are output names. Field refs decide Rails column names.

Generated Ruby must keep ActiveRecord visible:

```ruby
HXRuby.active_record_projection(
  Models::Todo.where(status: "open").pluck(:id, :title),
  ["id", "title"]
)
```

The runtime helper returns Ruby hashes with string keys so generated Haxe
anonymous-object field access stays compatible with the existing Ruby target
object representation.

### Grouped Aggregate Projection API

`Projection.group(source, field, spec)` is the v1 selected grouped aggregate
row API.

- `source` accepts either a `@:railsModel` class expression or
  `Relation<TModel, TCriteria>`.
- `field` is the grouped field and must be owned by the same model as the
  source.
- `spec` must be a non-empty object literal whose values are the grouped field
  or typed `Aggregate.*` expressions from the same model.
- The returned row type is an anonymous object matching the spec keys and value
  types, for example `Array<{status:String, todoCount:Int}>`.
- v1 rejects arbitrary non-grouped field refs so RailsHx does not emit invalid
  SQL behind a nice-looking Haxe type.

Generated Ruby keeps ActiveRecord and Arel visible:

```ruby
HXRuby.active_record_projection(
  Models::Todo.where(status: "open").group(:status).pluck(:status, Models::Todo.arel_table[:id].count),
  ["status", "todoCount"]
)
```

### Grouped Count API

`Group.count(source, field)` is the v1 grouped-count API.

- `source` accepts either a `@:railsModel` class expression or
  `Relation<TModel, TCriteria>`.
- `field` must be a generated `Field<TModel, TValue>` owned by the same model.
- Return type depends on the field value type:
  - `Field<TModel, String>` returns `haxe.ds.StringMap<Int>`.
  - `Field<TModel, Int>` returns `haxe.ds.IntMap<Int>`.
  - Other key types are deferred unless already supported by a concrete Haxe map
    target in this repo.

Generated Ruby:

```ruby
HXRuby.active_record_group_count(
  Models::Todo.where(status: "open").group(:status).count,
  :string
)
```

The runtime helper converts Rails' hash result into the Haxe map implementation
expected by the return type.

## Validation And Failures

These must fail during Haxe compilation:

```haxe
Projection.pluck(Todo, {id: User.f.id});
Projection.pluck(Todo.where({status: "open"}), {id: Todo.f.id, name: User.f.name});
Projection.pluck(Todo, {});
Projection.group(Todo, Todo.f.status, {status: Todo.f.status, userCount: Aggregate.count(User.f.id)});
Projection.group(Todo, Todo.f.status, {status: Todo.f.status, todoCount: "COUNT(*)"});
Projection.group(Todo, Todo.f.status, {title: Todo.f.title, todoCount: Aggregate.count(Todo.f.id)});
Group.count(Todo, User.f.name);
Group.count(Todo, Todo.f.completed); // deferred until Bool map support exists
```

Implementation should produce clear macro errors:

- Projection specs must be non-empty object literals.
- Projection fields must be generated RailsHx model field refs.
- Grouped projection specs must use the grouped field or typed aggregate
  expressions.
- Every projection/group field must belong to the source model.
- Group count only supports key types with an implemented Haxe map target.

## Implementation Notes

- Add `std/rails/active_record/Projection.hx` and
  `std/rails/active_record/Group.hx` as macro facades.
- Add compiler lowering for the macro-emitted internal calls, not app-facing raw
  Ruby escapes.
- Reuse existing field-ref metadata extraction (`@:railsField`) and owner typing
  patterns from `ParamsMacro`/`ModelMacro`.
- Add runtime helpers only for result shaping, not query construction.
- Keep single-field `select`, `pluck`, `minimum`, and `maximum` unchanged.

## Follow-Up Beads

Created follow-up beads:

- `haxe.ruby-4fa`: `Implement RailsHx named multi-field Projection.pluck`
- `haxe.ruby-fbw`: `Implement RailsHx typed Group.count`
- `haxe.ruby-lbt`: `Document RailsHx projection and grouped count query APIs`

Each implementation bead must update `examples/active_record_model`, generated
Ruby smoke assertions, negative compile cases, snapshots, query docs, and package
inventory.
