# Deterministic RBS-To-Haxe Generation

RubyHx packages a conservative RBS contract pipeline under `HXRuby::Rbs`.
It converts one exact declaration from a reviewed, repository-local `.rbs`
file into a nominal Haxe extern. The pipeline is infrastructure for curating
typed Ruby facades; generated text is not automatically a supported public API.

## Maintainer Command

The command reads one checked source and writes only to standard output:

```bash
ruby -Ilib scripts/rbs/generate-extern.rb \
  --root test/fixtures/rbs_generator \
  --input catalog.rbs \
  --constant FixtureCatalog \
  --package generated.rbs \
  --require fixture_catalog \
  --source-label catalog.rbs
```

Review or diff stdout before placing it in an owned Haxe source tree. The tool
has no output-path option and cannot overwrite a curated facade. `--root` must
exist, `--input` must be a safe relative path inside it, and the canonical
input path must remain inside that root. Missing files, traversal, absolute
paths, malformed declarations, unknown top-level syntax, and symlink escapes
fail before rendering.

Both release artifacts include the reusable `lib/hxruby/rbs/**` pipeline. The
Ruby gem also includes `scripts/rbs/generate-extern.rb`; the Haxelib ZIP keeps
its established no-`scripts/` layout, so maintainers use the repository command
or call `HXRuby::Rbs::ExternGenerator` from the packaged library directly.

`--class` can give a reviewed Haxe class a different name, while `--native`
retains the exact Ruby constant path. `--require` emits `@:rubyRequire` for a
logical Ruby library path. These options change names and loading metadata;
they do not make an unsupported RBS type safe.

## Precise-Or-Omitted Subset

The current mechanical subset supports:

- exact class declarations named by a Ruby constant path;
- exact module declarations when the generated surface contains only `self`
  methods (instance mixin contracts require manual curation);
- constructors, instance methods, and class methods;
- required and optional positional arguments;
- `String`, `Integer`/`int`, `Float`/`float`, Boolean aliases, and `Symbol`;
- nilable forms of those scalar types;
- nested `Array<T>` values whose member type is also supported;
- `void`/`nil` method returns; and
- Haxe-safe member and argument naming with `@:native` when Ruby spelling
  differs.

Overloads, keyword arguments, blocks, splats, open protocols, custom nominal
types, unions, intersections, mutation-specific shapes, and other unsupported
signatures are never widened to `Dynamic`, `Any`, `untyped`, a cast, or raw
Ruby. A recognized method becomes an explicit review marker when its complete
signature is outside the subset. Unsupported declaration syntax and malformed
structure fail closed.

## Determinism And Review Boundary

The standalone renderer groups constructors, instance methods, and class
methods, then sorts each group by its complete reviewed contract. It emits LF
line endings and one final newline. Equivalent declarations in a different
source order therefore produce byte-identical output when they use the same
stable source label and options.

The Rails adoption generator reuses the same parser and renderer but retains
source order for its established app-local snapshot. This compatibility mode
keeps existing generated adoption files byte-identical; it does not fork the
type system or introduce a second parser.

Before a generated stdlib contract becomes public, maintainers must still:

1. pin and review the exact upstream RBS source and its distribution on every
   supported Ruby branch;
2. curate names, nullability, blocks, overloads, mutations, and open protocols;
3. compile the Haxe contract and inspect direct Ruby output;
4. add MRI runtime evidence across the supported matrix;
5. add the bounded domain and evidence to `stdlib_coverage.json`; and
6. run the complete example, Rails runtime, browser, production, package, and
   canonical CI gates.

`CSV`, `Open3`, and `Set` now have separate reviewed facade slices; none
acquired support merely because this generator exists. Each remains owned by
its own curation, compilation, generated-shape, runtime, package, and matrix
gates.
The generator does not claim whole-RBS or whole-stdlib support.

## Mandatory Evidence

```bash
npm run test:rbs-generator
npm run test:ruby-stdlib-coverage
```

The first gate covers parser failures, canonical source-order independence, a
committed Haxe snapshot, Haxe compilation, direct native Ruby dispatch, MRI
runtime behavior, and checked-path failures. The second binds this deliberately
bounded generator contract to the packaged stdlib catalog.
