# RailsHx Routing Design

RailsHx should support two route ownership modes:

- **Haxe-owned routes** for greenfield RailsHx apps. Haxe route declarations are
  the source of truth, and RailsHx emits normal `config/routes.rb`.
- **Rails-owned routes** for existing Rails apps and gradual adoption. The
  existing `config/routes.rb` remains the source of truth, and RailsHx consumes
  it without rewriting it.

Both modes must converge through Rails itself. Rails remains the route-helper
naming oracle: RailsHx runs `rails routes` and generates typed Haxe route-helper
externs from Rails output even when Haxe emitted the route file.

## Implemented Mode: Rails-Owned Route Helper Sync

Source of truth:

- `config/routes.rb` remains the source of truth for Rails-owned/adopted apps.
- Rails computes route names, path helpers, optional segments, glob params,
  namespaces, mounted routes, and resource/member/collection helper names.
- RailsHx runs `rails routes` and generates Haxe externs such as
  `Routes.todoPath(id)`.

Generated Haxe shape:

```haxe
package routes;

import rails.routing.RouteParam;

extern class Routes {
	public static function todoPath(id:RouteParam):String;
	public static function todosPath():String;
}
```

Generated Ruby shape:

```ruby
todo_path(id)
todos_path
```

Required route params use `RouteParam`, not `Dynamic`. `Int` and `String`
coerce implicitly because those are the common Rails ID/glob values. Model-like
objects cross the Rails `to_param` boundary explicitly:

```haxe
Routes.todoPath(1);
Routes.todoPath("legacy-slug");
Routes.todoPath(RouteParam.model(todo));
```

Why this mode stays first-class:

- Rails has many route naming rules that are easy to approximate badly.
- Existing Rails apps already have `config/routes.rb`; adoption must not force a
  rewrite.
- Haxe route helper externs give Haxe authors typeable/completable route calls
  while preserving normal Rails runtime behavior.
- Route helper params are typed enough for completion and ordinary compile-time
  mistakes while still erasing to Rails' normal helper arguments. Explicit Haxe
  `Dynamic` remains a language-level escape hatch and should not appear in
  generated route helper signatures.

## Implemented Initial Mode: Haxe-Owned Route Emission

For greenfield RailsHx apps, Haxe-owned routes are the preferred source of truth
for generator-created starter apps. The implemented initial shape is a typed
Haxe declaration layer that feels close to Rails' routing DSL, removes avoidable
controller/action/resource strings through typed refs where possible, and emits
normal `config/routes.rb`. Route helper externs still come from Rails output.

Canonical Haxe source:

```haxe
package routes;

import controllers.TodosController;
import controllers.HealthController;
import controllers.admin.UsersController as AdminUsersController;
import models.Todo;
import rails.macros.RoutesDsl.*;

@:railsRoutes
class AppRoutes {
	static final routes = {
		root(to(TodosController, index));

		get("todos/archive", to(TodosController, archive), {
			asName: routeName("archived_todos")
		});

		resources(Todo, TodosController, {
			except: [destroy],
			param: paramName("slug")
		});

		resources(resourceName("legacy_posts"), TodosController, {
			only: [index]
		});
	};
}
```

The `static final routes = { ... }` field is the canonical declaration host
because it is valid Haxe, preserves route order, supports Rails-like nested
blocks, and matches RailsHx's existing contextual `static final lifecycle = {
... }` controller pattern. Do not use naked route calls directly in the class
body; Haxe macros cannot reinterpret source the parser rejects.

Typed targets should be the default:

```haxe
root(to(TodosController, index));
get("todos/:slug/preview", to(TodosController, preview), {
	asName: routeName("todo_preview")
});
```

The macro receives a controller type reference and an action identifier,
resolves the controller class, validates the action method exists, derives the
Rails controller path, and emits `"todos#index"`/`"todos#preview"` into Ruby.
For Rails' `new` action, which cannot be used as a normal Haxe method name,
controllers should expose a Haxe-safe name mapped to Ruby:

```haxe
@:railsController
class TodosController extends rails.action_controller.Base {
	public function index():Void {}

