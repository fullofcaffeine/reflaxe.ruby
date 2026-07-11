# Ruby Stdlib Facades

Ruby stdlib facades let Haxe-authored Ruby code use real Ruby libraries without
falling back to raw `__ruby__`, broad `Dynamic`, or wrapper runtimes. They live
under `std/ruby/**` and should make the generated Ruby look like ordinary
hand-written Ruby wherever the Ruby API already has the desired behavior.

## Naming And Ownership

- Put Ruby-owned library surfaces under the `ruby` package:
  `ruby.Dir`, `ruby.File`, `ruby.FileUtils`, `ruby.Json`, `ruby.Kernel`,
  `ruby.Pathname`, and future `ruby.CSV`, `ruby.URI`, or `ruby.Tempfile`
  facades.
- Keep the Haxe class name Haxe-idiomatic when RubyHx owns the authoring
  surface. Use `@:native` to point at Ruby constants with different spelling,
  for example `@:native("JSON") extern class Json`.
- Preserve exact Ruby names through `@:native`, `@:rubyName`, or metadata when
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
- `UPDATE_SNAPSHOTS=1 npm run test:snapshots && npm run test:snapshots` when
  generated Ruby shape or requires change.
- `npm run test:runtime-minitest` when `runtime/hxruby/**` changes.
- `npm run test:stdlib-inventory && npm run test:gap-report` when inventory or
  std ownership changes.
- `npm run public:precommit` and GitHub CI before considering the slice done.

If a facade starts as a deliberately loose boundary, add a follow-up bead for
typed decoding or stronger contracts instead of letting `Dynamic` spread into
canonical examples.
