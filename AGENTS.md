# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Ruby Profile Contract

The compiler has two public profile contracts: `ruby_first` and `portable`.

- `ruby_first` is the default Ruby-first contract: Ruby/Rails conventions win when they conflict with cross-target portability.
- `portable` is the Haxe-semantics-first contract: Haxe behavior wins when Ruby/Rails conventions would drift semantics.
- Both profiles should emit idiomatic Ruby whenever it is behavior-preserving.
- Treat profiles as semantic guardrails in one compiler pipeline, not separate backend engines.
- `idiomatic` is a compatibility alias for `ruby_first`; new docs, examples, and tests should prefer `ruby_first`.
- Do not introduce a public `metal` profile by analogy with `haxe.rust` or `haxe.go`; Ruby performance policy belongs in explicit optimizer/runtime defines unless a future profile has a real, tested, documented contract.

See `docs/profiles.md` before changing profile behavior.

## RailsHx Direction

Rails work should follow `docs/railshx-roadmap.md`.

- Treat RailsHx as the Rails-first layer on the existing Ruby compiler pipeline, not a separate backend.
- RailsHx/rubyhx should provide a better typed Haxe authoring UX over vanilla Rails, not just one-to-one Rails wrappers. Prefer Haxe-native abstractions, typed facades, macros, and small DSLs when they make app code safer or clearer, while still emitting idiomatic Rails/Ruby artifacts.
- Use `../haxe.elixir.codex`'s Phoenix/Ecto implementation as the local architectural inspiration before designing new RailsHx surfaces.
- Map the Elixir compiler pattern to Rails concepts: Ecto schemas become ActiveRecord model registries, Ecto typed queries become typed `ActiveRecord::Relation` APIs, Ecto migrations become Rails migration builders/generators, Phoenix controllers/params become typed ActionController/strong-params surfaces, and Phoenix router tooling informs Rails route helper sync.
- When a Rails surface wants DSL ergonomics, prefer typed Haxe std stubs plus macros/compiler lowering, following the HXX/HEEx pattern: type-check in Haxe, erase compile-time helpers when possible, and emit Rails-native Ruby/templates instead of a parallel runtime DSL.
- Before implementing or changing Rails templates, inspect the relevant Phoenix/HXX examples in `../haxe.elixir.codex` (`examples/todo-app`, `test/snapshot/phoenix/*hxx*`, `std/phoenix/hxx/**`, and `plans/active/hxx2-default-authoring-path.md`) and mirror the architectural lesson: app authors write typed Haxe/HHX, while target template syntax is compiler output.
- Hard rule for ActionView: app-facing Rails templates, partials, and layouts must be authored as typed Rails HHX inline markup (`return <div>...</div>`) through `@:railsTemplateAst(...)`. Raw ERB strings (`public static var body:String = '<% ... %>'`, `erb/template` string fields, generator/materializer `writeFile("app/views/**/*.erb", ...)`, or copied `.erb` source) are not acceptable for new examples or default paths. ERB is an output format produced by the compiler, not the authoring format.
- `@:railsAllowRawErb` is an explicit migration/interop escape hatch only. Before adding or keeping it, document why HHX cannot express the case yet, add/keep a bd follow-up for the missing typed RailsHx feature, and avoid using that escape hatch in canonical samples such as `examples/todoapp_rails`.
- For ActionView work, `@:railsTemplateAst(...)` classes should let `reflaxe.ruby.macros.RailsInlineMarkup` rewrite markup into typed `HtmlNode`/`HtmlAttr` AST before the Ruby compiler emits Rails-native ERB. Prefer HHX tags such as `<if>`, `<for>`, `<link_to>`, `<partial>`, and `<form_with>` in examples before reaching for lower-level helper calls.
- HHX helper tags that take labels, such as `<link_to>`, `<field_label>`, and `<submit>`, may use `text="..."`, static child text, or `${...}` expression children. `<link_to>` also supports nested HHX markup via Rails block-form `link_to`. Keep broader component slots as explicit future work unless the parser/lowerer has typed coverage and tests.
- Rails layout primitives have typed HHX tags: `<>...</>` fragments, `<doctype_html />`, `<csrf_meta_tags />`, `<csp_meta_tag />`, `<stylesheet_link_tag />`, `<javascript_importmap_tags />`, `<rails_yield />`, `<yield_content name="..." />`, and `<content_for name="...">...</content_for>`. Use these for layouts/slots instead of generator/materializer ERB strings.
- In `@:railsTemplateAst` methods, a single argument named `locals` is a typed Rails locals object: field access like `locals.sampleUserId` should lower to the Rails partial local `sample_user_id`, not to `locals.sample_user_id`. `<partial locals=${{sampleUserId: value}}>` object-literal keys must also lower to Rails local names such as `sample_user_id`, so typed partial composition remains compatible with generated partial bodies.
- Treat `rails.action_view.H`, `HtmlNode`, and `HtmlAttr` as lower-level compiler-owned IR/facade surfaces. They are still valid for small implementation slices, tests, and explicit escape hatches, but the default sample/documented authoring style should be HHX. Typed partials, route-helper links, and form-builder tags must continue lowering through `@:railsTemplateAst(...)`; raw ERB must remain explicit with `@:railsAllowRawErb` and should be treated as a migration bridge, not the destination.
- RailsHx examples must have a developer loop, not only CI materialization. For `examples/todoapp_rails`, keep `npm run todoapp:prepare`, `npm run todoapp:server`, `npm run todoapp:watch`, and `npm run todoapp:test` documented and working: Haxe/HHX remains the source of truth, the generated Rails app under `test/.generated/rails_integration` is disposable, Rails runs through Bundler and the app-local `bin/rails`, and the watcher refreshes generated Rails files without deleting local SQLite/bundle state.
- Keep generated output Rails-native and recognizable: `ApplicationRecord`, Rails macros, Rails route helpers, timestamped migrations, Rails rake/tasks/generators, and Rails tests.
- Keep Rails apps `ruby_first` by default while allowing portable Haxe domain code to compile cleanly into idiomatic Ruby.
- Do not introduce raw app-level `__ruby__` to paper over missing Rails APIs; add typed `std/rails/**` or runtime wrappers instead.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- Commit and push frequently after each coherent task slice; do not accumulate multiple completed tasks locally before landing them.
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
