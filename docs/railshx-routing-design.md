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

## Target Mode: Haxe-Owned Route Emission

For greenfield RailsHx apps, Haxe-owned routes should become the preferred
source of truth once parity gates exist. The shape should be a typed Haxe
declaration layer that feels close to Rails' routing DSL, removes avoidable
strings through typed refs where possible, emits normal `config/routes.rb`, then
immediately runs the same route-helper generator from Rails output.

Possible Haxe source:

```haxe
@:railsRoutes
class AppRoutes {
	static function routes(r:RailsRouter):Void {
		r.root("todos#index");
		r.resources("todos", {only: [Index, Create]});
		r.namespace("admin", function(admin) {
			admin.resources("users");
		});
	}
}
```

Generated Rails output must be recognizable Rails:

```ruby
Rails.application.routes.draw do
  root "todos#index"
  resources :todos, only: [:index, :create]
  namespace :admin do
    resources :users
  end
end
```

The emitted file must then be validated by Rails itself:

```bash
bin/rails routes
bin/rails test
```

## Source-Of-Truth Rules

- A project must choose one route source of truth per app or explicit route
  ownership boundary: Rails-owned `config/routes.rb` or Haxe-owned
  `@:railsRoutes`.
- The greenfield RailsHx default should be Haxe-owned after implementation.
- The adoption/migration-safe mode is Rails-owned and must remain supported.
- Haxe-owned route emission must refuse to overwrite an existing non-generated
  `config/routes.rb` unless an explicit force/adopt flag is used.
- Mixed route ownership in one file is not allowed until marker/manifest block
  ownership is designed and tested. If engines need local routing, each
  engine/app boundary needs its own explicit source-of-truth declaration.
- Route helper externs are always generated from Rails output, even when Haxe
  emitted the route file. Rails remains the naming oracle.

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

Until that exists, RailsHx must continue to support Rails-owned route helper
sync and generator ergonomics rather than emitting greenfield routes by default.

## Near-Term Work

- Keep hardening `HXRuby::Generators::Routes` against more `rails routes` output
  variants.
- Add fixtures for mounted engines and nested namespaces before designing
  Haxe-owned route emission.
- Keep `Template`/HHX examples using generated route externs, not literal route
  strings.
- Implement the `@:railsRoutes` bead with parity fixtures and runtime Rails
  tests before switching greenfield generators/templates to Haxe-owned routes.
