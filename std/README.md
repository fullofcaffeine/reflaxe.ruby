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

RailsHx browser helpers should also stay typed. If Haxe's DOM externs do not
yet expose a browser API needed by idiomatic Turbo/Hotwire code, add a small
facade such as `rails.dom.Forms` here instead of using raw `js.Syntax.code` in
app examples.

Repeated Hotwire UX patterns belong one layer higher, under packages such as
`rails.hotwire`, so app code can consume typed helpers instead of rewriting the
same selector and lifecycle glue.

Rails template primitives that are Hotwire-native, such as HHX
`<turbo_frame>` and `<turbo_stream_from>`, belong in `rails.action_view` and
should lower to ordinary Rails/Turbo markup rather than introducing client
runtime wrappers.

See `docs/stdlib-ownership.md` and `docs/stdlib-inventory.json`.
For typed Ruby stdlib facade authoring rules, see
`docs/ruby-stdlib-facades.md`.
