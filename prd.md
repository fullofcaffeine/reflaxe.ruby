Haxe macros vs Ruby metaprogramming (and “stricter?”)

They’re cousins, but they live on different planes of reality:

Ruby metaprogramming is runtime reality-bending. You can define_method, reopen classes, intercept calls with method_missing, etc. It’s alive while the program runs. That gives you insane flexibility, but it also means the “shape” of your program can change depending on code paths, load order, environment, gems, and moon phases.

Haxe macros are compile-time reality-bending. They run before you have a program. You can:

inspect types (including generics),
generate fields/methods/classes,
rewrite expressions,
enforce compile-time policies,
and emit extra files.

That’s stricter in the sense that:

macros operate on the typed AST (abstract syntax tree) and type info,
you can enforce constraints and produce errors early,
but you can’t (directly) react to runtime values.

So yeah: Haxe macros are “as powerful” as Ruby metaprogramming for many categories (DSLs, boilerplate erasure, codegen), but they’re powerful in a different direction: “make illegal states unrepresentable” instead of “anything goes at runtime.” If the goal is Rails ergonomics plus compile-time safety (especially around ActiveRecord), Haxe macros are a perfect weapon.

Reflaxe target template (extracted patterns from reflaxe.rust / reflaxe.ocaml / reflaxe.elixir + genes-ts)

This is the reusable “new target” template you can follow for reflaxe.<target> repos.

1) Repo layout (common baseline)

Required

