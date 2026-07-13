# RailsHx Skeleton And Todoapp Tutorial

RailsHx is not a Rails replacement. It is a typed Haxe authoring layer that
emits ordinary Rails artifacts. Rails still boots the app, runs migrations,
serves ActionView templates, expands routes, owns Devise/Warden, runs tests,
precompiles assets, and deploys the bundle. Haxe owns source-level contracts,
macros, compile-time validation, HHX views, and generated Ruby/ERB/JS that
Rails can read as if it had been written by hand.

The useful mental model is:

```text
Haxe / HHX / Haxe JS source
        |
        v
RailsHx compiler and generators
        |
        v
ordinary Rails app files: app/haxe_gen, app/views, db/migrate,
config/routes.rb, app/javascript, config/importmap.rb
        |
        v
Rails runtime, Rails tests, Hotwire, Devise, Bundler, assets
```

This guide starts from the generated RailsHx skeleton, then maps those concepts
onto the larger `examples/todoapp_rails` dogfood app.

## Why RailsHx Feels Different

Vanilla Rails is wonderfully direct: models, controllers, routes, ERB views, and
Hotwire all live close to the framework. RailsHx keeps that output shape, but
moves greenfield authoring into typed Haxe.

The differences should be positive:

- Views are Haxe classes with typed HHX render methods, not hand-written ERB
  files. HHX gives Rails a TSX-like authoring experience with parser and type
  checks, but Rails still receives `.html.erb` output and no client view runtime.
- Route helpers, model fields, params keys, template locals, and Turbo hooks are
  typed values instead of repeated strings.
- Controllers can use Rails-shaped APIs while Haxe checks locals, params, and
  current-user flow before Ruby runs.
- Migrations are reviewable Haxe operation snapshots that emit timestamped
  ActiveRecord migrations.
- Haxe-authored browser code can compile through the Genes ES-module lane and
  stay inside Rails' importmap/Turbo conventions.
- Generated files are disposable build artifacts. The source of truth is the
  Haxe/HHX code unless an adoption boundary explicitly says Rails owns the file.

RailsHx should not make simple Rails tasks feel heavier. If a Haxe API requires
more ceremony than Ruby, it should buy clear compile-time safety or be improved
with macros, generated refs, typed facades, or a smaller DSL.

## Create A Skeleton App

For a new or generated RailsHx app, use the Rails-native generator path. From
this repository you can exercise the app generator with:

```bash
rake rails:app ARGS="--output tmp/railshx_app --name MyApp"
```

Inside an installed Rails app, use the app-facing Rails generator:

```bash
bin/rails generate hxruby:install MyApp
```

The generated skeleton includes:

- `.haxerc`, `build.hxml`, and `build-client.hxml`
- `src_haxe/**` server-side Haxe source
- `src_haxe/client/**` or equivalent Haxe-authored browser boot code
- typed HHX layout/page examples
- Haxe-owned route source plus route-helper externs
- Rails importmap/assets wiring
- `lib/tasks/hxruby.rake`
- `bin/railshx-dev` and `bin/railshx-prod`
- app-local docs for wrapping installed gems

That starter is intentionally small but complete. It should boot as a Rails app
while showing the same source/output split used by the todoapp.

## Run The Dev Loop

In a generated RailsHx app, the one-command developer loop is:

```bash
bundle exec rake hxruby:start
```

For active editing, run Rails and the Haxe watchers together:

```bash
bundle exec rake hxruby:start:watch
# or:
WATCH=1 bundle exec rake hxruby:start
# or:
bundle exec rake 'hxruby:start[watch]'
```

The repository dogfood app has the same shape:

```bash
rake todoapp:start
rake todoapp:start:watch
```

The watcher recompiles Haxe/HHX and Haxe-authored JavaScript, then refreshes the
generated Rails app. Rails keeps serving normal Rails files, so most controller
and template changes need only a browser refresh.

