# Ruby Extension Interop Example

This example shows RubyHx extension interop from simple to more advanced adoption shapes.

Run it through the smoke gate:

```bash
npm run test:ruby-extensions
```

## Scenarios

1. Existing Ruby library, gradual wrapper: `LegacyPost` is an extern for a Ruby-owned class. `SluggableInstance` and `SlugSearchClassMethods` describe methods provided by existing Ruby modules. Haxe can call `legacy.slug()` and `LegacyPost.findBySlug(...)` with types, while Ruby ownership stays untouched.
2. Haxe-only library: `HaxeOnlyLibrary` is authored only in Haxe and emitted as normal Ruby. Ruby callers can require and call the generated constant as ordinary Ruby.
3. Haxe-owned class with Ruby mixins: `HaxeOwnedPost` is authored in Haxe and emits normal `include Decorated` / `extend Decorated`. Haxe gets typed members from extension contracts; generated Ruby does not contain fake stub methods.
4. Haxe plus explicit raw Ruby island: `HaxeRawBackedPost` is marked `@:rubyAllowRaw` and keeps a small `__ruby__` call behind a typed public method. Use this only for Ruby-specific metaprogramming that is not covered by typed std/compiler APIs yet.

For more patterns, including metaprogramming-heavy libraries and generator-assisted contracts, see [`docs/ruby-extension-interop.md`](../../docs/ruby-extension-interop.md).
