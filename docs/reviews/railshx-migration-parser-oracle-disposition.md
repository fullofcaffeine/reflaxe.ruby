# RailsHx migration-parser Oracle disposition

Status: accepted local implementation plan. Current implementation and closure
evidence are tracked by `haxe_ruby-zsf.5`.

Oracle request: `orq_20260824T151315Z_2b43f048`

Oracle input revision: `7a7b3e294e957be8e3783001a1bbdff6e4af7768`

Local reconciliation revision: `7a7b3e294e957be8e3783001a1bbdff6e4af7768`

Oracle model: GPT-5.6 Pro. Local processor: `gpt-5.6-sol` at `xhigh` reasoning.

## Local baseline

The accepted authority permits one selected migration under `db/migrate`.
The complete file must match a closed Ruby grammar without execution.

The grammar permits an ordered sequence of calls from two operation families.
Those families are `add_column` and `add_index`. It does not set an exact count.

The first tracer uses one `add_column` call followed by one `add_index` call.
The tracer does not narrow the catalog to those two exact occurrences.

`MigrationOperation` already owns the public semantic boundary. Its relevant
constructors are `AddColumn(table, name, StringColumn(options))` and
`AddIndex(table, column, options)`.

`RubyCompiler` already lowers both constructors to ordinary ActiveRecord calls.
It maps `defaultValue` to `default`, `nullable` to `null`, and `name` to the
index name.

`MigrationInventory` currently owns the safe file-read code. It uses Ripper to
report facts, but it does not validate operation arguments or build a candidate.

The current reader checks the path before and after opening. It does not check
the path identity again after the read, and it does not reject hard links.

The `hxruby` gem currently has no runtime dependencies. An executable release
contract rejects every `add_runtime_dependency` entry and the installation guide
states that the gem has no runtime dependencies.

Canonical CI runs the complete suite on Ruby 3.3, 3.4, and 4.0. The verified
platform is Ubuntu 24.04 on `x86_64`.

The local Ruby 3.4.10 installation contains Prism 1.9.0. The exact gem activates
successfully and accepts `Prism.parse(source, version: "3.3")`.

Prism 1.9.0 declares Ruby `>= 2.7.0` and includes a native extension. Local
success does not prove the three canonical Ruby lanes or packaged consumption.

The Oracle inspected the same Git revision. It performed a static review and
did not run repository, package, Bundler, or Rails tests.

## Oracle claim matrix

| Oracle claim | Disposition | Local evidence and consequence |
| --- | --- | --- |
| Pin Prism at exactly `1.9.0`. | Retained | Parser behavior and node locations authorize untrusted source. An exact toolchain pin prevents silent parser drift. |
| Parse Ruby syntax version `3.3`. | Retained | This gives all supported Ruby hosts one source grammar. |
| Use parser ID `railshx-migration-prism-v1` and catalog ID `railshx-migration-catalog-v1`. | Retained | Separate identities let parser implementation and admitted operations change independently. |
| Fail when exact Prism is absent or a different version is active. | Retained | A bundled version, compatible range, or Ripper fallback would use an unqualified parser. |
| Make Prism an exact `hxruby` runtime dependency. | Retained as a toolchain exception | The gem package must install the parser version that makes admission decisions. The dependency must stay lazy for unrelated `hxruby` use. |
| Extract one `MigrationSourceReader`. | Retained | Inventory and selected parsing must not own separate security-sensitive file readers. |
| Give the parser only validated source bytes. | Retained | The parser must not reopen a path or read different bytes. |
| Recheck file identity after the bounded read. | Retained | This closes the current path-replacement gap during the read. |
| Require `File::NOFOLLOW` and reject multiply linked files. | Retained with a precise boundary | The selected-parser feature fails closed when the platform cannot provide `NOFOLLOW`. A link count other than one is outside the file-authority contract. |
| Reject RailsHx-owned source in the parser. | Modified | The adoption command rejects an already owned input. The parser stays ownership-neutral because the next task parses generated RailsHx Ruby through the same grammar. |
| Use a private immutable candidate and two nominal operation cases. | Retained | The values mirror the existing Haxe constructors without creating a public migration IR. |
| Store generated Haxe and Ruby hashes in a separate dry-run record. | Retained | Parser output cannot contain hashes for artifacts that do not exist yet. The next Bead owns that evidence. |
| Build the candidate only after complete validation. | Retained | A rejected file must expose no candidate or accepted prefix. |
| Include file identity, normalized operations, and spans in the candidate ID. | Modified | A versioned hash of path, source digest, parser ID, and catalog ID is sufficient. Device and inode values are unstable and must not enter durable identity. |
| Add complete token coverage as a second grammar. | Rejected | Exhaustive AST validation owns semantic syntax. Narrow Prism lexical checks own directives, data sections, embedded documents, heredocs, and semicolons. A parallel token parser would duplicate policy. |
| Validate every consequential AST field without a generic fallback. | Retained | Each admitted node gets one explicit validator. Unknown nodes, receivers, blocks, arguments, and options reject the file. |
| Admit exactly one `add_column` followed by one `add_index`. | Rejected | The accepted authority permits sequential calls from the catalog and requires order preservation. The implementation accepts one or more valid calls in source order. |
| Reject every alternate literal spelling. | Modified | Semantic node shape is authoritative unless the accepted contract excludes a spelling. Static strings remain literals. Interpolation, heredocs, computation, and unsupported option shapes reject. |
| Use strict segmented snake case for names and filenames. | Retained | The current broader pattern can map distinct names to one class. One shared rule prevents this collision. |
| Use half-open byte spans and byte columns. | Retained | Exact bytes are the source authority. Tests must cover multibyte comments and different line endings. |
| Reject parser warnings and return one stable earliest diagnostic. | Retained | The command must fail closed with a deterministic location and no raw parser exception. |
| Add deep-nesting and high-token-count cases before adding a subprocess. | Retained | These cases characterize the pinned native parser. Process isolation is unnecessary unless a reproducible failure requires it. |
| Prove source, built-gem, Bundler, and Rails use on Ruby 3.3, 3.4, and 4.0. | Retained | Local Ruby 3.4 evidence cannot qualify the supported matrix or the native dependency. |
| Add a renderer or generated Haxe in this task. | Rejected | `haxe_ruby-zsf.6` owns dry-run rendering and compiler round-trip evidence. |

