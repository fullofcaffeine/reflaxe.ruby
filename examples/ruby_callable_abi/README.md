# Pure RubyHx Callable ABI

This executable example shows how typed Haxe functions become idiomatic Ruby
blocks without exposing `yield` or `&block` as separate Haxe APIs.

- `CallableApi.direct` calls its required callback immediately and emits Ruby
  `yield`.
- `capture`, `forward`, and `optional` need a first-class callback value and
  therefore emit a normal Ruby `&block` parameter.
- `decorate` combines a typed keyword carrier with a typed block and emits
  ordinary required Ruby keywords plus `yield`.
- The locally narrowed `ScopedTempfile.create` extern proves the same ABI works
  for Ruby's stdlib without introducing a broad value type. Applications that
  need the wider reusable surface can use `ruby.Tempfile` directly.

The smoke gate also runs
`test/fixtures/ruby_callable_abi/ruby_origin.rb`, a handwritten Ruby program
that requires `callable_api.rb` and calls the Haxe-owned methods with normal
Ruby blocks and keywords.

Run the executable contract with:

```bash
npm run test:ruby-callable-abi-example
```

The committed snapshots under `test/snapshots/m1/ruby_callable_abi` own the
app-facing generated Ruby shape. The smoke gate owns Ruby syntax, Haxe-origin
and Ruby-origin behavior, and the established runtime-free guarantee: no
`hxruby/core.rb` and no `HXRuby.*` semantic helper calls. The compiler-wide
`hxruby/data_define.rb` compatibility file may still be retained for generated
Haxe enum support; it is not part of the callable ABI.

The related stdlib optimization is covered separately by the upstream Array
parity lane: statically typed Haxe calls may normalize to direct loops, while
calls that reach the Ruby backend emit native `map`/`select` blocks. Neither
path uses the removed `array_map`/`array_filter` helpers.