.github/workflows/
ci.yml (tests + security checks)
release.yml (semantic-release packaging)
haxe_libraries/
reflaxe.hxml (pins reflaxe framework, either vendored or via lix cache)
reflaxe.<target>.hxml (the self-referential -lib reflaxe.<target> entrypoint)
src/
reflaxe/<target>/
CompilerBootstrap.hx (macro-only, earliest classpath injection / gating)
CompilerInit.hx (registers compiler via ReflectCompiler.AddCompiler)
<Target>Compiler.hx (main backend)
CompilationContext.hx (per-build state and caches)
naming/ (identifier rules + keyword escaping)
ast/ (target IR + printer; optional transformer)
optional: macros/, preprocessor/, runtimegen/
std/
target-facing externs and helper APIs
optionally std/<target>/_std/ for Haxe std overrides, injected only when targeting this backend
haxelib.json
package.json (lix toolchain + semantic-release scripts)
scripts/
release/sync-versions.* (keeps package.json, haxelib.json, haxe_libraries/*.hxml in sync)
ci/version-sync-check.* (CI guardrail)

Common optional

runtime/ (target runtime code copied/emitted into output)
test/ (fixtures + expected outputs, snapshot harness)
2) Bootstrap + init pattern (the “two-stage ignition”)

CompilerBootstrap (macro-only)

Purpose: ensure anything needed to type the compiler itself is available before Haxe starts typing target modules.
Common responsibilities:
add std/ always (or conditionally)
add std/<target>/_std only when building for this target
add vendor/reflaxe/src if you vendor reflaxe
do early “target gating” based on defines / platform

CompilerInit

Purpose: register the compiler with Reflaxe and configure codegen behavior.
Responsibilities:
gate on target (Haxe 5 CustomTarget("...") if available; defines fallback)
call ReflectCompiler.Start() if needed (or rely on reflaxe.hxml)
set expression preprocessors (defaults + custom)
call ReflectCompiler.AddCompiler(new <Target>Compiler(), config)

The config consistently includes:

fileOutputExtension
outputDirDefineName
fileOutputType (usually FilePerModule)
targetCodeInjectionName (e.g. __rust__, __ocaml__, __elixir__)
ignoreExterns: true (externs are type-only; you emit requires/imports separately)
trackUsedTypes: true (when you need dependency-aware imports/requires)
3) “Profiles” pattern (portable vs idiomatic vs native interop)

Rust explicitly has Portable / Idiomatic / Rusty. The general pattern is:

Portable: preserve Haxe semantics; runtime helps; fewer target idioms.
Idiomatic: still framework-first, but emits nicer target code.
Native/Interop: leans into target ecosystem patterns/APIs.

This pattern exists because:

porting Haxe code wants predictability,
writing “native” target code wants idioms,
and sometimes those conflict.
4) Policy enforcement pattern (keep examples honest)

Rust uses:

a BoundaryEnforcer for repo examples/snapshots (no raw __target__ escapes)
a StrictModeEnforcer for user projects (opt-in: forbid code injection)

This is a good default for new targets because it forces “missing features” into reusable Haxe APIs instead of scattered raw injections.

5) Framework integration pattern (Phoenix as the model)

reflaxe.elixir shows a full “framework-in-the-stdlib” approach:

typed extern surfaces in std/phoenix
macros that validate keys/types at compile time (e.g. AssignMacro)
generator tasks that are “Haxe-first” (generate Haxe sources; compilation generates framework code)

That’s exactly the shape you want for Rails.

PRD: reflaxe.ruby (Haxe → idiomatic Ruby, with Rails-first typed APIs)
0) Executive summary

Build reflaxe.ruby, a Reflaxe-based Haxe compilation target that outputs idiomatic Ruby and supports Rails as a first-class framework via typed externs + macro-powered code generation.

Why now
Ruby + Rails have stable conventions (naming, file layout, autoloading, DSLs).
Ruby 4.0 shipped recently (Ruby 4.0.0 on 2025‑12‑25; 4.0.1 on 2026‑01‑13).
Rails is on 8.1.x (Rails 8.1.2 released Jan 2026).
Rails 8.0/8.1 require Ruby ≥ 3.2.0.
So the baseline runtime can assume modern Ruby features like pattern matching (introduced 2.7, stabilized 3.0) and Data.define (Ruby 3.2).
1) Goals
G1: Ruby output is idiomatic by default

Generated Ruby should look like something a Rails dev would accept in a PR:

snake_case methods/locals
CamelCase constants/modules
Ruby blocks where safe/appropriate
keyword args where appropriate
stable formatting (2-space indentation)
G2: “Rails-first” typed ergonomics in Haxe

Provide typed Rails APIs in Haxe that:

map 1:1 to Rails concepts (ActiveRecord, controllers, params, routes),
improve safety (typed columns, typed where, typed params),
avoid “API cliff” (don’t force a totally alien DSL).
G3: Minimal runtime (hxruby), maximum leverage of Ruby core

Prefer Ruby’s native classes (Array, Hash, String, Integer) instead of heavy wrapper types, but supply a runtime for Haxe-specific semantics where needed (enums, exceptions, reflection helpers).

G4: Tooling + examples match existing target repos
examples like other targets
a Rails todoapp showcasing:
typed model
typed controller/actions
typed params (strong parameters)
associations/validations
migrations generation (at least for the example)
G5: A path to “strict mode”

Allow opting out of __ruby__ escape hatches for “pure Haxe” projects, mirroring the policy approach in reflaxe.rust.

2) Non-goals (for 1.0)
Perfect byte-for-byte parity with Haxe stdlib behavior (unless portable profile is enabled).
Full Rails surface area on day 1 (ActionCable, ActionMailer, ActiveJob, etc. can be phased).
Full Sorbet/RBS integration (nice future add-on; not required).
Ruby C-extension interop.
3) Target versions / compatibility
Ruby runtime: Ruby ≥ 3.2 (to align with Rails 8+)
Ensure compatibility with Ruby 4.0 as well.
Rails: Rails 8.0+ (example todoapp on 8.1.x).
Haxe: Haxe 5.x primary (support Haxe 4.x only if Reflaxe + ReflectCompiler path allows; otherwise document Haxe 5 requirement).
4) Product shape
4.1 Deliverables (what ships)
reflaxe.ruby haxelib package (compiler + std)
hxruby runtime (Ruby code)
either shipped as copyable runtime directory
and/or packaged as a Ruby gem (recommended for Rails integration)
std/ruby externs + helpers
std/rails typed Rails externs + macros
Examples:
examples/hello_world
examples/ruby_interop (extern + require + block/kwargs)
examples/todoapp_rails (full Rails app)
5) Profiles / modes
Recommendation

Implement two public profile contracts and make them feel optional and non-annoying:

Default: ruby_first
Ruby-first contract
Ruby-native types
snake_case output
blocks/kwargs
minimal runtime
Ruby/Rails conventions win when they conflict with cross-target portability

Optional: portable
Haxe-semantics-first contract
closer to Haxe semantics
more runtime helpers (e.g., to emulate certain std behaviors)
Ruby idioms are still preferred when behavior is preserved
Haxe behavior wins when Ruby/Rails conventions would drift semantics

Both profiles should generate idiomatic Ruby whenever possible. `portable` is not an "unidiomatic Ruby" mode; it is the contract that refuses to sacrifice Haxe portability merely to look more native.

Do not add a public `metal` profile for Ruby by analogy with `haxe.rust` or `haxe.go`. Ruby performance should be handled through explicit optimizer/runtime defines until a third profile has a real, tested, documented contract.

Config

-D reflaxe_ruby_profile=ruby_first|portable
fallback define aliases:
-D reflaxe_ruby_profile=idiomatic (legacy alias for ruby_first)
-D ruby_first
-D ruby_portable
-D ruby_idiomatic
6) Compiler architecture
6.1 Pipeline

Typed Haxe AST → Ruby IR (AST) → Ruby pretty printer → files

Mirrors rust/ocaml structure:

Ruby AST keeps precedence correct and formatting stable.
Printer is deterministic and “boring”.
6.2 Core modules (template-applied)
src/reflaxe/ruby/CompilerBootstrap.hx
supports source/package classpath fallback; `haxe_libraries/reflaxe.ruby.hxml`
declares std/, std/ruby/_std, and vendored reflaxe for Ruby target builds
src/reflaxe/ruby/CompilerInit.hx
gates on Ruby target (CustomTarget("ruby") for Haxe 5, -D ruby_output fallback)
registers compiler with:
fileOutputExtension: ".rb"
outputDirDefineName: "ruby_output"
fileOutputType: FilePerModule
targetCodeInjectionName: "__ruby__"
ignoreExterns: true
trackUsedTypes: true
src/reflaxe/ruby/RubyCompiler.hx
src/reflaxe/ruby/RubyOutputIterator.hx
src/reflaxe/ruby/CompilationContext.hx
src/reflaxe/ruby/ast/* (Ruby IR + printer)
src/reflaxe/ruby/naming/RubyNaming.hx
src/reflaxe/ruby/macros/*
BoundaryEnforcer (repo examples)
StrictModeEnforcer (user opt-in)
RequireRegistry (collect require/require_relative from metadata)
6.3 Output structure rules
File-per-module.
Ruby file path must align with constants for autoloaders (especially Rails Zeitwerk):
Module/class Foo::BarBaz → foo/bar_baz.rb
For non-Rails apps:
emit a main.rb (or app.rb) entrypoint requiring generated files and calling main.
7) Code generation rules (Ruby-first/default profile)

This is the “compiler contract” the implementation must follow.

7.1 Naming
Ruby constants/modules/classes: UpperCamelCase
Ruby methods/locals/ivars: snake_case
Escape Ruby keywords by suffixing _ (or a stable alternative) when needed.

Ruby keyword set must include: class, module, def, end, if, else, elsif, case, when, in, while, until, for, do, yield, return, break, next, redo, retry, rescue, ensure, begin, nil, true, false, and, or, not, super, self, etc.

7.2 Classes / modules
Haxe package a.b; class C → Ruby:
module A; module B; class C; ... end; end; end
or configurable “flat constants” mode for Rails contexts.
7.3 Fields and properties

Map Haxe properties to Ruby accessors:

public var x:T; → attr_accessor :x + @x
public var x(default, null):T; → attr_reader :x
get/set properties generate methods x and x=.
7.4 Static members
Haxe static function foo() → Ruby def self.foo ... end
Haxe static var X = ...:
if constant-like: Ruby X = ... (optional)
otherwise: @x = ... + def self.x; @x; end / def self.x=(v); @x=v; end
7.5 Functions and lambdas
Haxe function values compile to Ruby lambdas (->) to preserve return semantics.
Block emission (idiomatic) is allowed only when semantics are safe:
compiler can emit { |x| ... } / do ... end when:
the function is passed as the final argument to a call marked “block-arg”
and any return in the Haxe lambda is translated safely (prefer next where legal).
Provide a metadata-driven system on externs:
@:rubyBlockArg(index=-1) indicates the arg becomes a Ruby block.
@:rubyKwargs indicates object literal becomes keyword args.
7.6 Enums (Haxe ADTs)

Use Ruby 3.x features for clean, matchable representations:

Represent each enum as a Ruby module.
Represent constructors as Data.define(...) classes (Ruby ≥ 3.2).
Switch-on-enum should use Ruby pattern matching (case … in …).

Example (spec-level, not final syntax):

Haxe:
enum Option<T> { None; Some(v:T); }
Ruby:
module Option; None = Data.define; Some = Data.define(:v); end
7.7 Exceptions and throw

Because Haxe can throw any value:

Implement runtime HxException < StandardError that carries value and (optionally) type tags.
Compile throw expr → raise HxException.new(expr)
Compile catch (e:T) to:
rescue HxException => e
then runtime/type-tag check + re-raise if mismatch
7.8 switch
Switch on enums: Ruby pattern matching in
Switch on constants: Ruby case + when (but ensure semantics aren’t accidentally ===-special-cased)
Switch expression returns value: Ruby case expression returns value naturally.
7.9 Collections
Haxe Array<T> → Ruby Array
Haxe Map<K,V> → Ruby Hash (key semantics documented)
Provide minimal helpers in hxruby runtime for:
Std.string
Type/Reflect basics (as needed)
EReg mapping to Ruby Regexp (with compatibility notes)
8) Haxe stdlib strategy for Ruby
8.1 std/ vs std/ruby/_std

Follow ocaml/rust pattern:

std/ contains Ruby-facing externs and helper APIs always safe to have on classpath.
std/ruby/_std contains overrides that should only apply when targeting Ruby.

Library split

`reflaxe.ruby` is the Ruby target compiler library and includes source-layout
`std/ruby/_std`.

`railshx.client` is the browser/client helper library and includes only the
shared/browser-safe `std/` surface.
8.2 Parity scope (for 1.0)

Minimum to support Rails apps and typical Haxe code:

Std, StringTools (or equivalents), Sys, Date, EReg, haxe.ds.* basics, haxe.io.* as needed
Provide a “gap report” JSON (like reflaxe.elixir) to track missing surfaces.
9) Ruby interop (externs + requires)
9.1 Extern mapping rules
extern class should not be emitted (ignoreExterns = true)
but compiler must support imports/requires for extern usage:
@:rubyRequire("json") → require "json"
@:rubyRequireRelative("./lib/foo") → require_relative "..."
9.2 @:native mapping

Support Ruby constants:

@:native("ActiveRecord::Base")
@:native("ActionController::Base")

Support method renames:

@:native("find_by") for Ruby snake_case
9.3 Symbols and keyword args

Add std/ruby/Symbol.hx similar to Elixir Atom idea:

allow ("created_at": ruby.Symbol) to compile to :created_at
macros may auto-convert Haxe camelCase fields to snake_case symbols
10) Rails support (the big one)

Rails support is split into:

Compiler-level affordances (output paths, autoloading friendliness, blocks/kwargs)
Typed Rails stdlib (std/rails/*) + macros (compile-time safety)
Rails integration tooling (rake tasks / generator / gem packaging)
10.1 Rails integration constraints
Rails autoloading expects file paths that match constants.
Rails 8+ assumes Ruby ≥ 3.2.
Generated code should live in a dedicated directory (recommended):
app/haxe_gen/**
Add to config.autoload_paths and config.eager_load_paths.
10.2 Typed Rails stdlib structure

Proposed std/rails layout:

rails/ActiveRecord.hx
Base, Relation<T>, Query<T>, ValidationErrors, etc.
rails/ActionController.hx
Base, Params, StrongParams<T>, Redirect, Render, etc.
rails/Routing.hx
typed route helpers generation target (see 10.5)
rails/ActiveSupport.hx
Concern, TimeZone, Notifications (gradual)

Plus std/rails/macros:

ModelMacro (columns, associations, validations)
ParamsMacro (typed strong params)
RoutesMacro (typed route helper generation, optional)
MigrationMacro (optional: migration codegen)
10.3 Typed ActiveRecord: core design

Design principle: keep Rails APIs recognizable, but make the unsafe parts typed.

10.3.1 Model declaration (Haxe-first)

A model class in Haxe declares:

table name (optional; default inferred)
columns (typed)
associations (typed)
validations (typed-ish)

Example Haxe (spec-level):

package app.models;

@:railsModel("todos")
class Todo extends rails.ActiveRecord.Base<Todo> {
  @:column public var title:String;
  @:column public var completed:Bool;

  @:belongsTo public var user:rails.ActiveRecord.BelongsTo<User>;

  @:validates({presence: true})
  public var titleValidation:rails.ActiveRecord.Validation<String>;
}

Macro responsibilities:

validate metadata correctness
generate typed helpers:
Todo.where({ completed: true }) : Relation<Todo>
Todo.create({ title: "...", completed: false }) : Todo
generate Ruby class body:
class Todo < ApplicationRecord
belongs_to :user
validates :title, presence: true
10.3.2 Typed where and friends

Provide a minimal typed query interface:

object-literal style (most Rails-like):
Todo.where({ completed: true, title: "x" })
compile to Todo.where(completed: true, title: "x")
macro checks:
keys exist as columns/associations
value types match

Optionally later:

expression DSL:
Todo.where(Todo.c.title.eq("x").and(Todo.c.completed.isTrue()))
more work; defer unless it’s clearly worth it.
10.3.3 Associations

Provide typed wrappers:

BelongsTo<T>, HasMany<T>, HasOne<T>
Macro ensures:
target type is a model
generated Ruby uses correct association name (snake_case, pluralization helper)
10.4 Typed controllers + params
10.4.1 Controller extern surface

rails.ActionController.Base maps to Rails controller base.

10.4.2 Typed Strong Parameters

Create a Haxe pattern like:

typedef TodoParams = {
  title:String,
  completed:Bool
}

class TodosController extends rails.ActionController.Base {
  public function create() {
    var p:TodoParams = params.require("todo").permit(TodoParams);
    Todo.create(p);
    redirectTo(todosPath());
  }
}

Macro responsibilities:

permit(TodoParams) expands to Ruby permit(:title, :completed)
keys auto snake_case
optional/default fields handled

This gives you Rails ergonomics without the typical “permit list typo” foot-gun.

10.5 Routes: typed helpers (gradual)

Two viable approaches. The PRD recommends doing A for 1.0 and B later.

A) Generator-based (recommended for 1.0)

Provide a Rails task that runs rails routes and generates src_haxe/routes/Routes.hx
Routes.hx contains typed externs for path/url helpers (e.g. todos_path, todo_path(id))
Compiler just compiles it; no need to parse Ruby DSL.

B) Haxe-first routes

Define routes in Haxe and emit config/routes.rb
cooler, but bigger surface + higher risk
10.6 Migrations (for todoapp + path forward)

For 1.0, migrations can be “MVP usable”:

A Haxe-first generator creates:
model class
migration file template (Ruby)
Later phases: use macros to generate migrations from @:column metadata.
11) Todoapp (Rails) specification
11.1 Features
Todo model: title, completed, timestamps
basic CRUD
validations: title presence
index page lists todos
create/update/delete
minimal styling (not the focus)
11.2 What must be authored in Haxe
model (Todo.hx)
controller (TodosController.hx)
typed params typedef(s)
route helper externs (generated) OR manual for MVP
11.3 What can remain in Ruby for MVP
views (ERB)
config/initializers
environment config
This keeps scope sane while still proving the core value: typed Rails logic.
12) Tooling
12.1 CLI (optional but strongly recommended)

Mirror reflaxe.elixir’s pattern:

haxelib run reflaxe.ruby create <name> --type rails|basic
generates:
a Ruby/Rails project skeleton
src_haxe/ + build.hxml
adds autoload paths
adds hxruby runtime (gem or vendored)
12.2 Rails tasks (if using gem)

Ship hxruby as a gem containing:

runtime code
rake tasks:
rails hxruby:compile
rails hxruby:watch
rails hxruby:gen:model
rails hxruby:gen:routes
13) Testing & QA plan
13.1 Compiler fixture tests (fast)
test/fixtures/**
each fixture: src/Main.hx, build.hxml, expected/**/*.rb and/or expected.stdout
test harness:
compile → compare generated Ruby snapshot
optionally run Ruby → compare stdout
13.2 Ruby runtime tests
run Ruby unit tests for hxruby (minitest)
ensure HxException, enum representation, etc.
13.3 Rails integration tests
in todoapp example:
rails test (or request specs)
compile step in CI before running tests
13.4 CI matrix
Ruby: 3.2, 3.3, 4.0 (at least)
Haxe: pinned (like other repos)
OS: ubuntu-latest first; add mac/windows later
14) Repo skeleton for reflaxe.ruby (concrete)
.github/workflows/
  ci.yml
  release.yml
