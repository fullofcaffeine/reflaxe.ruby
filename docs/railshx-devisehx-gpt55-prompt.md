# DeviseHx GPT 5.5 Pro Design Prompt

Use this prompt before implementing `haxe.ruby-bjv.6.4`.

The goal is a focused design review for a reusable Devise companion layer for
RailsHx. Do not ask for code first. Ask for a design, risks, typed API shapes,
deterministic extraction plan, tests, and bead mutations. Implementation should
start only after this review is folded back into the repo.

## Prompt

You are helping design `DeviseHx`, a reusable Haxe/RailsHx companion layer for
the Ruby Devise gem.

Context:

- `reflaxe.ruby` compiles Haxe to idiomatic Ruby.
- `RailsHx` is the Rails-first layer on top of that compiler.
- Rails and Bundler must remain runtime owners for Devise. Devise installation,
  migrations, controllers, routes, Warden integration, mailers, and runtime
  semantics stay normal Ruby/Rails/Devise.
- RailsHx should provide a typed Haxe authoring layer around Devise: externs,
  model mixin/module contracts, controller helper facades, route helper
  contracts, typed current-user APIs, generator templates, docs, and tests.
- The design must preserve gradual adoption: existing Rails apps using Devise
  should be able to wrap Devise with typed Haxe contracts without rewriting the
  app, while greenfield RailsHx apps can opt into the same typed layer.
- The design must be deterministic-first. Any LLM assistance is advisory and
  must happen after mechanical discovery of installed gem metadata.

Please audit these local repos/references:

- `/Users/fullofcaffeine/workspace/code/haxe.ruby`
- `/Users/fullofcaffeine/workspace/code/haxe.elixir.codex`
- `/Users/fullofcaffeine/workspace/code/haxe.compilerdev.reference/rails`
- `/Users/fullofcaffeine/workspace/code/haxe.compilerdev.reference/ruby`
- Devise source/docs. You may search the web for current Devise docs, but prefer
  primary sources and cite them.

Important local docs/files to inspect in `haxe.ruby`:

- `AGENTS.md`
- `README.md`
- `docs/railshx-gem-layers.md`
- `docs/ruby-extension-interop.md`
- `docs/railshx-gradual-adoption.md`
- `docs/railshx-controller-guide.md`
- `docs/railshx-routing-design.md`
- `docs/railshx-generated-artifact-ownership.md`
- `docs/railshx-escape-hatch-security-audit.md`
- `docs/railshx-testing-strategy.md`
- `lib/hxruby/generators/adopt.rb`
- `lib/hxruby/generators/app.rb`
- `scripts/ci/rails-adopt-generator-smoke.js`
- `scripts/ci/rails-app-generator-smoke.js`
- `std/rails/action_controller/**`
- `std/rails/active_record/**`
- `std/rails/routing/**`
- `examples/todoapp_rails/**`

Important local inspiration in `haxe.elixir.codex`:

- Generator and starter-app docs that make generated projects LLM-friendly.
- Phoenix/Ecto examples where Haxe types wrap framework-native runtime behavior
  without replacing the framework.
- The todo app auth/user-management examples, only as architectural inspiration:
  do not copy Phoenix APIs into Rails.

Design questions to answer:

1. What belongs in a reusable `devisehx` / `hxruby-devise` companion package
   versus app-local generated contracts under `src_haxe/interop/gems/devise`?
2. What deterministic metadata should `hxruby:adopt --gem devise` or a future
   `hxruby:gem-layer devise` collect before any LLM touches the code?
3. What Haxe API should model Devise model modules, for example
   `database_authenticatable`, `registerable`, `recoverable`, `rememberable`,
   `validatable`, `confirmable`, `lockable`, `timeoutable`, `trackable`, and
   `omniauthable`?
4. What Haxe API should model controller helpers such as authentication filters,
   `current_user`, `user_signed_in?`, `authenticate_user!`, redirects, and
   Devise controller customization?
5. How should typed current-user APIs work for multiple Devise scopes such as
   `User`, `Admin`, or custom scope names?
6. How should Devise route macros such as `devise_for` be handled in
   Haxe-owned routes and Rails-owned route adoption?
7. How should generated Haxe route externs remain Rails-authoritative after
   Devise routes are installed?
8. What should the typed auth UX look like in a RailsHx app, including login,
   logout, login-as-guest/sample flows, protected controllers, and HHX template
   helpers?
9. Which Devise APIs should stay explicit escape hatches because they are too
   dynamic or app-specific?
10. What compile-time diagnostics can RailsHx add for missing Devise model
    modules, wrong scope names, invalid controller lifecycle hooks, missing
    route helpers, wrong current-user types, or unsafe generator output?
11. What should the tests be? Include compiler snapshots, negative compile
    tests, generator smoke, Rails runtime tests, route parity, and a small
    browser/Turbo flow if useful.
12. What docs and examples should be added, and should the todoapp stay
    first-party session-only or grow a separate DeviseHx example app?

Design constraints:

- Do not hard-code Devise into RailsHx core unless a tiny generic hook is
  clearly justified.
- Keep generated output recognizable to Rails developers:
  `devise :...`, `before_action :authenticate_user!`, `current_user`,
  `user_signed_in?`, Devise routes, normal migrations, normal Rails tests.
- Avoid app-facing `Dynamic` except with review markers and explicit escape
  hatches.
- Prefer typed Haxe refs/macros over repeated strings.
- Macros/generators that read files must fail closed.
- LLM output must be a reviewable patch and must not bypass Haxe compile, Ruby
  syntax checks, Rails runtime tests, route parity, or gitleaks.
- The design should work for both Rails-owned and Haxe-owned source-of-truth
  modes.

Expected output:

- A concise verdict and recommended architecture.
- Proposed public Haxe API examples.
- Generator/adoption workflow examples.
- Deterministic extraction inventory.
- Devise module/controller/route/helper type-safety plan.
- Escape hatch/security policy.
- Test plan.
- Documentation/example plan.
- Concrete bead mutations or new beads under `haxe.ruby-bjv.6.4`.
- A list of unresolved questions that must be decided before implementation.

## Repos To Include

Give GPT 5.5 Pro these paths as local context:

- `/Users/fullofcaffeine/workspace/code/haxe.ruby`
- `/Users/fullofcaffeine/workspace/code/haxe.elixir.codex`
- `/Users/fullofcaffeine/workspace/code/haxe.compilerdev.reference/rails`
- `/Users/fullofcaffeine/workspace/code/haxe.compilerdev.reference/ruby`

If you also have a local Devise checkout, include it. Otherwise instruct GPT to
search the web and use primary Devise sources.