	@:native("new")
	public function newAction():Void {}
}
```

Existing Ruby controllers should be consumed through typed extern contracts
before raw strings:

```haxe
@:native("Legacy::PostsController")
@:railsExternalController("legacy/posts")
extern class LegacyPostsController {
	public function show():Void;
}

@:railsRoutes
class AppRoutes {
	static final routes = {
		get("legacy/posts/:id", to(LegacyPostsController, show), {
			asName: routeName("legacy_post")
		});
	};
}
```

When a typed contract is not available yet, use explicit escapes:

```haxe
get("legacy/posts/:id", externalTo("legacy/posts#show"), {
	asName: routeName("legacy_post")
});

mountExternal(rubyConst("Sidekiq::Web"), at("/sidekiq"), {
	asName: routeName("sidekiq")
});

defaults({format: "json"}, {
	constraints({id: rx("[0-9]+")}, {
		get("numeric_posts/:id", to(PostsController, show), {
			asName: routeName("numeric_post")
		});
	});
});

uncheckedRubyRoute('get "legacy/*path", to: "legacy#show"');
```

`externalTo(...)` must be literal-only and validate `controller#action` shape,
safe characters, no traversal, and no Ruby injection. `mountExternal(...)`
accepts checked Ruby constants and checked mount paths for Rack apps such as
Sidekiq. `defaults(...)` and `constraints(...)` use checked object literals;
regex segment constraints must go through `rx("...")`, which rejects Rails-invalid
anchors and unsafe delimiter characters at Haxe compile time.
`uncheckedRubyRoute(...)` must require `-D
railshx_allow_unchecked_routes`, remain out of canonical examples, and pass Ruby
syntax plus Rails route parity gates.

Generated Rails output must be recognizable Rails. The implemented emitter uses
the Haxe type name as the source marker and records exact source positions in
the route manifest:

```ruby
# Generated by RailsHx from @:railsRoutes.
# Source: routes.AppRoutes
# Do not edit directly unless you intend to take RailsHx ownership.

Rails.application.routes.draw do
  root "todos#index"

  resources :todos, only: [:index, :show, :create, :update, :destroy], param: :slug do
    collection do
      get "completed", to: "todos#completed", as: :completed
    end

    member do
      patch "complete", to: "todos#complete"
    end
  end

  namespace :admin do
    resources :users, only: [:index, :show]
  end

  controller :health do
    get "up", action: :show, as: :health
  end

  defaults format: "json" do
    constraints id: /[0-9]+/ do
      get "numeric_posts/:id", to: "posts#show", as: :numeric_post
    end
  end
end
```

The emitted file must then be validated by Rails itself:

```bash
bin/rails routes
bin/rails test
```

For a focused, committed example of the implemented output shape, see
`examples/rails_routes_dsl`. It snapshots both generated `config/routes.rb` and
`.railshx/routes.haxe.json`. For a full app using Haxe-owned routes plus one
Rails-owned adoption route, see `examples/todoapp_rails`.

## Generated Route Helper Externs

`Routes.hx` must still be generated from Rails output, not invented directly
from the Haxe route manifest. Rails is the oracle for resource helper names,
namespace prefixes, optional/glob behavior, and route precedence.

```haxe
package routes;

import rails.routing.RouteParam;

// Generated by HXRuby::Generators::Routes from Rails route output.
@:native("self")
extern class Routes {
	@:native("root_path")
	public static function rootPath():String;

	@:native("todos_path")
	public static function todosPath():String;

	@:native("todo_path")
	public static function todoPath(slug:RouteParam):String;

	@:native("completed_todos_path")
	public static function completedTodosPath():String;

	@:native("complete_todo_path")
	public static function completeTodoPath(slug:RouteParam):String;

	@:native("admin_users_path")
	public static function adminUsersPath():String;

	@:native("health_path")
	public static function healthPath():String;
}
```

First-slice behavior should keep the existing safe route-param rule: required
segments become required `RouteParam` arguments; optional segments are not
required. Richer overload-like optional params can come later.

## Type-Safety Model