## Integrated conclusion

The implementation will use Prism 1.9.0 as an exact, lazy gem dependency. It
will parse Ruby syntax version 3.3 without a fallback parser.

One shared reader will return a frozen `ValidatedMigrationSource`. The value
will contain the relative path, basename, exact UTF-8 bytes, size, and digest.

The reader will own directory, path, file type, link, size, NUL, encoding, and
read-race diagnostics. It will read the selected descriptor once.

The parser will own only syntax and catalog validation. It will use explicit
validators for the program, class, superclass, method, operations, arguments,
options, and literal values.

Prism AST shape will own the semantic grammar. Narrow lexical checks will
reject forms with separate source effects or explicit policy exclusions.

The parser will accept one or more receiverless `add_column` and `add_index`
calls. It will preserve their order and allow each catalog operation more than
once.

The initial tracer remains one string column and one named index. Additional
focused tests will prove repeated calls and the opposite order.

The private candidate will contain source provenance, profile identities,
ordered operations, exact spans, comment facts, and one stable candidate ID.
It will contain no Prism objects, open files, mutable collections, or generated
artifact hashes.

The candidate ID will hash a versioned canonical record. That record contains
the relative path, source digest, parser ID, and catalog ID.

The adoption command will reject an already RailsHx-owned selected source. The
internal parser will remain usable for the generated-Ruby round trip in the
next Bead.

The gemspec, release contracts, installation guide, compatibility matrix, and
package checks will describe the exact Prism dependency. Plain
`require "hxruby"` will not eagerly load Prism.

## Verification and unresolved gaps

The local reconciliation verified the accepted authority, reader, public Haxe
operations, compiler mappings, gemspec, release checks, package checks, and CI
matrix at revision `7a7b3e294e957be8e3783001a1bbdff6e4af7768`.

The local Prism probe proved only Ruby 3.4.10 on macOS ARM. It did not prove
the canonical Ubuntu platform or Ruby 3.3 and 4.0.

Implementation must start with a focused test that fails because no parser
exists. The test must record the expected candidate and a non-execution case.

Focused evidence must cover every admitted operation shape and representative
unknown nodes, calls, values, options, branches, SQL, helpers, paths, bytes,
links, locations, and resource limits.

Canonical CI must prove the same normalized candidate and source spans on Ruby
3.3, 3.4, and 4.0. It must also prove exact dependency activation.

The built-gem test must install Prism 1.9.0 through the gem dependency. It must
run the parser from an isolated installed package and a Bundler Rails process.

This document records the review decision at its input revision. It does not
claim current implementation or closure status. The Bead and exact-SHA release
evidence own those changing facts.
