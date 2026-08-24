# RailsHx migration-history Oracle disposition

Status: accepted implementation plan. No migration-adoption feature ships from this review.

Oracle request: `orq_20260823T234053Z_91c7e739`

Oracle input revision: `dc02046b4f070a52685be3fcbc878c96c7f1df19`

Rails reference revision: `43a1f3b574cceafcd78d288a1339e37711cf79c7`

Local reconciliation revision: `f4dab829fc1328dd73685454753b69ab91b6e3f3`

Oracle model: GPT-5.6 Pro. Local processor: `gpt-5.6-sol` at `xhigh` reasoning.

## Outcome

RailsHx will not infer migration history from models, `db/schema.rb`, or the database version table.

Rails-owned migration files remain the source of truth until an explicit ownership transfer completes.

RailsHx can later adopt one selected migration through a closed static parser. The parser must reject the complete file when it finds unsupported Ruby.

The adoption path must not load or run the source migration. A disposable Rails database is an independent test oracle after static translation.

The existing `MigrationOperation` type remains the public semantic boundary. The adoption tool can use one private immutable candidate for source facts and review data.

Implementation cannot start with broad adoption. Current rollback defects must be corrected first.

## Local baseline

The current documentation already gives Rails and RailsHx separate ownership:

- Rails owns migration execution, rollback, status, and schema dumps.
- Haxe migration snapshots own RailsHx-generated Ruby migrations.
- Current schema data can validate new operations. It does not describe old intent.
- Migration discovery is report-only.

The current compiler accepts literal `MigrationOperation` arrays. It emits normal ActiveRecord migration classes through one compiler path.

The review found four current safety problems:

1. Name-only index removal is accepted outside `Reversible`.
2. Name-only foreign-key removal is accepted outside `Reversible`.
3. Mixed validation and schema changes in one `ChangeTable` become one up-only block.
4. Generic `--force` can bypass a Rails-owned migration-file collision.

The first two problems are confirmed by the installed Rails runtime. Rails rejects both rollback requests because required restoration data is absent.

The third problem is confirmed by the compiler flow. One validation member marks the complete `change_table` block as up-only.

The fourth problem is confirmed in `HXRuby::Generators::Migration`. The current collision rule accepts `--force` without a source digest.

## Oracle claim matrix

| Oracle claim | Disposition | Local evidence and consequence |
| --- | --- | --- |
| Keep migration history explicit. | Retained | Current docs already use this rule. Models and schema dumps cannot recover ordered intent or rollback data. |
| Allow one-file static adoption for a closed Ruby subset. | Retained | This gives useful adoption without arbitrary Ruby execution or partial translation. |
| Use a private immutable adoption candidate. | Retained | The candidate can hold source facts, spans, digests, and admitted operations. It must not become a public migration IR. |
| Require `Reversible` for name-only index removal. | Retained and urgent | Rails raises `ActiveRecord::IrreversibleMigration` when `remove_index` has a name but no columns. |
| Require `Reversible` for name-only foreign-key removal. | Retained and urgent | Rails raises `ActiveRecord::IrreversibleMigration` when `remove_foreign_key` has no target table. |
| Reject mixed validation and schema members in `ChangeTable`. | Retained and urgent | The current compiler wraps the complete block in `dir.up`. Rollback then skips reversible members. |
| Add restoration-aware removal operations. | Retained | Exact index and foreign-key definitions are required before Rails can recreate the removed object. |
| Add `Irreversible(reason)`. | Retained | An explicit down branch must raise instead of becoming a silent no-op. |
| Separate `--force` from migration ownership transfer. | Retained and urgent | A Boolean flag does not prove which Rails-owned bytes a reviewer accepted. |
| Use a real Ruby parser with source locations. | Retained | Regular expressions cannot enforce a closed Ruby grammar. The dependency choice belongs to the parser task. |
| Execute or sandbox Ruby to discover operations. | Rejected | Migration files can run arbitrary application, file, network, and database code. |
| Reconstruct history from current schema data. | Rejected | Current state omits operation order, original options, data changes, and rollback behavior. |
| Add a general migration IR or a second Ruby emitter. | Rejected | The existing typed operation family and compiler already own Ruby generation. |
| Claim portable adoption after SQLite proof. | Rejected | A portable claim requires the same runtime oracle on SQLite, PostgreSQL, and MySQL. |
| Preserve source comments automatically. | Deferred and out of contract | The review report will state that comments are omitted. Authors can add Haxe comments during review. |

## Integrated conclusion and plan

The work will use small dependent Beads. Each Bead has one observable safety result.

### 1. Record the source-authority contract

