# Ruby Stdlib Facades

Ruby stdlib facades let Haxe-authored Ruby code use real Ruby libraries without
falling back to raw `__ruby__`, broad `Dynamic`, or wrapper runtimes. They live
under `std/ruby/**` and should make the generated Ruby look like ordinary
hand-written Ruby wherever the Ruby API already has the desired behavior.

## Naming And Ownership

- Put Ruby-owned library surfaces under the `ruby` package:
  `ruby.Dir`, `ruby.File`, `ruby.FileUtils`, `ruby.Json`, `ruby.Kernel`,
  `ruby.Pathname`, `ruby.Tempfile`, and future `ruby.CSV` or `ruby.URI`
  facades.
- Keep the Haxe class name Haxe-idiomatic when RubyHx owns the authoring
  surface. Use `@:native` to point at Ruby constants with different spelling,
  for example `@:native("JSON") extern class Json`.
- Preserve exact Ruby names through Haxe's built-in `@:native` metadata when
  modeling an existing Ruby API. Do not introduce public lowercase Haxe class
  names just because the Ruby constant is lowercase or acronym-heavy.
- Add `@:rubyRequire("...")` on externs that need a Ruby stdlib require, such as
  `ruby.Json`, so generated output records the dependency instead of relying on
  user glue.
- Keep internal compiler/runtime adapters clearly internal. `ruby.NativeHash`
  and `ruby.NativeIterator` are implementation helpers for target std
  overrides; they are not the model for public app-facing stdlib facades.

## Choosing The Shape

Prefer the narrowest typed surface that still feels useful:

| Need | Shape |
| --- | --- |
| Existing Ruby constant or module method | `extern class` with `@:native` and typed static methods |
| Existing Ruby receiver method | extern, typed patch contract, or compiler direct lowering when it is a Haxe std method |
| Small Haxe-owned convenience | normal Haxe class that delegates to `Sys`/typed std APIs, such as `ruby.Prelude` |
| Ruby value with a small representation boundary | abstract such as `ruby.Symbol` |
| Ruby behavior needed by Haxe std semantics | std override plus direct Ruby or compact `HXRuby` helper only for the semantic gap |
| Framework/gem-specific behavior | RailsHx/gem-layer package, not `std/ruby` core |

A public facade should expose typed parameters and return values whenever the
contract is known. Use `Dynamic` only at a real Ruby boundary, such as
`JSON.parse` before a typed decoder exists, and document or narrow the value
before app logic depends on its shape.

## Coverage Goal

RubyHx should ultimately provide broad typed access to the Ruby core and
standard-library APIs that are available across its supported Ruby matrix. In
Haxe source, these are imported as `ruby.*` types such as `ruby.Pathname`; the
physical `std/ruby` directory is an implementation and packaging detail, not a
package named `@std/ruby`.

Broad coverage does not mean copying every Ruby method by hand or pretending
that every open Ruby contract is statically sound. The coverage program should:

- inventory Ruby core APIs, standard libraries, default gems, bundled gems, and
  platform-specific libraries separately;
- establish the common contract for the supported Ruby versions before adding
  a version-specific API;
- generate conservative low-level contracts from deterministic RBS where that
  is mechanical, then compile, review, document, and runtime-test them;
- curate Haxe-idiomatic names, overloads, blocks, keyword arguments,
  nullability, and return types where a mechanical signature is not sufficient;
- omit an uncertain operation or expose an explicitly named narrow unchecked
  boundary instead of widening a whole facade to `Dynamic`;
- keep Rails and third-party gem APIs in RailsHx, companion packages, or
  generated app-local contracts rather than treating them as Ruby core.

The complete inventory is a useful long-term goal. Stable releases should state
which domains and Ruby versions are covered instead of making an unqualified
"whole stdlib" claim. A smaller precise facade is more valuable than a large
surface whose types do not describe Ruby's actual behavior.

## Relationship To Haxe Std

The public Ruby-native surface and the Haxe std compatibility surface have
different semantic owners:

```text
                       native Ruby constants and methods
                                    |
                   typed externs and narrow target primitives
                              /                 \
                    public ruby.*          std/ruby/_std
                    Ruby semantics          Haxe semantics
                                              |
                                   semantic adapters only
                                   where Ruby behavior differs
```

