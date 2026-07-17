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
3.3 and a bundled gem on MRI 3.4/4.0. Its typed facade is implemented for the
tested distributions, but that does not promise a bundled gem in arbitrary
minimal Ruby installations.
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

## Second Reviewed Slice: CSV

`ruby.CSV` provides a bounded header-free CSV contract over nullable string
rows. `ruby.CSVRow` is `Array<Null<String>>`, preserving Ruby's important
distinction between an unquoted missing field (`null`) and a quoted empty field
(`""`). The facade covers single-line and whole-string parsing, file reads,
native block iteration, and single/multi-row generation:

```haxe
var rows = ruby.CSV.parseRows("name,value\nalpha,1\n");
ruby.CSV.forEachRow("imports/users.csv", row -> {
	ruby.Kernel.puts(row[0]);
});

var output = ruby.CSV.generateRows([["alpha", "1"], ["beta", null]]);
```

```ruby
require "csv"

rows = CSV.parse("name,value\nalpha,1\n")
CSV.foreach("imports/users.csv") { |row| Kernel.puts(row[0]) }
output = CSV.generate_lines([["alpha", "1"], ["beta", nil]])
```

Typed `CSVParseOptions` and `CSVGenerateOptions` expose only
string-preserving separators, quoting controls, parser field limits, blank-row
handling, stripping, and liberal parsing. `maxFieldSize` maps to Ruby's
`max_field_size` and lets applications bound look-ahead for unterminated quoted
fields. Header/table modes, converters, open IO, file modes, encodings,
arbitrary field objects, replacement objects, and unchecked keyword bags are
omitted because they change the result type or widen the boundary.

The checked contract pins official `ruby/rbs` `v4.0.3`
`stdlib/csv/0/csv.rbs`. That RBS owns the nullable no-header parse/read/foreach
row types and documents the generation API; its missing singleton definitions
for `generate_line` and `generate_lines` are supplemented by the official Ruby
CSV documentation plus direct MRI runtime evidence. The facade remains a
curated subset, not a claim that all CSV headers, tables, converters, or IO
forms are typed.

## Third Reviewed Slice: Open3

`ruby.Open3` provides capture-only child-process execution without accepting a
shell command line. `Open3Executable.of(path)` privately creates Ruby's
`[path, argv0]` direct-exec form, and Haxe rest arguments lower to a native Ruby
splat. A stored argument list therefore remains concise and shell-free:

```haxe
var arguments = ["-e", "STDOUT.write(ARGV.fetch(0))", "literal;$(not-run)"];
var capture = ruby.Open3.capture(ruby.Open3Executable.of("ruby"), ...arguments);

ruby.Kernel.puts(capture.standardOutput);
ruby.Kernel.puts(capture.status.succeeded());
```

```ruby
require "open3"

capture = Open3.capture3(["ruby", "ruby"], *arguments)
Kernel.puts(capture.first)
Kernel.puts(capture.last.success?)
```

Ruby returns `[String, String, Process::Status]`, a fixed heterogeneous Array.
`Open3Capture` keeps that representation private and permits only the three
reviewed native reads exposed as `standardOutput`, `standardError`, and
`status`. `Open3Status` then provides typed success, exit code, process ID, and
signal information with Ruby's real nullability. Callers cannot index, convert,
or mutate the tuple.

The checked contract pins official `ruby/rbs` `v4.0.3`
`stdlib/open3/0/open3.rbs` and the official `ruby/open3` `v0.2.1` implementation
sources. Shell command strings, environment/process option hashes,
`stdin_data`/`binmode` keywords, `capture2`/`capture2e`, live `popen` streams,
pipelines, and unchecked argument bags remain omitted. This is a precise
capture contract, not a claim that every Open3 process or lifecycle API is
typed.

## Fourth Reviewed Slice: Set

`ruby.Set<T>` provides a generic Ruby-semantic collection without claiming
portable `haxe.ds` behavior. Construction is deliberately limited to a typed
Array, all multi-value operands are same-element `Set<T>` values, and blocks are
explicitly typed and lowered natively:

```haxe
var left = new ruby.Set<String>(["alpha", "beta", "alpha"]);
var right = new ruby.Set<String>(["beta", "gamma"]);

var common = left.intersection(right);
left.forEach(value -> ruby.Kernel.puts(value));
```

```ruby
require "set"

left = Set.new(["alpha", "beta", "alpha"])
right = Set.new(["beta", "gamma"])
common = left.intersection(right)
left.each { |value| Kernel.puts(value) }
```

