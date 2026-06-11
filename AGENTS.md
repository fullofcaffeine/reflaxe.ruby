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
- Use `../haxe.elixir.codex`'s Phoenix/Ecto implementation as the local architectural inspiration before designing new RailsHx surfaces.
- Map the Elixir compiler pattern to Rails concepts: Ecto schemas become ActiveRecord model registries, Ecto typed queries become typed `ActiveRecord::Relation` APIs, Ecto migrations become Rails migration builders/generators, Phoenix controllers/params become typed ActionController/strong-params surfaces, and Phoenix router tooling informs Rails route helper sync.
- When a Rails surface wants DSL ergonomics, prefer typed Haxe std stubs plus macros/compiler lowering, following the HXX/HEEx pattern: type-check in Haxe, erase compile-time helpers when possible, and emit Rails-native Ruby/templates instead of a parallel runtime DSL.
- For ActionView work, prefer Rails HHX inline markup (`return <div>...</div>`) for new app-facing templates, following the haxe.elixir.codex HXX/HEEx pattern. `@:railsTemplateAst(...)` classes should let `reflaxe.ruby.macros.RailsInlineMarkup` rewrite markup into typed `HtmlNode`/`HtmlAttr` AST before the Ruby compiler emits Rails-native ERB.
- Treat `rails.action_view.H`, `HtmlNode`, and `HtmlAttr` as lower-level compiler-owned IR/facade surfaces. They are still valid for small implementation slices, tests, and explicit escape hatches, but the default sample/documented authoring style should be HHX. Typed partials, route-helper links, and form-builder tags must continue lowering through `@:railsTemplateAst(...)`; raw ERB must remain explicit with `@:railsAllowRawErb` and should be treated as a migration bridge, not the destination.
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
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