When a Rails task consumes generated artifacts, prefer the RailsHx-prefixed
compile-then-delegate wrappers:

```bash
bundle exec rake hxruby:db:migrate
bundle exec rake hxruby:db:prepare
bundle exec rake hxruby:test
bundle exec rake hxruby:rails TASK=zeitwerk:check
```

These tasks compile Haxe-owned Ruby, HHX/ERB, migrations, routes, and client JS
where needed before handing control back to ordinary Rails. Raw `bin/rails`
commands are still valid when generated artifacts are already current; the
wrappers are the safer daily workflow. `hxruby:start:watch` keeps target
artifacts current while you edit, so a separate manual compile is usually not
needed during the dev loop.

## Edit The Skeleton

A generated RailsHx skeleton starts with a small set of source files. The names
vary slightly by generator version, but the pattern is stable.

### Models

RailsHx models are Haxe classes that emit `ApplicationRecord` subclasses:

```haxe
package models;

@:railsModel("todos")
@:railsTimestamps
class Todo extends rails.active_record.Base<Todo> {
  @:railsColumn({nullable: false, index: true})
  public var title:String;

  @:railsColumn({nullable: false, defaultValue: false})
  public var isCompleted:Bool;
}
```

The compiler emits normal Ruby, schema metadata, associations, validations, and
typed refs such as `Todo.f.title`. Use those refs instead of repeating
`"title"` or `:title` in Haxe authoring code.

### Controllers

Controllers stay Rails-shaped, but Haxe checks the calls:

```haxe
@:railsController
class TodosController extends rails.action_controller.Base {
  public function index() {
    var todos = Todo.where({isCompleted: false})
      .order(Todo.f.title.asc())
      .limit(10)
      .toArray();

    ViewMacro.renderTemplate(
      this,
      (Template.of(TodoIndexView) : Template<TodoIndexLocals>),
      {todos: todos}
    );
  }
}
```

The output is ordinary Rails controller Ruby. The win is that template names,
locals, fields, and query shapes are checked before Rails boots.

### Views

RailsHx-owned views are HHX-first:

```haxe
@:railsTemplate("controllers/todos/index")
@:railsTemplateAst("render")
class TodoIndexView {
  public static function render(locals:TodoIndexLocals):HtmlNode {
    return <main class="todo-shell">
      <h1>Todos</h1>
      <for ${todo in locals.todos}>
        <article>${todo.title}</article>
      </for>
    </main>;
  }
}
```

Rails receives `app/views/controllers/todos/index.html.erb`. App authors do not
write raw ERB for RailsHx-owned templates. That is deliberate: HHX lets Haxe
type-check embedded expressions, branch conditions, loop binders, partial
locals, routes, and form fields.

This is more than ERB syntax coloring. Haxe owns the markup AST and the embedded
expressions in one compile, so malformed HHX, unknown locals, wrong helper
arguments, invalid partial-local objects, and supported route/field drift can
fail before Rails boots. Editors also gain completion and rename support across
those typed values. See [Typed Views And HHX](railshx-typed-views.md) for the
guarantees, additional advantages, and limits.

Use `Template.of(ViewClass)` for owned templates/partials. Keep
`Template.existing("legacy/path")` for Rails-owned ERB during adoption.

### Routes

Greenfield RailsHx routes can be Haxe-owned:

```haxe
@:railsRoutes
class AppRoutes {
  static final routes = {
    root(to(TodosController, index));
    resources(Todo, TodosController, {only: [index, create]});
  };
}
```

The compiler emits normal `config/routes.rb`. Rails then remains the helper-name
oracle: run the route sync task and consume generated `Routes.hx` helpers such
as `Routes.todosPath()`.

Existing apps can keep Rails-owned `config/routes.rb`. In that mode RailsHx
only reads `rails routes` and generates typed externs.

### JavaScript And Turbo

RailsHx browser code should layer on normal Hotwire, not replace it. The
todoapp client compiles through Genes to importmap-friendly ES modules and binds
only progressive behavior:

