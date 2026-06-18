# reflaxe.ruby std

Target stdlib sources live here.

- Additive Ruby facades and target-owned Haxe APIs belong directly under `std/`.
- Upstream Haxe std replacements belong under `std/_std/`.
- Runtime Ruby implementation files belong under `runtime/hxruby/`, not here.

Rails/Ruby library facades should be typed contracts over the real target APIs,
not wrapper runtimes. For receiver extensions such as ActiveSupport core
extensions, prefer `@:rubyPatch` externs under packages like
`rails.active_support` and use them from app code with Haxe `using`.

Ruby-flavored convenience helpers should stay explicit. `ruby.Prelude.puts`
can be statically imported as an opt-in alias for `Sys.println`, preserving
HXRuby stringification, while `ruby.Kernel.puts` remains the direct Ruby Kernel
interop surface.

See `docs/stdlib-ownership.md` and `docs/stdlib-inventory.json`.