- Controller/action refs: `to(ControllerClass, actionIdent)` validates the
  controller class exists, is a RailsHx controller or checked external
  controller, and has a public instance action whose Ruby name matches.
- HTTP verbs: `get`, `post`, `patch`, `put`, `delete`, `options`, and `head`
  are distinct calls. Multi-verb routes should use typed verb tokens; all-verb
  routes need an explicitly unsafe API because Rails calls out security risks.
- Resource actions: `only`/`except` use action tokens such as `index`, `show`,
  `newAction`, `edit`, `create`, `update`, and `destroy`; included actions must
  exist on the target controller.
- Resource names: prefer `resources(Todo, TodosController)` and derive the
  Rails resource name from typed model metadata or convention. Use
  `resourceName("legacy_posts")` for non-model or legacy resources; it must be
  a checked snake_case literal and still validates controller actions.
- Route aliases: use `routeName("photo_display")`, not arbitrary strings.
  Validate snake_case helper prefix shape and reject empty/unsafe names.
- Path literals: accept checked Rails path literals such as `"photos(/:id)"`
  and `"files/*path"`. Parse required params, optional groups, and globs; reject
  traversal, malformed groups, backslashes, and invalid param identifiers.
- Constraints/defaults: support typed object-literal defaults and simple
  constraints, including `rx("...")` for segment regexes. Reject regexp anchors
  in route regex constraints because Rails disallows anchors there.
- Mounted apps: use explicit checked Ruby constants such as
  `mountExternal(rubyConst("Sidekiq::Web"), at("/sidekiq"), {asName:
  routeName("sidekiq")})`.
- Raw Ruby: disallowed by default. Any raw route line must be literal-only,
  define-gated, syntax-checked, parity-checked, and marked opaque in the route
  manifest.

## Compiler Architecture

Public DSL files:

- `std/rails/macros/RoutesDsl.hx`
- `std/rails/routing/RouteDecl.hx`
- `std/rails/routing/RouteTarget.hx`
- `std/rails/routing/RouteName.hx`
- `std/rails/routing/ResourceAction.hx`
- `std/rails/routing/HttpVerb.hx`
- `std/rails/routing/RouteRegex.hx`

Compiler implementation files:

- `src/reflaxe/ruby/rails/RailsRoutesExtractor.hx`
- `src/reflaxe/ruby/rails/RailsRoutesEmitter.hx`
- `src/reflaxe/ruby/rails/RailsRouteManifest.hx`

`RubyCompiler` detects `@:railsRoutes`, requires Rails mode, extracts the
`static final routes` declaration, emits `config/routes.rb`, emits the route
manifest `.railshx/routes.haxe.json`, records both artifacts in
`.railshx/manifest.json`, and suppresses generation of a Ruby class for the
declaration host. The route marker calls are compiler carriers, not a runtime
routing library.

Macro validation should happen as early as possible for literal shape,
controller/action refs, resource action tokens, unknown option fields, invalid
Ruby constants, and context errors such as `member(...)` outside
`resources(...)`. Cross-tree checks and duplicate output/alias checks belong in
the compiler extraction pass.

Post-emission sync supports:

```bash
bundle exec rake hxruby:routes MODE=rails-owned
bundle exec rake hxruby:routes MODE=haxe-owned
bundle exec rake hxruby:routes MODE=auto
```

Rails-owned mode reads `config/routes.rb`, runs `bin/rails routes`, and
generates `Routes.hx`. Haxe-owned mode compiles Haxe first, runs `bin/rails
routes`, generates `Routes.hx`, and runs parity checks against
`.railshx/routes.haxe.json`. Auto mode uses the Haxe-owned lane when it sees
`src_haxe/routes/AppRoutes.hx` or an existing `.railshx/routes.haxe.json`;
otherwise it behaves like Rails-owned adoption mode.

The first parity checker intentionally validates the route shapes RailsHx can
prove from the Haxe route manifest: root routes, direct verb routes, `match`,
simple `scope`/`namespace` path prefixes, mounted routes, wrong path/verb/target
diagnostics, missing routes, and opaque raw-route rejection. Full resource
expansion and richer nested route parity remain follow-up work under the route
coverage beads because Rails helper naming is still delegated to Rails.

