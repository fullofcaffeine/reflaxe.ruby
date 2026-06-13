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
- Ruby extension interop should follow `docs/ruby-extension-interop.md`. Prefer typed extension contracts (`@:rubyMixin`, `@:rubyInclude`, `@:rubyPrepend`, `@:rubyExtend`) for `include`/`extend`/`prepend`/Concern-style APIs. Existing Ruby libraries should be consumed through typed extern/contracts first; Haxe-owned output should emit normal Ruby constructs so Ruby callers keep seeing hand-written-looking Ruby.
- Whatever can be generated or inferred by macros/generators should be generated or inferred. Do not make users repeat strings, paths, fields, module names, routes, params, or signatures when the compiler can derive them from typed Haxe metadata, Ruby/Rails source, schemas, routes, RBS/YARD, or checked filesystem state.
- Macros/generators that reference files or directories must fail closed by default: if a referenced path is missing or unsafe, raise a compile/generator error with a useful diagnostic. Only add unchecked escapes when the API name and docs make the risk explicit (`external`, `unchecked`, or similar), and prefer checked forms such as `Template.existing(...)` for normal app code.
- For metaprogramming-heavy Ruby/Rails libraries, prefer generator-assisted typed contracts over dynamic calls. Optional LLM assistance may suggest externs/contracts from Ruby source/docs, but generated contracts must compile and uncertain guesses must be marked for human review.
- RailsHx/rubyhx should provide a better typed Haxe authoring UX over vanilla Rails, not just one-to-one Rails wrappers. Prefer Haxe-native abstractions, typed facades, macros, and small DSLs when they make app code safer or clearer, while still emitting idiomatic Rails/Ruby artifacts.
- Haxe-facing RailsHx APIs should be idiomatic Haxe where the API composes as Haxe, then lower to idiomatic Ruby/Rails. Use Haxe package/class/member conventions for owned abstractions (`Todo.f.title`, `sampleUserId`, `requirePermit`) and reserve Ruby/Rails `snake_case` for generated Ruby, Rails paths, database columns, params keys, route names, template tags, and explicitly external native APIs.
- Rails-shaped Haxe APIs are acceptable when they improve familiarity, migration, or 1:1 Rails predictability, but they must still be typed and Haxe-safe. A close Rails mapping is good if it is 1:1 and well typed, or if RailsHx improves it with macros/typed refs/better UX. Examples: HHX tags such as `<form_with>`/`<content_for>` can mirror Rails template concepts; `ParamsMacro.requirePermit(...)` can mirror strong params while validating fields; `Template.existing("legacy/badge") : Template<Locals>` can keep Rails partial paths while typing locals.
- Do not casually mix Ruby naming into app-facing Haxe just because the output is Ruby. If a Rails concept is naturally `snake_case` at runtime (`user_id`, `content_for`, `data-turbo-track`, `app/views/controllers/todos/_card.html.erb`), expose a typed Haxe abstraction or checked literal that lowers to that string/symbol when possible. Prefer `Todo.fields.userId` or `Todo.f.userId` over repeated `"user_id"`/`"userId"` strings in Haxe when the field is known from schema metadata.
- For externs that model existing Ruby APIs, preserve the Ruby name through `@:native`, `@:rubyName`, metadata, or generated wrappers, but present a Haxe-idiomatic facade where RailsHx owns the abstraction. Existing Ruby should keep seeing hand-written-looking Ruby; Haxe authors may use Rails-shaped names at deliberate interop or Rails-concept boundaries, not as accidental stringly leakage.
- When adding new public RailsHx std packages/classes, pause before introducing names that mirror Ruby module spelling mechanically. Prefer the naming that will feel stable and normal to Haxe users; document any deliberate exception where Rails naming is more valuable than Haxe convention. Avoid adding new lowercase class names or public snake_case Haxe members unless compatibility with existing source or extern mapping requires it.
- Use `../haxe.elixir.codex`'s Phoenix/Ecto implementation as the local architectural inspiration before designing new RailsHx surfaces.
- Use `../haxe.compilerdev.reference` as a local reference source for Haxe/compiler internals, Haxe docs, Ruby, and Rails examples when those references are useful for implementation decisions.
- Treat PhoenixHx as inspiration for the abstraction/compilation strategy, not as a 1:1 API template. Adapt the pattern to Rails-native concepts: for example, Phoenix slots map better to Rails captured buffers passed as typed partial locals than to copied HEEx slot syntax.
- Map the Elixir compiler pattern to Rails concepts: Ecto schemas become ActiveRecord model registries, Ecto typed queries become typed `ActiveRecord::Relation` APIs, Ecto migrations become Rails migration builders/generators, Phoenix controllers/params become typed ActionController/strong-params surfaces, and Phoenix router tooling informs Rails route helper sync.
- When a Rails surface wants DSL ergonomics, prefer typed Haxe std stubs plus macros/compiler lowering, following the HXX/HEEx pattern: type-check in Haxe, erase compile-time helpers when possible, and emit Rails-native Ruby/templates instead of a parallel runtime DSL.
- Before implementing or changing Rails templates, inspect the relevant Phoenix/HXX examples in `../haxe.elixir.codex` (`examples/todo-app`, `test/snapshot/phoenix/*hxx*`, `std/phoenix/hxx/**`, and `plans/active/hxx2-default-authoring-path.md`) and mirror the architectural lesson: app authors write typed Haxe/HHX, while target template syntax is compiler output.
- Hard rule for ActionView: RailsHx-authored app-facing templates, partials, and layouts must be authored as typed Rails HHX inline markup (`return <div>...</div>`) through `@:railsTemplateAst(...)`. Raw ERB strings (`public static var body:String = '<% ... %>'`, `erb/template` string fields, or generator/materializer `writeFile("app/views/**/*.erb", ...)`) are not acceptable for RailsHx-owned examples or default paths. ERB is normally an output format produced by the compiler, not the authoring format.
- Gradual adoption exception: existing Rails/Poc `.erb` files may be tracked only as Rails-owned external source in explicit interop/adoption fixtures or user apps. Haxe must consume those files through typed contracts such as `Template.existing("path") : Template<TLocals>` (checked filesystem interop) or lower-level `Template.external("path") : Template<TLocals>` when a synthetic/test fixture cannot be filesystem-checked, plus typed extern/facade wrappers for Ruby helpers/services. Do not rewrite mixed-app fixtures to fake HHX ownership; the point is to prove Haxe can wrap and gradually replace real Rails code safely.
- For quick Rails PoCs, support this workflow: prototype in pure Rails/Ruby/ERB, wrap stable Ruby services/components with typed Haxe externs and `Template.existing`/`Template.external`, then migrate pieces to Haxe/HHX over time without breaking Ruby callers. Existing Ruby should consume generated Haxe constants and generated partials exactly as normal hand-written Rails artifacts.
- `@:railsAllowRawErb` is an explicit migration/interop escape hatch only. Before adding or keeping it, document why HHX cannot express the case yet, add/keep a bd follow-up for the missing typed RailsHx feature, and avoid using that escape hatch in canonical samples such as `examples/todoapp_rails`.
- For ActionView work, `@:railsTemplateAst(...)` classes should let `reflaxe.ruby.macros.RailsInlineMarkup` rewrite markup into typed `HtmlNode`/`HtmlAttr` AST before the Ruby compiler emits Rails-native ERB. Prefer HHX tags such as `<if>`, `<for>`, `<link_to>`, `<partial>`, and `<form_with>` in examples before reaching for lower-level helper calls.
- RailsHx HHX should be aggressively type-safe. Do not accept stringly Haxe authoring just because Rails/Ruby ultimately wants strings. Prefer typed helpers, abstracts, generated constants, enums, typedef-backed locals, model-field references, route externs, and macros that validate string literals at compile time. Raw string literals are acceptable only when they are the Rails-facing representation and are checked by a macro/compiler pass or documented as a temporary gap with a bead follow-up.
- RailsHx template paths should use typed template references by default. For RailsHx-owned HHX, prefer `Template.of(ViewClass)` and `Template.layout(LayoutViewClass)` so missing/renamed view classes fail at Haxe compile time; keep `Template.named("...")` as a lower-level escape only. `@:railsTemplate("...")`, `Template.named("...")`, and `Template.external("...")` strings must remain literal-only and validated for safe path shape. External Rails/Poc templates should prefer `Template.existing("path")`, which checks `app/views`/`rails/app/views`; use unchecked `Template.external("path")` only when the file cannot be discovered by the macro and document why.
- RailsHx form/params fields should not drift as independent strings. Field names in `<hidden_field>`, `<field_label>`, `<text_field>`, `<text_area>`, `<check_box>`, `ParamsMacro.requirePermit`, model metadata, and generated strong params should be derived from typed model/schema field references or checked string-literal macros. If a string is unavoidable because Rails expects snake_case, keep it behind a typed abstraction that lowers to the Rails string/symbol.
- RailsHx ActiveRecord queries should feel Rails-native but remain Haxe-typed: prefer `Relation<T>` chains, model-owned criteria checks, and field refs such as `Todo.f.title.asc()` over string/symbol query fragments. Keep generated Ruby as ordinary ActiveRecord (`where(...)`, `order(title: :asc)`, `limit(...)`, `to_a`) rather than emitting a parallel query runtime.
- RailsHx slot/layout names, DOM hooks, and CSS classes should be centralized when they cross files. Prefer typed slot names/DOM hook constants/abstracts over repeated `"head"`, `"#open-work"`, `"data-railshx-*"`, or class strings in Haxe/JS samples. Plain static HTML class strings are acceptable for local styling, but repeated behavior hooks should be named typed values.
- HHX helper tags that take labels, such as `<link_to>`, `<field_label>`, and `<submit>`, may use `text="..."`, static child text, or `${...}` expression children. `<link_to>` also supports nested HHX markup via Rails block-form `link_to`. Keep broader component slots as explicit future work unless the parser/lowerer has typed coverage and tests.
- RailsHx reusable components should stay Rails-native: prefer `<component template=... slot="body" locals=${{body: Slot.content(), ...}}>...</component>` when a typed partial needs child content. The compiler should lower this to a normal Rails `render partial:` call with a captured ActionView buffer local, not Phoenix-style slot syntax copied into Rails.
- Rails layout primitives have typed HHX tags: `<>...</>` fragments, `<doctype_html />`, `<csrf_meta_tags />`, `<csp_meta_tag />`, `<stylesheet_link_tag />`, `<javascript_importmap_tags />`, `<rails_yield />`, `<yield_content name="..." />`, and `<content_for name="...">...</content_for>`. Use these for layouts/slots instead of generator/materializer ERB strings.
- Rails migrations should be authored in Haxe through `@:railsMigration(...)` classes and generated as standard timestamped `db/migrate/*.rb` ActiveRecord artifacts. Do not add canonical sample/scaffold migrations as hand-written Ruby unless it is an explicit interop fixture with a tracked follow-up; the Rails Ruby file is compiler output, not source of truth.
- In `@:railsTemplateAst` methods, a single argument named `locals` is a typed Rails locals object: field access like `locals.sampleUserId` should lower to the Rails partial local `sample_user_id`, not to `locals.sample_user_id`. `<partial locals=${{sampleUserId: value}}>` object-literal keys must also lower to Rails local names such as `sample_user_id`, so typed partial composition remains compatible with generated partial bodies.
- Treat `rails.action_view.H`, `HtmlNode`, and `HtmlAttr` as lower-level compiler-owned IR/facade surfaces. They are still valid for small implementation slices, tests, and explicit escape hatches, but the default sample/documented authoring style should be HHX. Typed partials, route-helper links, and form-builder tags must continue lowering through `@:railsTemplateAst(...)`; raw ERB must remain explicit with `@:railsAllowRawErb` and should be treated as a migration bridge, not the destination.
- RailsHx examples must have a developer loop, not only CI materialization. For `examples/todoapp_rails`, keep `npm run todoapp:prepare`, `npm run todoapp:server`, `npm run todoapp:watch`, and `npm run todoapp:test` documented and working: Haxe/HHX remains the source of truth, the generated Rails app under `test/.generated/rails_integration` is disposable, Rails runs through Bundler and the app-local `bin/rails`, and the watcher refreshes generated Rails files without deleting local SQLite/bundle state.
- RailsHx browser E2E should follow the PhoenixHx sentinel lesson, adapted to Rails: use `npm run test:todoapp-playwright` for a real browser gate that prepares the generated Rails app, boots Rails on a dedicated port, runs Playwright specs under `examples/todoapp_rails/e2e`, and tears down. Keep Playwright specs thin and user-visible; deeper compiler/framework behavior belongs in Haxe/Ruby smoke tests and Rails integration tests.
- Rails-facing generators should be Ruby/Rails-native, analogous to PhoenixHx's Mix tasks for in-place Phoenix apps. Prefer `bin/rails generate hxruby:*` as the app-facing UX, keep rake/npm wrappers compatible, and reserve Haxe->Ruby generator self-hosting for optional dogfooding or greenfield bootstrap experiments after the Ruby generator contract is stable.
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