The facade covers size/empty/membership queries, precise nullable `add?` and
`delete?` results, direct mutation, non-mutating algebra, subset/superset and
intersection relations, Bool-narrowed native filters, block iteration, and
explicit `Array<T>` conversion. Ruby still determines membership through
`eql?` and `hash`; callers must not mutate a stored element's identity, and
Ruby may store a frozen copy of a mutable String.

The checked contract pins official `ruby/rbs` `v4.0.3` `core/set.rbs`, official
`ruby/set` `v1.1.0` and `v1.1.1` implementations for Ruby 3.3/3.4, and the
official `ruby/ruby` `v4.0.0` `set.c` core implementation. Open Enumerable and
variadic inputs, type-changing transforms, classify/divide/flatten, identity
mode, reset, subclass/CoreSet behavior, implicit Haxe iteration, raw operators,
and unchecked values are omitted. The catalog records the Ruby 4.0 promotion
from default gem to core without widening the common tested API.

## Fifth Reviewed Slice: Time and Date

`ruby.Time` is a require-free facade over Ruby's core instant type, while
`ruby.Date` is a separate civil-date facade that emits `require "date"`. Their
shared Haxe authoring style does not erase the native semantic split:

```haxe
import ruby.Date as RubyDate;
import ruby.Time as RubyTime;

var instant = RubyTime.utc(2024, 2, 29, 12, 0, 0).addSeconds(90.5);
var date = RubyDate.parseWithFormat("29/02/2024", "%d/%m/%Y").nextDay();
```

```ruby
require "date"

instant = Time.utc(2024, 2, 29, 12, 0, 0) + 90.5
date = Date.strptime("29/02/2024", "%d/%m/%Y").next_day
```

The Time contract covers concrete epoch/local/UTC construction, one-based
calendar components, zone/offset and daylight-saving reads, non-mutating zone
copies, epoch conversion, `strftime`, and Float seconds arithmetic/difference.
The Date contract covers concrete civil construction, `today`, strict ISO 8601
and explicit-format parsing, calendar/ISO-week components, leap-year queries,
formatting, and integer day/month/year movement. A focused Time-only fixture
proves that core Time does not acquire `require "date"` or `require "time"`.

Both contracts pin official `ruby/rbs` `v4.0.3`: `core/time.rbs` and
`stdlib/date/0/date.rbs`. The catalog also pins the official `ruby/ruby`
implementation sources at `v3_3_11`, `v3_4_10`, and `v4.0.0`, matching the
supported Ruby branches. Open Numeric and timezone protocols, subsecond units,
Rational values, permissive parsing, timezone databases, mutating conversion,
calendar-reform controls, enumerators, and unchecked option bags remain
omitted. `DateTime` is not claimed: upstream documents it as deprecated, and
its useful offset/subsecond contracts require a separate Rational-aware design.

The existing Haxe `Date` override remains a separate Haxe-semantics wrapper
over Ruby Time. Its zero-based months, millisecond epoch, accepted parse forms,
and output formatting are still owned by the Date/DateTools parity suite rather
than by these Ruby-shaped facades. Its generated `HxDate` constant and
`hx_date.rb` filename keep the portable wrapper collision-free when native
Ruby `Date` is loaded in the same program.

## Sixth Reviewed Slice: Strict Time Parsing

`ruby.TimeParsing` is a require-backed native view of the same core `Time`
constant. It maps restricted ISO 8601 and explicit-format parsing directly
while preserving the require-free `ruby.Time` contract:

```haxe
var iso = ruby.TimeParsing.parseIso8601("2026-07-17T12:30:00-06:00");
var formatted = ruby.TimeParsing.parseWithFormat(
  "2026/07/17 12:30 -0600",
  "%Y/%m/%d %H:%M %z"
);
```

```ruby
require "time"

iso = Time.iso8601("2026-07-17T12:30:00-06:00")
formatted = Time.strptime("2026/07/17 12:30 -0600", "%Y/%m/%d %H:%M %z")
```

The catalog records `time` as a default gem on Ruby 3.3, 3.4, and 4.0 and pins
official `ruby/rbs` `v4.0.3` plus the exact supported `ruby/ruby` `lib/time.rb`
sources. Heuristic `Time.parse`, parser blocks, HTTP/mail parsing, DateTime
conversion, open Numeric inputs, and unchecked options remain omitted.

Rails named-zone behavior is not part of this Ruby-library catalog. It lives
in the separate RailsHx layer through `RailsTime`, `TimeZone`, and
`TimeWithZone`; see [Modern Temporal APIs](temporal-apis.md).

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