## Implemented First-Slice Surface

Implemented:

- `root`
- `get`, `post`, `patch`, `put`, `delete`, `options`, and `head`
- typed multi-verb `match("path", to(Controller, action), [GET, POST])`
- `resources(Model, Controller, {only: [...]})`
- `resources(Model, Controller, {except: [...]})`
- `resources(Model, Controller, {param: paramName("slug")})`
- `resources(resourceName("legacy_posts"), Controller, {only: [...]})`
- `resources(..., ..., ..., { collection({ ... }); member({ ... }); })`
- `resource(Model, Controller, {only: [...]})`
- `resource(resourceName("legacy_profile"), Controller, {only: [...]})`
- `namespace("admin", { ... })`
- `scope("/api", {moduleName: "api", asName: routeName("api")}, { ... })`
- `controller(HealthController, { ... })`
- checked route aliases through `routeName("archived_posts")`
- duplicate explicit route alias diagnostics across the Haxe-owned route tree
- checked path literals including normal Rails `:id` segments, optional
  segments such as `"photos(/:id)"`, and glob segments such as `"files/*path"`
- typed controller/action refs through `to(Controller, action)`
- checked external controller refs through `@:railsExternalController`
- checked literal external targets through `externalTo("legacy/posts#show")`
- checked mounted Rack app constants through
  `mountExternal(rubyConst("Sidekiq::Web"), at("/sidekiq"))`
- typed object-literal route defaults through `defaults({format: "json"}, { ... })`
- simple checked constraints through `constraints({id: rx("[0-9]+")}, { ... })`
- route manifest emission under `.railshx/routes.haxe.json`
- generated artifact ownership entries for `config/routes.rb` and the route manifest
- `hxruby:routes MODE=rails-owned|haxe-owned|auto` route extern sync
- initial Haxe-owned route parity checks for direct route declarations and
  opaque raw-route rejection

Defer:

- unsafe all-verb routes
- action-only shorthand inside resource/member/collection blocks
- action-only shorthand inside controller blocks
- route helper parity checks beyond the implemented manifest comparison slice
- `concern`/`concerns`
- `shallow`, `shallowPath`, and `shallowPrefix`
- `drawExternal(...)` route files
- `redirect`, `direct`, and `resolve`
- Unicode route literals
- polymorphic helper extern generation beyond `RouteParam.model(...)`
- gem-specific macros such as `devise_for`
- arbitrary Ruby loops, conditionals, lambdas, and dynamic route generation

Known deferred DSL calls should fail with RailsHx-specific diagnostics, not
generic Haxe name-resolution errors. The public `RoutesDsl` intentionally
defines unsupported macro entry points for deferred Rails concepts such as
`concern`, `shallow`, `drawExternal`, `redirect`, `direct`, `resolve`, and
Devise-style route macros so users get an actionable message and a clear typed
escape/adoption path.

The route parity checker deliberately uses a hybrid shape. The Rails/Rake-facing
adapter remains Ruby-native because it handles CLI options, file IO, JSON parse
errors, and `HXRuby::Generators::Error` in the normal Rails tooling layer. The
deterministic manifest-vs-`rails routes` comparison core is authored in Haxe
under `tools/route_parity_hx` and compiled to committed Ruby under
`lib/hxruby/generated/route_parity`.

This is an intentional dogfood seam: the Haxe source should stay easier to
reason about than the equivalent dynamic Ruby algorithm, while the public Rails
task still looks and behaves like normal Ruby/Rake tooling. `npm run
test:routes-generator` runs `test:route-parity-dogfood`, which recompiles the
Haxe source and fails if the committed generated Ruby is stale. Do not hand-edit
the generated route parity files; regenerate them from the Haxe source.

## Source-Of-Truth Rules

- A project must choose one route source of truth per app or explicit route
  ownership boundary: Rails-owned `config/routes.rb` or Haxe-owned
  `@:railsRoutes`.
- The greenfield RailsHx default is Haxe-owned for generator-created starter
  apps.