`std/ruby/_std` is not a second Ruby library API. It implements portable Haxe
types such as `haxe.Json`, `haxe.ds.Map`, `sys.FileSystem`, and `sys.io.File` on
the Ruby target. Those APIs must retain their Haxe contracts even when the most
direct implementation uses Ruby's `JSON`, `Hash`, `File`, `Dir`, or
`FileUtils` underneath.

The preferred implementation rule is:

1. Model a reusable native operation with a precise typed `ruby.*` extern or a
   narrow internal target primitive.
2. Let Haxe std overrides consume that typed operation when its contract is an
   exact fit.
3. Add a small Haxe-semantic adapter when return values, indexing, mutation,
   exceptions, encodings, nullability, blocks, or other behavior differs.
4. Keep the adapter's public result in Haxe std types. Do not leak a
   `ruby.Pathname`, native status value, or Ruby-only exception contract through
   a portable Haxe API.

This means a typed-native-first implementation is desirable for new reusable
domains, but it is not a rigid prerequisite for every Haxe std parity fix. A
private native carrier can be the correct boundary when no useful public Ruby
facade exists, and a compiler lowering can be better than introducing a public
wrapper solely for `_std`. Conversely, a completed public `ruby.*` facade must
not wait for a Haxe std consumer: Ruby-first code is itself a first-class use
case.

The two branches should share typed native contracts where doing so removes raw
target access and duplication. They should not be collapsed into one public API.
`ruby.*` answers "what does Ruby do?" while Haxe std answers "what does this
Haxe API promise on every target?"

## Direct Ruby First

When Ruby behavior matches the Haxe/RubyHx contract, emit the Ruby call directly:

```haxe
import ruby.Kernel;

Kernel.puts("ready");
```

This should lower to an ordinary Ruby call against `Kernel`, not an `HXRuby`
wrapper. The same rule applies to compiler-special lowerings for Haxe std
methods: `Array.concat` can become `left + right`, `Array.contains` can become
`include?`, and `Array.copy` can become `dup` because those Ruby calls preserve
the required behavior.

`Kernel.puts` and `Kernel.print` use method-level generics instead of
`Dynamic`: each call preserves the caller's precise Haxe value type while the
extern still maps directly to Ruby's open-value Kernel API. The generic does
not grant field access or leak an unchecked value into application code.

Use an `HXRuby` helper only when Ruby would drift from the documented Haxe
semantics. Examples include numeric-prefix parsing for `Std.parseInt`,
Haxe-specific stringification for `Std.string`, portable `Array.join`, string
UTF-16 overlap behavior, enum/type reflection, and array boundary methods such
as `slice`, `splice`, `indexOf`, and `lastIndexOf`.

## Facade Examples

Direct Ruby extern:

```haxe
package ruby;

@:native("File")
extern class File {
	public static function read(path:String):String;
}
```

Ruby stdlib require:

```haxe
package ruby;

@:rubyRequire("json")
@:native("JSON")
extern class Json {
	public static function parse(input:String):Dynamic;
}
```

Opt-in Ruby-flavored convenience:

```haxe
import ruby.Prelude.puts;

puts("typed output");
```

`ruby.Prelude.puts` intentionally delegates to `Sys.println`, so it keeps
RubyHx/Haxe stringification semantics. Use `ruby.Kernel.puts` when the goal is
exact Ruby Kernel interop.

### Pathname

`ruby.Pathname` is the canonical typed facade for Ruby's stdlib-owned Pathname
value. It exposes Haxe-idiomatic names for construction, path composition and
decomposition, cleaning/expansion, relative-path calculation, parent/children,
read-only filesystem predicates, and bounded reads:

```haxe
var base = new ruby.Pathname("/srv/app");
var entry = base.join("lib").join("entry.rb");

ruby.Kernel.puts(entry.relativeTo(base).toPath()); // lib/entry.rb
ruby.Kernel.puts(entry.baseName().toPath());       // entry.rb
ruby.Kernel.puts(entry.extension());               // .rb
```

The generated Ruby stays target-native:

```ruby
require "pathname"

base = Pathname.new("/srv/app")
entry = base.join("lib").join("entry.rb")
Kernel.puts(entry.relative_path_from(base).to_path)
```

