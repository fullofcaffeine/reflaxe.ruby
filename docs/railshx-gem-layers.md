# RailsHx Gem Layers

RailsHx should support installed Ruby gems without pretending to replace Ruby's
gem ecosystem. The runtime owner stays Ruby/Bundler; the Haxe layer supplies
typed contracts, macros, checked generators, and app-facing ergonomics.

## Ownership Model

- The Rails app installs and configures gems normally through `Gemfile`,
  Bundler, Rails generators, initializers, migrations, and routes.
- RailsHx consumes the installed gem through typed Haxe contracts generated from
  deterministic metadata where possible: RBS, YARD, Ruby source parsed without
  executing app code, Rails routes, schema metadata, and known integration hooks.
- Common gems can grow reusable companion layers such as `devisehx` or
  `hxruby-devise`. Those packages should contain Haxe externs/facades, macros,
  generators, examples, docs, and tests, while the original Ruby gem remains the
  runtime implementation.
- App-local generated contracts remain valid for project-specific conventions
  and for gems that are not popular enough to justify a maintained package.

## Recommended Workflow

There are two time horizons:

- **Implemented now:** use `hxruby:adopt --gem NAME --discover` for a
  deterministic Bundler inventory and `hxruby:adopt --gem NAME --write
  contracts` for a conservative app-local Haxe skeleton under
  `src_haxe/interop/gems/<gem>`.
- **Planned next:** grow a dedicated `hxruby:gem-layer` generator and reusable
  companion packages such as DeviseHx once the generic adoption lane has enough
  production evidence.

For a generic installed gem, the current flow is:

```bash
bundle add some_gem
bin/rails generate some_gem:install
bin/rails generate hxruby:adopt --gem some_gem --discover
bin/rails generate hxruby:adopt --gem some_gem --write contracts
bundle exec rake hxruby:compile
bundle exec rake hxruby:test
```

The `--gem` lane fails closed when the app `Gemfile` is missing, the gem is not
present in Bundler's resolved specs, the gem path cannot be resolved safely, or
the write mode is not explicit. Generated Haxe may contain `Dynamic` only with
review/TODO markers because Ruby source rarely proves complete Haxe types.

The first pass should be deterministic. Before asking an LLM for help, the
generator should mechanically inventory what it can prove: installed gem path and
version, exported Ruby constants, RBS/YARD signatures, source-defined modules and
methods, Rails generators, routes, migrations, initializers, model concerns, and
test helpers. That pass should emit a conservative Haxe skeleton plus explicit
TODO/review markers for anything uncertain.

LLMs can help after that deterministic pass, but only inside a generator-shaped
lane. The generator should emit or reference stable templates that show the
expected RailsHx patterns for externs, mixins, controller helpers, route
contracts, macros, docs, and tests. An LLM can then use those templates plus the
mechanical inventory and gem docs/source to propose a Haxe layer, while RailsHx
remains the gatekeeper:

```bash
bin/rails generate hxruby:adopt --gem devise --discover
bin/rails generate hxruby:adopt --gem devise --write contracts
bin/rails generate hxruby:adopt --gem devise --write contracts --devise-hhx-views
# Ask an LLM to draft patches using tmp/devisehx-prompt.md, the deterministic
# inventory, the gem docs/source, and the RailsHx companion-layer templates.
bundle exec rake hxruby:compile
bundle exec rake hxruby:test
```

LLM-generated code must be treated as a reviewable patch. It must compile, avoid
unmarked guesses, keep uncertain APIs as TODO/review markers, and pass the same
Ruby syntax, Rails runtime, route/schema/helper parity, and security checks as
hand-written contracts.

For DeviseHx specifically, use
[`railshx-devisehx-gpt55-prompt.md`](railshx-devisehx-gpt55-prompt.md) before
implementation. That prompt asks GPT 5.5 Pro for the focused design review
required by `haxe.ruby-bjv.6.4`: reusable package boundaries, deterministic
metadata inputs, typed model/controller/route APIs, current-user typing,
escape-hatch policy, tests, docs, and bead mutations.

The folded design review lives in
[`railshx-devisehx-design.md`](railshx-devisehx-design.md). Treat it as the
source of truth for DeviseHx implementation sequencing: Devise remains the
runtime owner, Rails route output remains the helper oracle, and RailsHx owns
typed scope contracts, deterministic inventory, HHX helpers, generator
validation, and dogfood tests.

For a reusable gem layer such as Devise:

```bash
bundle add devise
bin/rails generate devise:install
bin/rails generate devise User
haxelib install devisehx
bin/rails generate hxruby:adopt --gem devise --write contracts
# Optional: generate RailsHx-owned HHX skeletons for supported Devise views.
bin/rails generate hxruby:adopt --gem devise --write contracts --devise-hhx-views
bundle exec rake hxruby:routes
bundle exec rake hxruby:compile
bundle exec rake hxruby:test
```

The reusable DeviseHx companion package is hardening incrementally, and the
contract is stable: Rails does normal Devise setup, then RailsHx generates or
consumes typed Haxe contracts around Devise routes, helpers, controllers, model
mixins, params, and test helpers.