- The adoption/migration-safe mode is Rails-owned and must remain supported.
- Haxe-owned route emission must refuse to overwrite an existing non-generated
  `config/routes.rb` unless an explicit force/adopt flag is used.
- Mixed route ownership in one file is not allowed until marker/manifest block
  ownership is designed and tested. If engines need local routing, each
  engine/app boundary needs its own explicit source-of-truth declaration.
- Route helper externs are always generated from Rails output, even when Haxe
  emitted the route file. Rails remains the naming oracle.
- Partial `config/routes.rb` marker-block ownership is future work. Route order
  is semantic in Rails, so the first implementation must not silently splice
  generated routes into a hand-written route file.

## Conflict Policy

Haxe-owned route emission must fail closed when:

- `config/routes.rb` exists and is not marked as RailsHx-generated.
- Two Haxe route declarations would emit the same helper name.
- A Haxe route declaration cannot be represented as normal Rails routing DSL.
- Generated `rails routes` helper output differs from the expected helper
  manifest.
- A route references a controller/action that cannot be resolved in generated
  Haxe-owned controllers or known Rails-owned app files when that validation is
  enabled.
- `uncheckedRubyRoute(...)` appears without the explicit unsafe define.
- Two `@:railsRoutes` classes target the same output file.

No silent merging, best-effort overwrites, or partially typed route helpers.

## Parity Test Gate

No Haxe-owned routing implementation should land without tests that:

- Emit `config/routes.rb` from Haxe route declarations.
- Run `rails routes` against the generated app.
- Generate `Routes.hx` from that Rails output.
- Assert helper names and required params match the Haxe route manifest.
- Run a Rails runtime request test for at least root, resource collection,
  resource member, namespace, optional segment, and glob route cases.
- Run the same helper generator against a hand-written Rails route fixture and a
  Haxe-emitted route fixture, proving both paths converge to the same extern
  shape.
- Add negative compile tests for missing/non-static `routes`, missing
  controllers/actions, invalid `only`/`except` actions, invalid route aliases,
  invalid path literals, invalid regex constraints, `member`/`collection`
  outside resources, unchecked raw routes without the define, duplicate route
  outputs, and unowned `config/routes.rb` overwrite attempts.
- Add ownership tests for absent files, generated-header rewrites,
  manifest-owned rewrites, unowned file refusal, and unsafe path refusal.

RailsHx must continue to support Rails-owned route helper sync and generator
ergonomics even while greenfield generator-created apps use Haxe-owned routes by
default.

## Implemented Evidence

- `examples/rails_routes_dsl` is the focused compiler fixture for Haxe-owned
  route authoring. It documents each route with source comments and snapshots
  generated `config/routes.rb` plus `.railshx/routes.haxe.json`.
- `scripts/ci/routes-dsl-smoke.js` is the negative/fail-closed fixture. It
  checks invalid declaration hosts, missing actions, bad `only`/`except`
  actions, bad aliases/paths/regexes/constants, unsafe raw routes, duplicate
  outputs, and unowned overwrite attempts.
- `scripts/ci/routes-generator-smoke.js` covers Rails-owned route helper extern
  generation and Haxe-owned parity checks.
- `examples/todoapp_rails` is the end-to-end dogfood app. Its
  `src_haxe/routes/AppRoutes.hx` owns the greenfield routes, while
  `rails/config/routes_rails_owned.rb` demonstrates a Rails-owned adoption
  route that still appears in typed `Routes.hx`.
- `test/snapshots/m1/todoapp_rails/config/routes.rb` and
  `test/snapshots/m1/todoapp_rails/.railshx/routes.haxe.json` prove the
  generated app route artifacts stay stable.

## Remaining Work

- Switch greenfield generators/templates to Haxe-owned routes by default only
  after the docs and generator help output are aligned.
- Keep `Template`/HHX examples using generated route externs, not literal route
  strings.
- Expand parity where it adds RailsHx-specific safety, while continuing to let
  Rails own helper naming and resource expansion.
- Add typed contracts/generators for common gem route macros such as Devise
  before treating them as first-class RailsHx DSL calls.