Ruby's constructor and variadic methods can accept arbitrary `to_path` objects,
but the canonical Haxe surface deliberately accepts `String` or `Pathname`
where modeled. Multiple segments use chained `join(...)` calls. This keeps
completion and diagnostics precise and avoids introducing `Dynamic`, casts, raw
Ruby, splat lowering, or a wrapper solely to mirror an open Ruby argument list.
`ruby.Pathname` is Ruby-shaped interop; it does not replace portable
`haxe.io.Path`, whose parsing/normalization contract remains Haxe-owned.

### Dir

`ruby.Dir` is the canonical typed facade for Ruby's core `Dir` class. It covers
current-directory lookup and explicit changes, home-directory lookup, entries,
children, one-pattern globbing, and directory existence/emptiness predicates:

```haxe
var original = ruby.Dir.current();
var sources = ruby.Dir.glob("std/ruby/*.hx");

if (ruby.Dir.exists("std")) {
	ruby.Kernel.puts(sources.length);
}

ruby.Dir.changeCurrent("std");
ruby.Dir.changeCurrent(original);
```

The generated Ruby calls the core constant directly and adds no require:

```ruby
original = Dir.pwd()
sources = Dir.glob("std/ruby/*.hx")

if Dir.exist?("std")
  Kernel.puts(sources.length)
end

Dir.chdir("std")
Dir.chdir(original)
```

`changeCurrent(...)` is intentionally named as a process operation: Ruby
`Dir.chdir` changes process-wide state when it is called without a block. The
facade returns Ruby's integer status and does not pretend to provide scoped
restoration; callers must save `current()` and restore it explicitly.

Ruby also accepts block-returning `chdir`, encoding and keyword options,
multiple glob patterns, and other open forms. They are excluded from this
bounded surface rather than represented with `Dynamic`, casts, raw Ruby, or a
wrapper. Future additions should introduce distinct typed contracts for those
shapes. `ruby.Dir` is Ruby-shaped interop and stays separate from Haxe-owned
`sys.FileSystem` semantics.

### FileUtils

`ruby.FileUtils` is the canonical typed facade for Ruby's standard-library
`FileUtils` module. Its first contract deliberately accepts one `String` path
per source/destination slot and exposes Haxe-idiomatic names for copying,
moving, directory creation, file and empty-directory removal, secure recursive
removal, touching, content comparison, and freshness checks:

```haxe
var created = ruby.FileUtils.makeDirectories("tmp/build/assets");
ruby.FileUtils.copyFile("README.md", "tmp/build/README.md");

if (ruby.FileUtils.sameContents("README.md", "tmp/build/README.md")) {
	ruby.Kernel.puts(created[0]);
}

ruby.FileUtils.secureRemoveTree("tmp/build");
```

The generated Ruby requires the real stdlib module and dispatches directly:

```ruby
require "fileutils"

created = FileUtils.mkdir_p("tmp/build/assets")
FileUtils.cp("README.md", "tmp/build/README.md")

if FileUtils.compare_file("README.md", "tmp/build/README.md")
  Kernel.puts(created[0])
end

FileUtils.remove_entry_secure("tmp/build")
```

Creation, touch, and non-recursive removal methods return `Array<String>`
because Ruby normalizes a single path into a one-element path list. Copy and
move operations intentionally return `Void`: their native return values are
either `nil` or undocumented implementation status, so app code should depend
on the filesystem result rather than an unstable value. `sameContents(...)`
and `isUpToDate(...)` retain their native `Bool` contracts.

Recursive deletion is security-sensitive. Ruby documents a local TOCTTOU risk
for `rm_r`/`rm_rf` under attacker-writable parent directories, so the canonical
facade omits those shortcuts and exposes
`secureRemoveTree(path, ?ignoreErrors)` over
`FileUtils.remove_entry_secure`. Passing `true` explicitly requests Ruby's
force behavior and can suppress errors beyond a missing path.
`forceRemoveFile(...)` similarly makes `rm_f` error suppression visible in the
Haxe name. Use force only when intentionally accepting that loss of diagnostic
information.