`--devise-hhx-views` is intentionally separate from plain contract adoption:
plain adoption does not claim view ownership, while the flag writes
manifest-owned HHX view skeletons such as Devise sessions and registrations
templates. Existing Rails/Devise ERB files remain Rails-owned unless a
manifest/header/force flow explicitly transfers that artifact.

Reusable gem layers should use the testing pyramid in
[`railshx-gem-layer-testing.md`](railshx-gem-layer-testing.md): deterministic
inventory/generator smoke, generated artifact snapshots, Haxe positive and
negative compile tests, thin Rails runtime seam tests, and small dogfood browser
flows. Do not retest the Ruby gem's own runtime when RailsHx is only wrapping it.

The todoapp now carries the first canonical DeviseHx dogfood slice. It keeps
Devise as the runtime owner for Warden, encrypted passwords, routes, sessions,
and sign-out semantics, while Haxe owns `UserAuth`, typed `@:devise(...)` model
metadata, `beforeAction(UserAuth.authenticate)`, typed current-user helpers,
`DeviseRoutes.deviseFor(UserAuth.scope, {only: [Sessions]})`, a Haxe-owned
guest sign-in route, `AuthLinks.sessionPath(UserAuth.scope)` plus
`<devise_sign_out_button>`/`DeviseErrors` in HHX, and auth composition around
normal Rails helpers. The reusable adoption lane can also generate opt-in
RailsHx-owned HHX skeletons for sessions, registrations, and recoverable
password reset/edit views while keeping existing Devise ERB Rails-owned unless
manifest ownership is explicit. A later dedicated DeviseHx app can still expand
into confirmable, unlockable, OmniAuth, and multi-scope matrices without making
the todoapp huge.

## DeviseHx Shape

Devise should not be hard-coded into RailsHx core. It is large and popular
enough to justify a reusable companion layer once the generic gem-layer lane is
ready. Until then, app-local contracts can still wrap the subset an app uses.

Migration path:

1. Start with ordinary Rails Devise install/generators.
2. Generate or write an app-local Haxe skeleton from deterministic metadata.
3. Use an LLM only to propose improvements against the skeleton and RailsHx
   patterns.
4. Promote the repeated, stable parts into `devisehx` / `hxruby-devise`.
5. Keep project-specific policy, such as role names or custom controllers, in
   the app.

A Devise companion layer should expose typed Haxe surfaces such as:

```haxe
import devise.DeviseController;
import devise.DeviseHelpers;
import devise.DeviseModel;

@:railsModel("users")
@:devise([databaseAuthenticatable, registerable, recoverable, rememberable, validatable])
class User extends rails.active_record.Base<User> {
	public var email:String;
}

@:railsController
class DashboardController extends rails.action_controller.Base {
	static final lifecycle = {
		beforeAction(DeviseHelpers.authenticateUser);
	};

	public function index():Void {
		var user = DeviseHelpers.currentUser<User>(this);
	}
}
```

The generated Ruby should remain ordinary Devise/Rails code: `devise :...`,
`before_action :authenticate_user!`, `current_user`, Devise routes, normal
migrations, and normal Rails tests. Haxe should add compile-time validation for
known Devise modules, generated route helpers, current-user types, model fields,
and controller lifecycle hooks.

## Package Policy

- Keep generic gem adoption in `hxruby`/RailsHx generators.
- Keep gem-specific behavior in separate companion layers once a gem's API is
  large or popular enough.
- Companion layers may live in this monorepo while incubating, but should be
  designed so they can become separate repos/packages that depend on
  `reflaxe.ruby`/`hxruby`.
- LLM-assisted contract generation is allowed only as a patch suggestion path.
  Prefer generator-provided prompt/templates so the LLM follows RailsHx naming,
  metadata, fail-closed, and test patterns. Generated contracts must compile,
  mark uncertain APIs for review, and pass Ruby syntax, Rails runtime, and
  route/schema/helper parity gates where applicable.

## Testing Policy

Typed gem layers should not re-test the Ruby gem they wrap. DeviseHx, for
example, should not duplicate Devise's login/session test suite. RailsHx tests
should prove the boundary RailsHx owns:

- deterministic discovery and adoption smoke tests for fail-closed behavior;
- committed golden snapshots for generated Haxe contracts, JSON inventory,
  diagnostics, docs, and other reviewable artifacts;
- Haxe compile checks proving generated app-local contracts are usable by typed
  Haxe app code;
- focused Rails request/browser dogfood only where Rails must consume generated
  artifacts end-to-end, such as a later DeviseHx login/logout example.

This is now tracked as `haxe.ruby-8jr` so future companion gem layers inherit
the same pattern instead of growing ad hoc test suites.

## Starter Template

New RailsHx starter apps include an app-local copy of this workflow at
`docs/railshx/gem_layers.md`. Treat that file as the place for project-specific
notes while integrating a gem. It should record:

- the installed gem/version;
- which deterministic metadata sources were used;
- which Haxe contracts were generated or hand-written;
- which APIs are still TODO/review;
- which LLM prompt, if any, produced reviewed patches;
- which compile, Rails test, and browser/runtime gates prove the layer.