haxe_libraries/
  reflaxe.hxml
  reflaxe.ruby.hxml
scripts/
  ci/version-sync-check.js
  release/sync-versions.js
src/
  reflaxe/ruby/
    CompilerBootstrap.hx
    CompilerInit.hx
    RubyCompiler.hx
    RubyOutputIterator.hx
    CompilationContext.hx
    naming/RubyNaming.hx
    ast/RubyAST.hx
    ast/RubyASTPrinter.hx
    ast/RubyASTTransformer.hx   (optional)
    macros/StrictModeEnforcer.hx
    macros/BoundaryEnforcer.hx
    macros/RequireRegistry.hx
std/
  ruby/
    Symbol.hx
    Kernel.hx (externs for puts, etc)
  rails/
    ActiveRecord.hx
    ActionController.hx
    Routing.hx
    macros/ModelMacro.hx
    macros/ParamsMacro.hx
runtime/
  hxruby/
    lib/hxruby.rb
    lib/hxruby/exception.rb
    lib/hxruby/enum.rb
    hxruby.gemspec
examples/
  hello_world/
  ruby_interop/
  todoapp_rails/
haxelib.json
package.json
README.md
CHANGELOG.md
LICENSE
15) Milestones (implementation plan)
M0: Compiler boots and emits Ruby
compiler registers
ruby_output works
emits main.rb + a module file
can run ruby main.rb
M1: Core language subset
expressions, locals, if/while/for, arrays/hashes
classes + methods + fields
function values as lambdas
M2: Enums + switch + exceptions
enum representation via Data.define
switch on enums via pattern matching
throw/try/catch via HxException
M3: Stdlib MVP
enough std overrides to compile typical code + Rails wrappers
runtime hxruby included and wired
M4: Ruby interop polish
@:native, @:rubyRequire, symbols, kwargs, block args metadata
M5: Rails MVP + todoapp
ActiveRecord base + typed where/create
controller base + typed params macro
todoapp builds and runs
M6: Ergonomics upgrades
associations typed
validations typed-ish
routes extern generator task
better output idioms (blocks/kwargs) where safe
M7: 1.0 hardening
docs + gap report
stable code formatting and deterministic outputs
CI matrix green
strict mode policy solid
Low priority note: “Rails ↔ Phoenix portability layer” (post‑1.0)

The clean way to do this is not “make Rails look like Phoenix” or vice versa. It’s to define a tiny Haxe-first web kernel that both can target:

hx.web.Router (route declarations)
hx.web.Controller (request/response abstraction)
hx.db.Model<T> (CRUD + validations + relations as capabilities)
adapters:
hx.rails.* emits Rails controllers/models/routes
hx.phoenix.* emits Phoenix controllers/schemas/router

A plausible POC (gist-level):

define a Todo model and TodosController once in the kernel
generate Rails and Phoenix backends that both implement:
list/create/update/delete
validation errors
prove that 80% of “boring CRUD” is portable, while framework-specific features remain framework-specific.

The compiler reaching 1.0 is the right gate before doing this, because the portability layer will amplify whatever sharp edges exist.

If you want this PRD in a format that Codex can consume even more mechanically (a “task list spec” with explicit file-by-file TODOs and acceptance tests per milestone), I can rewrite it into that style without changing the content.