Document the one-file boundary, closed grammar, no-execution rule, version profile, adapter profile, and digest-bound handoff.

The initial migration compatibility version is `7.1`. This version matches the current generator default.

Parsing cannot start until this contract names the initial operation catalog and test profiles.

### 2. Correct current rollback behavior

Add focused compile failures for name-only index and foreign-key removal outside `Reversible`.

Reject mixed validation and non-validation members in one `ChangeTable` value.

Make `--force` unable to replace a Rails-owned migration file.

Retain the existing todo example because it uses explicit reversible branches.

### 3. Add exact removal and irreversibility types

Add restoration-aware index and foreign-key removal operations.

Keep add-operation guards separate from restoration data.

Add `Irreversible(reason)` as the sole legal operation in a `Reversible.down` branch.

Use focused Rails runtime tests for forward behavior and rollback behavior.

### 4. Add read-only history inventory

Report the path, digest, timestamp, class, migration version, transaction marker, body form, and first unsupported construct.

Report duplicate timestamps and class names. Do not write files or run Ruby source.

### 5. Add the closed migration parser

Select a pinned parser that gives stable source locations without code execution.

Parse one selected regular file. Reject unknown nodes, calls, values, options, branches, SQL, and helper methods.

Create a private immutable candidate with bounded sizes and relative paths.

### 6. Add deterministic Haxe dry-run output

Render Haxe from the private candidate. Compile it through the existing compiler in a temporary output root.

Parse the generated Ruby with the same closed grammar. Compare normalized operations and show a Ruby diff.

Do not write application files in this stage.

### 7. Prove SQLite behavior

Run the selected original Ruby migration and the generated Ruby migration against separate disposable databases.

Compare the schema, retained rows, new-row defaults, migration version, second-run skip, and rollback state.

Add separate fixtures for explicit directions, irreversibility, exact removals, and ordered table changes.

### 8. Add digest-bound ownership transfer

Require the candidate identifier and original source digest.

Read and hash every input again before mutation. Reject changed source, destination, or manifest bytes.

Commit Haxe, Ruby, and manifest changes together through a recoverable operation.

If recovery is not proven, keep the feature dry-run-only.

### 9. Prove PostgreSQL and MySQL profiles

Run the same state oracle with pinned PostgreSQL and MySQL versions.

Publish only the operation and adapter combinations that pass.

### 10. Update security, support, and release claims

Name `ExecuteSql` and `DataMigration` in the escape-hatch audit and policy gate.

Document all rejected Ruby forms and the no-execution rule.

Do not use broad phrases such as “infer migration history” or “import Rails migrations.”

Publish adoption only after the named adapter profiles and rollback tests pass.

## First tracer migration

The first fixture adds one `status` string column and one named index to `widgets`.

The source uses `ActiveRecord::Migration[7.1]`. All names, options, defaults, and operation order are literals.

The pre-state contains an existing row. The runtime test compares that row and a new row after migration.

The rollback test removes the column, index, and migration version. It also restores the original row state.

This fixture is intentionally small. It proves the complete path before the operation catalog expands.

## Verification performed during reconciliation

The Oracle performed static inspection only. It did not run repository or Rails tests.

Local inspection used the current checkout and the pinned Rails reference:

```text
rg -n "RemoveIndexByName|RemoveForeignKeyByName|ChangeTable" \
  std/rails/migration/MigrationOperation.hx \
  src/reflaxe/ruby/RubyCompiler.hx

sed -n '250,330p' \
  ../haxe.compilerdev.reference/rails/activerecord/lib/active_record/migration/command_recorder.rb
```

The pinned Rails reference revision matched the Oracle bundle:

```text
43a1f3b574cceafcd78d288a1339e37711cf79c7
```

The installed Rails runtime produced these results:

```text
index_name_only:ActiveRecord::IrreversibleMigration
remove_index is only reversible if given a :column option.

foreign_key_name_only:ActiveRecord::IrreversibleMigration
remove_foreign_key is only reversible if given a second table
```

No runtime test yet proves the mixed `ChangeTable` correction. The rollback-correction Bead must add that regression before closure.

No adoption parser, ownership transfer, or adapter profile is implemented by this review.

## Unresolved decisions

The parser task must compare the existing Ripper-based adoption code with a source-location parser such as Prism.

The adapter-profile task must select exact PostgreSQL and MySQL versions. SQLite currently uses the repository-supported `2.9.6` line.

Public constructor names remain open until the exact Rails option mapping passes focused runtime tests.

The ownership-transfer task must prove recovery. Until then, the public command remains dry-run-only.

Compiler drift for an unchanged adopted migration must stop with a review-required diagnostic. It must not rewrite historical Ruby silently.