- Turbo lifecycle form feedback
- smooth same-page navigation
- scroll restoration after Rails redirects
- textarea Enter/Shift+Enter handling through a typed helper

The chatroom does not build DOM rows in JavaScript. Rails renders a typed HHX
partial and broadcasts a normal Turbo Stream. That keeps the output pleasant to
Rails developers while Haxe owns safer stream names, targets, templates, locals,
and selectors.

The browser build still uses Haxe's JavaScript typing pipeline, but Genes
replaces the stock final emitter with readable split ES modules. It is not part
of the Ruby server compiler or runtime. See
[Client JavaScript And Genes](railshx-client-javascript.md) for the exact build
and importmap ownership contract.

## Understand Generated Artifacts

Generated Rails files are meant to be readable. You should inspect them when
reviewing compiler changes, but you should not edit RailsHx-owned output by
hand.

Common generated paths:

- `app/haxe_gen/**`: Ruby classes emitted from Haxe models/controllers/services
- `app/views/**/*.erb`: ERB emitted from HHX templates
- `db/migrate/*.rb`: ActiveRecord migrations emitted from Haxe migration snapshots
- `config/routes.rb`: emitted from `@:railsRoutes` when routes are Haxe-owned
- `app/javascript/railshx/**`: Haxe-authored JavaScript output
- `config/initializers/hxruby_autoload.rb`: Rails autoload wiring

The compiler and generators should refuse to overwrite unowned Rails files.
For partial ownership, use manifest/header/marker blocks and fail closed.

## Todoapp Walkthrough

`examples/todoapp_rails` is the canonical dogfood app. It is intentionally more
complete than the starter skeleton because it exercises production-shaped seams:
ActiveRecord, migrations, routes, DeviseHx, HHX, Turbo, Haxe-authored JS, Rails
tests, Playwright, and production smoke.

Run it locally:

```bash
rake todoapp:start:watch
```

Then open `http://127.0.0.1:3000/`.

### DeviseHx Login And Topbar

The app uses real Devise runtime ownership:

- Devise owns Warden, encrypted passwords, session persistence, and redirects.
- `app/auth/UserAuth.hx` owns typed scope/current-user helpers.
- `views/DeviseLoginView.hx` owns the HHX login page that Devise consumes as
  `app/views/devise/sessions/new.html.erb`.
- `views/AppTopBarView.hx` owns the authenticated topbar.
- `controllers/SessionsController.hx` adds a Haxe-owned guest action that calls
  typed `UserAuth.signIn(this, guest)`.
- `devisehx.hhx.AuthLinks` validates the generated `UserAuth.scope` contract in
  HHX and lowers to normal Rails Devise route helpers such as
  `user_session_path` and `destroy_user_session_path`.

The board is protected with:

```haxe
static final lifecycle = {
  beforeAction(UserAuth.authenticate, {});
};
```

That lowers to:

```ruby
before_action :authenticate_user!
```

The result should feel like Rails: unauthenticated users see a Devise login
page, signed-in users see the board, and logout is a standard Rails `button_to`.
Haxe adds typed route helpers, typed current-user access, and checked HHX without
making Devise a RailsHx runtime.

For auth navigation, prefer the DeviseHx HHX tags when they fit:

```haxe
<devise_sign_out_button scope=${UserAuth.scope} class="topbar-logout">
	Log out
</devise_sign_out_button>
```

