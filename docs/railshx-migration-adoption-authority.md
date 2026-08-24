# RailsHx migration adoption authority

Status: accepted contract. The bounded report-only inventory and private closed
parser are implemented. The dry-run translator, database parity proof, and
ownership transfer are not implemented yet.

This contract defines how RailsHx can later adopt one Rails-owned migration.
It does not authorize broad migration import or history inference.

## Source authority

The selected Ruby file remains authoritative until an ownership transfer
finishes successfully. Current models, `db/schema.rb`, and database metadata
cannot replace that historical source.

RailsHx must never load, require, evaluate, or run the selected file during
inventory, parsing, or translation. It can run the original migration only in
a separate disposable database test.

The existing `MigrationOperation` family remains the public semantic boundary.
The existing Ruby compiler remains the only Ruby emitter. Adoption must not add
a general migration IR or a second emitter.

## One-file input boundary

The initial parser accepts one explicit path under `db/migrate`. It does not
scan and translate a directory.

The selected input must meet all these rules:

- The path is relative to the Rails application root.
- Its normalized path stays inside `db/migrate`.
- The file name has a 14-digit timestamp and a segmented snake-case migration
  name. Each segment starts with a lowercase letter and can then contain
  lowercase letters or digits.
- The path resolves to one regular file, not a link or special file.
- The file is at most 1 MiB and contains valid UTF-8 without NUL bytes.
- The parser reads the exact bytes once and records their SHA-256 digest.

Any path, size, encoding, or file-type failure rejects the input before
parsing. The tool must not follow a changed link or alternate path.

## Closed initial Ruby grammar

The complete file must match this shape:

```ruby
class AddStatusToWidgets < ActiveRecord::Migration[7.1]
  def change
    add_column :widgets, :status, :string, default: "pending", null: false
    add_index :widgets, :status, name: "index_widgets_on_status"
  end
end
```

The initial grammar permits:

- blank lines and Ruby line comments;
- one top-level class with no namespace;
- the exact superclass `ActiveRecord::Migration[7.1]`;
- one parameterless instance method named `change`;
- one or more sequential bare calls from the initial operation catalog;
- symbol literals for table, column, and column-type names;
- string and Boolean literals for the admitted options;
- safe snake-case database names and a CamelCase class matching the file name.

The parser rejects the complete file when any other syntax appears. Rejected
forms include extra classes, modules, methods, receivers, variables, other
constant references, interpolation, branches, loops, blocks, rescue, callbacks,
SQL, and helper calls.

The parser uses exact Prism `1.9.0` with the Ruby `3.3` syntax profile. Its
identity is `railshx-migration-prism-v1`. The catalog identity is
`railshx-migration-catalog-v1`. There is no fallback parser.

Exhaustive Prism node validation owns the grammar. Narrow token checks reject
forms such as semicolons, heredocs, embedded documents, and `__END__` sections.
Regular expressions do not establish the Ruby grammar.

## Initial operation catalog

The first catalog contains only these operations:

| Ruby source | Existing Haxe operation | Admitted values |
| --- | --- | --- |
| `add_column` | `AddColumn` with `StringColumn` | One table symbol, one column symbol, exact type `:string`, optional string `default`, and optional Boolean `null` |
| `add_index` | `AddIndex` | One table symbol, one column symbol, and one required literal `name` |

The parser accepts one or more calls from this catalog. Calls can repeat and
can occur in either order. It preserves their source order. It rejects unknown
options, duplicate options, splats, arrays, computed values, and overloaded
call shapes.

This catalog exists to prove one tracer migration. Later work can add one
operation shape at a time with focused static and runtime evidence.

## Comment policy

Comments are parsing trivia, not adopted semantics. The dry-run report must
count source comments and state that generated Haxe omits them.

The initial grammar rejects shebangs and Ruby magic comments, including
encoding and frozen-string directives. This keeps comments from changing how
the admitted source parses or behaves.

An author can restore useful comments during review. RailsHx must not guess
which comments describe behavior, ownership, or obsolete history.

## Compatibility and adapter profiles

`ActiveRecord::Migration[7.1]` is the first source compatibility profile. It
defines the admitted superclass and operation meanings. It is not a claim that
RailsHx supports every Rails 7.1 migration form.