Ruby's list-input, keyword, symlink, ownership, permission, install, and block
forms remain excluded rather than represented through `Dynamic`, casts, raw
Ruby, or a wrapper. Future additions should use distinct typed option records
or methods where their semantics justify the extra surface. As with `ruby.Dir`,
this is Ruby-shaped interop and does not replace Haxe `sys.FileSystem`.

### Tempfile

`ruby.Tempfile` is the canonical typed lifecycle facade for Ruby's
standard-library `Tempfile`. Normal code should use `createDefault(...)`,
`create(...)`, or `createIn(...)`: each accepts a typed `ruby.File -> T`
callback, returns that callback's `T`, and uses `@:rubyBlockArg` to emit Ruby's
recommended native block form:

```haxe
var size = ruby.Tempfile.create("report-", function(file) {
	file.write("typed report");
	file.flush();
	return file.size();
});
```

Generated Ruby remains recognizable and lets Ruby own the `ensure` cleanup:

```ruby
require "tempfile"

size = Tempfile.create("report-") do |file|
  file.write("typed report")
  file.flush()
  file.size()
end
```

Ruby closes and removes the scoped file when the block exits, including when
the callback raises. The callback receives a typed `ruby.File`, not `Dynamic`.
Inline Haxe function expressions emit normal Ruby blocks; a callback stored in
a typed Haxe function value is forwarded as `&callback`, preserving its arity.
To support that boundary, `ruby.File.open(...)` now returns `ruby.File` and the
nominal instance exposes bounded `path`, `write`, `readAll`, length-bounded
`read`, `rewind`, `flush`, `close`, `isClosed`, and `size` operations. A
length-bounded read returns `Null<String>` because Ruby returns `nil` at EOF;
the all-content form remains a non-null `String`.

The `new ruby.Tempfile(...)` constructor remains available for code that must
retain a nominal temporary-file object outside a callback. That form is an
explicit lifecycle responsibility: call `closeAndUnlink()` deterministically.
Ruby's GC finalizer is a fallback, not a resource-management contract, and may
leave files present for an unbounded interval. `path()` is therefore
`Null<String>` because successful unlinking removes the path.

Open-ended basename arrays, mode/options keyword bags, anonymous-file keyword
forms, and general delegated IO are intentionally excluded. They should gain
separate typed contracts where needed rather than widening this lifecycle seam
through `Dynamic`, casts, raw Ruby, or a wrapper runtime.

## Adding A New Facade

1. Check whether the API belongs in `std/ruby`, Haxe std, RailsHx, or a gem
   layer. Ruby stdlib modules belong in `std/ruby`; Rails and gem APIs do not.
2. Prefer an extern over a wrapper class when the Ruby API is already the
   runtime owner and the Haxe surface can be typed directly.
3. Add `@:rubyRequire` if Ruby needs a stdlib require.
4. Keep raw `__ruby__` out of public facades. If a tiny implementation helper
   needs raw Ruby, mark it explicitly with `@:rubyAllowRaw`, keep it narrow, and
   explain why a direct extern or compiler lowering was not enough.
5. Avoid hiding Ruby magic behind compiler globals. Use explicit imports for
   convenience names, and keep exact Ruby interop under the `ruby.*` package.
6. Add or update inventory when adding new std/runtime files:
   `docs/stdlib-inventory.json` must represent new `std/**` and
   `runtime/hxruby/**` ownership.

## Testing Expectations

Choose the smallest gate set that proves both authoring and emitted shape:

- `npm run test:examples-compile` when a public example imports the facade.
- Focused smoke tests such as `test:ruby-interop`, `test:ruby-call-shapes`, or a
  new facade-specific smoke when behavior executes at runtime.
- `npm run test:compiler-metadata-docs` when adding or changing compiler
  metadata; `docs/compiler-metadata.md` is the canonical target metadata index.
- `UPDATE_SNAPSHOTS=1 npm run test:snapshots && npm run test:snapshots` when
  generated Ruby shape or requires change.
- `npm run test:runtime-minitest` when `runtime/hxruby/**` changes.
- `npm run test:stdlib-inventory && npm run test:gap-report` when inventory or
  std ownership changes.
- `npm run public:precommit` and GitHub CI before considering the slice done.

If a facade starts as a deliberately loose boundary, add a follow-up bead for
typed decoding or stronger contracts instead of letting `Dynamic` spread into
canonical examples.
