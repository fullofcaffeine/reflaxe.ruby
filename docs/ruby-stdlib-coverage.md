# Ruby Stdlib Coverage Catalog

RubyHx publishes a versioned, machine-readable catalog at
[`lib/hxruby/stdlib_coverage.json`](../lib/hxruby/stdlib_coverage.json). It
records the bounded Ruby core and standard-library domains the project has
selected, how each library is distributed on every supported MRI branch, which
typed `ruby.*` facades exist, and which mandatory gates own their evidence.

The catalog is deliberately domain-level and curated. An
`implemented-public` entry means the listed facade surface is implemented and
tested; it does not claim every class or method in that Ruby library, the whole
Ruby standard library, or platform support beyond the compatibility matrix.

## Contract And Classifications

The catalog consumes the supported Ruby branches directly from
[`lib/hxruby/support_matrix.json`](../lib/hxruby/support_matrix.json). CI rejects
branch drift between the two files. Each domain has exactly one distribution
classification per supported branch:

| Classification | Meaning |
| --- | --- |
| `core` | Available without a separate require or gem contract. |
| `standard-library` | Shipped with Ruby but not represented by a default or bundled gem specification. |
| `default-gem` | Shipped as a default gem and independently upgradeable. |
| `bundled-gem` | Installed as an ordinary gem by the tested Ruby distribution; do not infer availability in every minimal Ruby installation. |
| `platform-specific` | Availability depends on the host OS or architecture and is outside the canonical cross-platform promise. |

Coverage status is independent of distribution. `implemented-public`,
`implemented-internal`, and `implemented-convenience` entries own real facade
files and mandatory evidence. `planned` and `deferred` entries claim neither.
This separation records transitions such as `csv`: it is a default gem on MRI
3.3 and a bundled gem on MRI 3.4/4.0, while its typed facade remains planned.
It also records Ruby 4.0's promotion of `Pathname` and `Set` from default gems
to core classes instead of freezing their Ruby 3.x ownership model.

Run the catalog gate with:

```bash
npm run test:ruby-stdlib-coverage
```

The gate proves that:

- catalog branches exactly match the packaged support matrix;
- every declared classification and status has a fixed meaning;
- every maintained `std/ruby/**/*.hx` facade outside `_std` is owned exactly
  once, and every implemented catalog path exists;
- implemented domains name mandatory compile/runtime evidence while planned or
  deferred domains cannot claim a surface;
- the active supported MRI can require each selected library, resolve its
  constants, and observe the expected core/default/bundled/stdlib
  classification; and
- platform-only probes run only on their matching host. A Ruby branch newer
  than the tested matrix receives a warning and schema validation, not an
  unsupported compatibility rejection or a fabricated runtime claim.

The JSON ships in both the Haxelib ZIP and `hxruby` gem. Consumers and tooling
can therefore inspect the same catalog that canonical CI validated.

## First RBS-Reviewed Slice: URI

`ruby.URI` and `ruby.URIValue` are the first public facade added under this
catalog. They provide typed parsing, bounded two-reference joining, form and URI
component codecs, common nullable components, URI predicates, merging,
relative routing, normalization, and string conversion. Both types emit a
deduplicated `require "uri"` and direct native calls:

```haxe
var base = ruby.URI.parse("https://example.com/app/");
var endpoint = base.merge("api/items?q=typed");

ruby.Kernel.puts(endpoint.host());
ruby.Kernel.puts(endpoint.toString());
ruby.Kernel.puts(ruby.URI.encodeComponent("a b/c"));
```

```ruby
require "uri"

base = URI.parse("https://example.com/app/")
endpoint = base.merge("api/items?q=typed")
Kernel.puts(endpoint.host)
Kernel.puts(endpoint.to_s)
Kernel.puts(URI.encode_uri_component("a b/c"))
```

The checked contract was reviewed against the official `ruby/rbs` `v4.0.3`
`stdlib/uri/0` signatures. The catalog pins the reviewed `common.rbs` and
`generic.rbs` SHA-256 values and records the curation boundary. Ruby's open
conversion protocols, enumerable form encoding, optional encoding arguments,
variadic calls, mutation, and scheme-specific APIs are omitted rather than
widened. `URI.parse` returns scheme-specific subclasses at runtime;
`ruby.URIValue` truthfully models their shared `URI::Generic` base.

The URI facade remains a reviewed, curated contract rather than an unchecked
generated dump. RubyHx now packages the strict deterministic foundation
documented in [Deterministic RBS-To-Haxe Generation](rbs-to-haxe-generator.md):
it can parse the precise scalar/nilable/array subset, emit a canonical nominal
extern, and mark or reject unsupported shapes without a broad fallback type.
That infrastructure does not retroactively claim every URI signature, make
generated text public without review, or add coverage for another library.
Generated contracts still require compilation, curation, MRI runtime evidence,
and explicit handling of signatures that Haxe cannot model precisely.

## Updating The Catalog

For each new domain:

1. Establish its distribution on every branch in the support matrix. Do not
   treat a bundled gem as a default-gem guarantee.
2. Add a sorted domain entry with a bounded note and runtime probe. Use
   `planned` until facade files and mandatory evidence exist.
3. Prefer precise externs and nominal values that emit direct Ruby. Keep open
   arguments, uncertain overloads, and scheme-specific behavior out until they
   have a truthful typed contract.
4. Record each new `std/ruby` file in both this coverage catalog and
   `docs/stdlib-inventory.json`.
5. Add compile, generated-shape, and MRI runtime evidence, then run the catalog,
   ownership, package, full example, Rails runtime, browser, and production
   gates required by the repository regression contract.

`CSV`, `Open3`, and `Set` are recorded as planned next domains. Their presence
in the catalog is prioritization and availability evidence, not public API
support.