| Profile | Initial role | Publication state |
| --- | --- | --- |
| ActiveRecord migration 7.1 with Rails/ActiveRecord 8.1.3.1 and SQLite `sqlite3` 2.9.6 | Static round trip and first behavioral oracle | Not qualified until the SQLite tracer passes |
| ActiveRecord migration 7.1 with PostgreSQL | Later adapter oracle | Disabled and unclaimed |
| ActiveRecord migration 7.1 with MySQL | Later adapter oracle | Disabled and unclaimed |

The SQLite profile separates source compatibility from execution. Rails 8.1.3.1
executes a migration that declares the 7.1 compatibility API. A portable claim
requires separate PostgreSQL and MySQL proof with exact pins.

## Dry-run contract

Dry-run is the only permitted public translation mode until recoverable
ownership transfer has independent tests. The existing
`hxruby:adopt --migrations --discover` command remains an inventory report. It
does not translate migrations.

The inventory reads each top-level `.rb` entry under `db/migrate` once as
bounded UTF-8 source data. It reports the safe relative path, SHA-256 digest,
timestamp, class names, migration version, transaction marker, body form,
comment count, ownership, and first unsupported structural construct. It
rejects links, non-regular files, NUL bytes, invalid UTF-8, and files over 1
MiB. It uses Ruby's syntax tree for structural facts and never loads or runs
the migration source.

A future dry run must:

1. Read and parse one selected Ruby file without execution.
2. Build one private immutable candidate from admitted source facts.
3. Render Haxe that uses existing `MigrationOperation` values.
4. Compile that Haxe through the existing Ruby compiler in a temporary root.
5. Parse the generated Ruby with the same closed grammar.
6. Compare normalized operation order, values, and options.
7. Show the Haxe output, Ruby diff, omissions, and all profile identities.

Dry-run must not modify the application, migration file, ownership manifest,
or generated-output tree.

## Candidate and provenance

The private parser candidate records only facts needed for later translation:

- normalized source path and exact source SHA-256;
- migration timestamp, class, and compatibility profile;
- admitted operations with source spans;
- comment count and omission notice;
- parser, parser-version, Ruby-syntax, and catalog identities; and
- a candidate identifier derived from the versioned source path, source digest,
  parser identity, and catalog identity.

The parser candidate does not contain generated Haxe, generated Ruby, compiler,
or adapter hashes. The dry-run record in the next task owns those facts. A
rejection returns one located diagnostic and no partial candidate. The
candidate is not a public general-purpose migration representation.

## Behavioral tracer

The first fixture adds a `status` string column and a named index to `widgets`.
The column uses a literal default so old and new row behavior can be compared.

The original Ruby and generated Ruby run against separate disposable SQLite
databases. The test compares:

- final columns, types, defaults, nullability, and indexes;
- an existing row and a row inserted after migration;
- the recorded migration version;
- the second-run skip behavior;
- the complete rollback state.

The static round trip and runtime comparison are independent oracles. A parser
snapshot or generated-text golden alone cannot qualify adoption behavior.

## Future ownership handoff

A future transfer must require the reviewed candidate identifier and source
digest. It must re-read every input immediately before any mutation.

The transfer must fail if source, destination, manifest, compiler, parser,
catalog, or generated bytes differ from the reviewed candidate. Generic
`--force` cannot bypass any mismatch.

The transfer must stage the Haxe source, generated Ruby, and ownership manifest
together. It can mark RailsHx ownership only after a recoverable commit of all
three artifacts.

If interruption recovery and rollback are not proven, the feature must remain
dry-run-only. The Rails-owned source must stay unchanged after every failed
attempt.

## Compiler drift

The ownership manifest binds an adopted migration to its reviewed Haxe and Ruby
digests. A later compiler that produces different Ruby must stop before writing
the historical migration.

The diagnostic must identify the migration and require review. A separate
review flow can accept new generated bytes only after static equivalence and
the applicable runtime oracle pass again.

RailsHx must never rewrite an adopted historical migration silently. This rule
applies even when the Haxe source and original candidate digest did not change.

## Claim boundary

This contract and the focused parser evidence justify one private, closed,
non-executing parser. They do not claim that migration adoption works today.

Public documentation must avoid broad phrases such as "infer migration
history" or "import Rails migrations." Each future claim must name its exact
grammar, operation catalog, compatibility profile, adapter profile, and runtime
evidence.

See the retained architecture decisions in
[`reviews/railshx-migration-history-oracle-disposition.md`](reviews/railshx-migration-history-oracle-disposition.md)
and the parser-specific review disposition in
[`reviews/railshx-migration-parser-oracle-disposition.md`](reviews/railshx-migration-parser-oracle-disposition.md).
