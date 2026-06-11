# RailsHx Roadmap

RailsHx is the Rails-first layer for `reflaxe.ruby`: typed Haxe authoring that emits idiomatic Rails-shaped Ruby. It should grow from the current Rails MVP into a first-class framework integration comparable in architecture to `../haxe.elixir.codex`'s Phoenix/Ecto implementation.

## Current State

The repo currently has a Rails MVP:

- Rails output roots and autoload affordances via `-D reflaxe_ruby_rails`.
- Minimal ActiveRecord model surface through `rails.active_record.Base<T>` and `rails.macros.ModelMacro`.
- Minimal ActionController/strong params surface through `rails.action_controller.Base`, `Params`, and `ParamsMacro`.
- Route helper and scaffold scripts under `scripts/rails`.
- A Rails todoapp example and optional Rails integration smoke coverage.

That MVP is useful, but it is not yet a RailsHx compiler layer. RailsHx should add typed framework APIs, macro metadata registries, generated Rails artifacts, app generators, and end-to-end Rails tests.

## Reference Implementation Pattern

Use `../haxe.elixir.codex` as the local inspiration, especially:

- Ecto schema registration and association validation for ActiveRecord model metadata.
- Ecto typed query APIs for typed `ActiveRecord::Relation` authoring.
- Ecto migration DSL, builder, registry, and validator for Rails migration generation.
- Phoenix typed controller/assign/params boundaries for Rails controller and strong-params boundaries.
- Phoenix router DSL and generated helpers for Rails route helper sync, with Haxe-first routes deferred.
- Mix/project generator docs and end-to-end Phoenix/Ecto examples for RailsHx generators and integration tests.

The goal is not to make Rails look like Phoenix. The goal is to reuse the same successful compiler architecture: typed std surfaces plus macros/registries/tooling that lower into normal framework code.

Official Rails behavior remains the output contract. RailsHx should follow Rails' Active Record query, association, validation, migration, routing, controller, generator, and testing conventions rather than inventing a parallel framework.

## Design Contract

- Keep one Ruby compiler pipeline. RailsHx is not a second backend.
- Use `ruby_first` as the default Rails authoring contract. Ruby/Rails conventions win when there is a real target-specific choice.
- Keep `portable` useful for domain code and shared Haxe modules. Portable code should still emit idiomatic Ruby where behavior-preserving.
- Do not add a Ruby `metal` profile. Performance and runtime policy should use explicit optimizers or runtime defines only if they gain real tests and docs.
- Keep raw `__ruby__` out of app code. Add typed std/runtime wrappers for Rails APIs that need target-specific lowering.
- Emit Rails-native Ruby: `ApplicationRecord`, `ActiveRecord::Relation`, `ActionController`, `config/routes.rb`, timestamped migrations, Rails route helpers, and Rails tests.

## Implementation Roadmap

Tracked by the `RailsHx typed Rails compiler` epic (`haxe.ruby-wpi`):

- `haxe.ruby-wpi.1` (closed): document the RailsHx architecture contract and agent guidance.
- `haxe.ruby-wpi.2`: implement ActiveRecord schema registry and typed column metadata.
- `haxe.ruby-wpi.3`: implement typed `Relation<T>` and ActiveRecord query DSL.
- `haxe.ruby-wpi.4`: implement typed associations, validations, enums, and callbacks.
- `haxe.ruby-wpi.5`: implement typed migration DSL and Rails migration generator.
- `haxe.ruby-wpi.6`: implement typed controllers, params, and action results.
- `haxe.ruby-wpi.7`: harden route helper sync, then design Haxe-first routing.
- `haxe.ruby-wpi.8`: implement RailsHx generators, rake tasks, and adoption tooling.
- `haxe.ruby-wpi.9`: add end-to-end Rails integration app and CI gate.
- `haxe.ruby-wpi.10`: write RailsHx guides and API references.
- `haxe.ruby-wpi.11`: plan post-core Rails surfaces such as ActionMailer, ActiveJob, ActionCable, ActiveStorage, ActionView/Hotwire, and ActiveSupport.

The first implementation slice should prove the complete CRUD path: typed model, typed migration, typed params/controller, typed route helpers, generated Rails Ruby, `rails db:migrate`, and `rails test`.

## Acceptance Bar

RailsHx work is ready when:

- Haxe code type-checks Rails model/query/controller/migration mistakes before Ruby or Rails runtime.
- Generated Ruby is recognizable Rails code a Rails maintainer would accept.
- Framework boundaries are typed in `std/rails/**` or runtime helpers, not scattered as raw app-level injection.
- Fixtures cover successful generated Ruby and negative macro/type failures.
- Rails integration tests compile Haxe, run migrations, boot Rails where available, and execute request/model flows.
- Docs show both Haxe source and generated Rails-shaped Ruby for each major surface.