The tag lowers to Rails' ordinary `button_to "Log out",
destroy_user_session_path(), method: "delete"`. Use `AuthLinks.sessionPath(...)`
or `AuthLinks.signOutPath(...)` inside lower-level `<form_with>`/`<button_to>`
when a custom form shape needs explicit control.

### Server-Owned User Assignment

The todo and chat forms do not render `user_id` hidden fields. The controller
owns authorship:

```haxe
var attrs = ParamsMacro.requirePermit(
  this.params(),
  Todo.railsParamKey,
  [Todo.f.title, Todo.f.notes]
);
attrs = ParamsMacro.mergeField(attrs, Todo.f.userId, currentUser.id);
```

The generated Ruby is ordinary Rails:

```ruby
attrs = params.require("todo").permit([:title, :notes])
attrs = attrs.merge(user_id: current_user.id)
```

This is the RailsHx pattern: keep Rails output idiomatic, but use Haxe refs so
the author cannot typo `user_id` or accidentally permit spoofable params.

### Typed HHX Partials

The todoapp uses small HHX classes instead of raw ERB partials:

- `TodoIndexView.hx`: page shell
- `TodoComposerView.hx`: typed partial composition
- `TodoFormView.hx`: typed Rails form tags
- `TodoListView.hx`: stable Turbo replacement target plus typed loop
- `ChatPanelView.hx`: Turbo Stream subscription and chat form
- `ChatMessageView.hx`: server-rendered Turbo row partial
- `UserManagementView.hx`: Turbo Frame response and direct `/users` fallback

This is close to component thinking, but the output is Rails-native ERB.

### Stable Turbo Targets

Turbo replacement targets must exist in every state. The todo list partial keeps
an outer `railshx-todo-list` wrapper even when there are no rows:

```haxe
return <div id=${TodoHooks.todoListId} class="todo-list-frame">
  <if ${locals.todos.length > 0}>
    ...
  <else>
    <div class="empty-state">No open tasks.</div>
  </if>
</div>;
```

That lets Rails respond with:

```ruby
turbo_stream.replace("railshx-todo-list", partial: "controllers/todos/list")
```

No custom client-side DOM patching is needed.

### Shared Hooks

Behavior-bearing IDs, classes, data attrs, and selectors live in
`shared/TodoHooks.hx`. The app exports them to Playwright through
`tools/ExportTodoHooks.hx`.

This avoids selector drift:

- HHX uses `TodoHooks.chatPanelId`.
- Haxe JS uses `TodoHooks.idSelector(TodoHooks.chatPanelId)`.
- Playwright imports `e2e/todo_hooks.ts`.

Plain styling-only classes can stay in CSS/templates. Cross-file behavior hooks
should be centralized.

## Testing The App

RailsHx uses layered tests:

```bash
npm run test:todoapp-rails
node scripts/rails/todoapp.js test
rake todoapp:playwright
rake todoapp:production
```

Use each layer for the thing it proves:

- Smoke/snapshot-style checks prove generated Ruby/ERB/JS shape.
- Rails tests prove Rails can consume generated routes, controllers, templates,
  models, params, Devise sessions, and migrations.
- Playwright proves browser-visible UX, Turbo, importmap JS, and two-session
  realtime behavior.
- Production smoke proves deployable boot, assets, Zeitwerk, and artifact shape.

Do not use browser tests to retest every compiler detail. Prefer generated
artifact checks for output shape and Rails tests for Rails runtime seams.

## Gradual Adoption

RailsHx must work for existing Rails apps too. In adoption mode, Rails-owned
files remain source of truth:

- keep existing `config/routes.rb`, then generate `Routes.hx` from `rails routes`
- wrap existing ERB with `Template.existing("legacy/badge") : Template<Locals>`
- wrap Ruby services with typed externs or source/RBS-backed contracts
- migrate pieces to Haxe/HHX only when the boundary is stable

This is useful for quick PoCs: build something in vanilla Rails, then add typed
Haxe contracts around the stable parts, then convert selected pieces to Haxe
over time.

## Production Shape

In production, compile RailsHx before Rails finalizes the release:

```bash
bin/railshx-prod
# or:
RAILS_ENV=production bundle exec rake hxruby:production
```

That should produce all Rails-owned runtime inputs before `zeitwerk:check`,
assets, tests, and deployment packaging run.

The production rule is simple: Rails runs the app; Haxe makes the app safer to
author.
