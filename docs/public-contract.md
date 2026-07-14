# RubyHx/RailsHx Public Contract

This is the proposed compatibility contract for stable `1.x`. Until stable
major approval, releases remain `0.x`, but changes should already be evaluated
against these boundaries so `1.0` does not freeze accidental internals.

## Contract Principles

- The compatibility matrix is the set the project continuously verifies and
  maintains. It is not an upper limit on conventional generated Ruby or Rails
  artifacts. Newer Ruby/Rails lines may work and warn as unverified; a hard
  upper bound needs a reproduced incompatibility.
- Haxe/HHX source, documented Ruby-callable shapes, and generated-artifact
  ownership are the stable inputs and boundaries. Exact private formatting in
  disposable generated output is not an API.
- The public inventory stays federated in the machine-checked sources that own
  each surface. A second monolithic list would duplicate those sources and
  create another place to drift.

## Public Surfaces

| Surface | Stable treatment | Authoritative inventory and evidence |
| --- | --- | --- |
| Package identities and install layout | `reflaxe.ruby`, `hxruby`, public Haxe import paths, and documented package entrypoints are SemVer-governed. | `haxelib.json`, `hxruby.gemspec`, Haxelib/gem package-consumer checks, and release artifact manifests |
| Profiles and build inputs | `ruby_first`, `portable`, their documented compatibility aliases, and documented end-user defines are public. | [Profiles](profiles.md), profile resolver tests, and package examples |
| Ruby/Rails authoring metadata | Documented `@:ruby*` and `@:rails*` metadata is public; compiler handoff metadata explicitly marked internal is not. | [Compiler Metadata](compiler-metadata.md) and `npm run test:compiler-metadata-docs` |
| Ruby and Rails typed APIs | Documented public modules under `ruby.*`, `rails.*`, and the supported companion boundary are public source APIs. | `docs/stdlib-inventory.json`, `npm run test:stdlib-inventory`, compiler examples, and runtime lanes |
| Ruby-callable generated ABI | Documented constants, methods, blocks, keywords, rest arguments, exceptions, and inheritance shapes consumed by handwritten Ruby are public behavior. | [Ruby Callable ABI](ruby-callable-abi.md) and its executable Ruby-origin/Haxe-origin gates |
| Runtime ABI | Helpers called by generated code are a compiler/runtime package ABI. Compiler and packaged runtime changes must remain mutually compatible; helpers are not general app APIs unless separately documented. | runtime usage/minitest gates plus Haxelib/gem consumer checks |
| User commands | Documented `hxruby:*`, Rails generator, package verification, doctor, check, clean, and production commands are public command surfaces. | Rake task registration, generator docs, and installed-gem task checks |
| Versioned data | Ownership manifest v1, support-matrix JSON, route/schema inventories, and release sidecars keep their documented readers and fail-closed version rules. | schema-specific docs, validators, package tests, and release contracts |
| Diagnostics | Fail-closed behavior, source positioning, and actionable remediation are public. Exact prose and compiler-private diagnostic implementation are not machine-parsing APIs. | negative compile fixtures, doctor/check tests, and [Debugging](debugging.md) |

## Internal Surfaces

The following may change in a patch or minor release when public behavior and
migration guidance remain intact:

- compiler-private functions, services, temporary metadata, and vendored file
  layout;
- exact whitespace, private locals, and other incidental generated formatting;
- snapshot names, CI script names, and repository-only task composition;
- generated helpers or artifact fields explicitly documented as internal.

Readable generated Ruby remains an inspectable debugging unit. That does not
make every emitted byte or private helper name a handwritten-Ruby API.

## Versioning And Deprecation

- A compatible bug or security fix is a patch. An additive public API or newly
  verified runtime line is a minor. Removing or incompatibly changing a public
  source API, callable/runtime ABI, command, or schema requires a major unless
  an alias or automatic reader preserves existing consumers.
- A public rename or removal normally ships an actionable deprecation in an
  earlier minor release. Existing profile compatibility aliases remain for all
  of `1.x` as documented. Security or correctness emergencies may move faster,
  with the exception and migration called out in release notes.
- Exact diagnostic prose and private generated formatting may improve without
  a major bump; documented error meaning, source ownership, and Ruby-callable
  behavior may not silently change.
- Dropping a verified Ruby/Rails line follows the published support lifecycle.
  Unverified newer versions remain warnings rather than automatic rejection.

Version selection and stable-major approval remain owned by
[Release Version Policy](release-version-policy.md).

## Generated Ownership And Upgrades

`.railshx/manifest.json` version `1` is the only historical ownership schema,
including the public `v0.4.0` line. Current readers require exactly v1 and reject
missing, malformed, or unknown versions before write or cleanup. There is no
generic migration engine because no v2 exists; a future schema change must add
the concrete migrator, backup behavior, and rollback fixture it actually needs.

Manifest-owned generated files are disposable outputs of Haxe/HHX source.
Normal rewrite and `hxruby:clean` first verify recorded checksums so a local edit
cannot be silently replaced or deleted. A generator's explicit `--force` can
replace a changed output. To keep the edit as Rails-owned source, remove its
manifest entry and generated header in the same reviewed change.

Run the public-baseline rehearsal with:

```bash
npm run test:public-upgrade
```

The canonical lane downloads and checksum-verifies the immutable public
`v0.4.0` Haxelib ZIP and gem, runs a packaged Haxe consumer, upgrades both
package types to artifacts built from the current Git tree, and rolls them back.
It also proves the v1 ownership manifest round-trip leaves handwritten app
source unchanged. This is a representative package/ownership contract, not a
claim that every application or future Rails release needs no application-level
upgrade testing.
