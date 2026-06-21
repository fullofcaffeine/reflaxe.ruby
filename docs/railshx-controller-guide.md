# RailsHx Controller And Params Guide

RailsHx controllers should feel like normal Rails controllers with Haxe checking
the parts Rails usually discovers at runtime: strong-param field names,
controller helper calls, filters, response statuses, request/response access,
and render locals.

Rails remains the output contract. RailsHx lowers typed Haxe APIs to ordinary
`ActionController::Base` classes, Rails strong parameters, Rails filters, and
Rails render/redirect/head calls. For the Rails concepts, keep the official
guides nearby:

- [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html)
- [Layouts and Rendering in Rails](https://guides.rubyonrails.org/layouts_and_rendering.html)
- [Action View Overview](https://guides.rubyonrails.org/action_view_overview.html)

The local compiler-architecture inspiration is `../haxe.elixir.codex`: use the
same PhoenixHx lesson of typed surfaces plus macros/registries, but adapt the
output to Rails instead of copying Phoenix concepts directly.

Controllers normally pair with generated typed route helpers from
`routes.Routes`. Those externs are generated from Rails output in both
ownership modes: Rails-owned `config/routes.rb` for adoption apps, or
Haxe-owned `@:railsRoutes` sources that first emit `config/routes.rb`. See
[RailsHx Routing Design](railshx-routing-design.md) and the focused
`examples/rails_routes_dsl` fixture for the route source-of-truth contract.

## Controller Setup

Annotate a Haxe class with `@:railsController` and extend
`rails.action_controller.Base`:

```haxe
package controllers;

import models.Todo;
import rails.action_controller.Status;
import rails.action_view.Template;
import rails.macros.ParamsMacro;
import rails.macros.ViewMacro;
import routes.Routes;
import views.TodoIndexView;
import views.TodoIndexLocals;

@:railsController
class TodosController extends rails.action_controller.Base {
	static final lifecycle = [];

	public function index() {
		var todos = Todo.incomplete()
			.includes(Todo.a.user)
			.order(Todo.f.title.asc())
			.limit(10)
			.toArray();

		var locals:TodoIndexLocals = {
			todos: todos,
			todoCount: todos.length,
			typedColumnCount: Todo.typedColumnCount(),
			sampleUser: null
		};

		ViewMacro.renderTemplate(this, (Template.of(TodoIndexView) : Template<TodoIndexLocals>), locals);
	}

	public function create() {
		var attrs = ParamsMacro.requirePermit(
			this.params(),
			Todo.railsParamKey,
			[Todo.f.title, Todo.f.notes, Todo.f.userId],
			{metadata: ["source"], tags: []}
		);

		Todo.create(attrs);
		flash.notice("Todo queued");
		redirectToOptions({action: "index", status: Status.seeOther});
	}
}
```

Generated Ruby is Rails-shaped:

```ruby
class TodosController < ActionController::Base
  def index()
    todos__hx0 = Models::Todo.incomplete().includes(:user).order(title: :asc).limit(10).to_a()
    locals__hx0 = {todos: todos__hx0, todo_count: todos__hx0.length, typed_column_count: Models::Todo.typed_column_count(), sample_user: nil}
    self.render(template: "controllers/todos/index", locals: locals__hx0)
  end

  def create()
    attrs__hx0 = self.params().require("todo").permit([:title, :notes, :user_id, {metadata: [:source]}, {tags: []}])
    Models::Todo.create(attrs__hx0)
    self.flash()[:notice] = "Todo queued"
    self.redirect_to(action: "index", status: :see_other)
  end
end
```

## Strong Params

Prefer model-owned field refs:

```haxe
ParamsMacro.requirePermit(
	this.params(),
	Todo.railsParamKey,
	[Todo.f.title, Todo.f.notes, Todo.f.userId]
);
```

This checks that refs belong to the same typed params root and lowers Haxe names
to Rails names:

```ruby
self.params().require("todo").permit([:title, :notes, :user_id])
```

Nested strong params use the optional fourth argument:

```haxe
ParamsMacro.requirePermit(
	this.params(),
	Todo.railsParamKey,
	[Todo.f.title],
	{metadata: ["source", "priority"], tags: []}
);
```

Generated Ruby:

```ruby
self.params().require("todo").permit([:title, {metadata: [:source, :priority]}, {tags: []}])
```

The fourth argument exists because mixed Haxe arrays like
`["title", {metadata: ["source"]}]` require an `Array<Dynamic>` cast before the
macro can inspect them. RailsHx keeps the default authoring path cast-free.

Failure modes are compile-time where Haxe has enough information:

```haxe
ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.missing]);
ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [User.f.name]);
```

The first fails because the model has no such field. The second fails because
the permitted field belongs to a different model than the typed params root.

## Lifecycle

Every `@:railsController` class must declare a static `lifecycle` field. Use an
empty declaration list when the controller has no filters or rescues:

```haxe
static final lifecycle = [];
```

Lifecycle declarations are contextual to `@:railsController`. Haxe does not
allow arbitrary function calls directly in a class body, so RailsHx uses the
closest valid-Haxe shape: a static block containing macro calls. The macro calls
validate method, action, and exception references, then the Ruby compiler erases
the field into Rails class macros.

```haxe
import rails.active_record.RecordNotFound;
import rails.action_controller.ForgeryProtectionStrategy;
import rails.action_controller.InvalidAuthenticityToken;
import rails.macros.ControllerDsl.*;

static final lifecycle = {
	protectFromForgery({with: ForgeryProtectionStrategy.exception, prepend: true, except: [index]});
	beforeAction(authenticateUser, {only: [create]});
	afterAction(auditResponse, {only: [create]});
	beforeAction(loadTenant, {except: [index]});
	rescueFrom(RecordNotFound, notFound);
	rescueFrom(InvalidAuthenticityToken, csrfFailure);
}

function authenticateUser() {
	var method = request.requestMethod();
}

function auditResponse() {
	var status = response.status();
}

function loadTenant() {
	var path = request.path();
}

function notFound(e:RecordNotFound) {
	render({plain: "Todo not found", status: Status.notFound});
}

function csrfFailure(e:InvalidAuthenticityToken) {
	render({plain: "Invalid CSRF token", status: Status.forbidden});
}

public function create() {}
public function index() {}
```

Generated Ruby:

```ruby
protect_from_forgery with: :exception, prepend: true, except: [:index]
before_action :authenticate_user, only: [:create]
after_action :audit_response, only: [:create]
before_action :load_tenant, except: [:index]
rescue_from ActiveRecord::RecordNotFound, with: :not_found
rescue_from ActionController::InvalidAuthenticityToken, with: :csrf_failure

def authenticate_user()
  method__hx0 = self.request().request_method()
end
```

This avoids stale lifecycle strings. `authenticateUser`, `create`, and
`RecordNotFound` are Haxe references, not unchecked strings. The compiler
rejects missing callback methods, missing action names in `only`/`except`, and
malformed lifecycle block contents. `rescueFromNamed("Ruby::Constant", handler)`
exists as a checked interop escape when no typed exception extern exists yet.
`protectFromForgery(...)` keeps the Rails concept recognizable while avoiding
raw symbol strings in Haxe: `ForgeryProtectionStrategy.exception` lowers to
`:exception`, and `only`/`except` entries are checked against real controller
actions.

For lower-level Rails parity, `@:railsFilter("before_action", {except:
["index"]})` and method metadata such as `@:beforeAction` remain available for
compatibility, but new RailsHx examples and docs should prefer `lifecycle`.

## Stores, Request, Response, And Status

Rails controller stores are typed facades over Rails runtime objects:

```haxe
flash.notice("Todo queued");
session().set("lastTodoTitle", attrs);
var remembered = session().get("lastTodoTitle");
cookies().delete("staleFilter");
```

Generated Ruby:

```ruby
self.flash()[:notice] = "Todo queued"
self.session()[:last_todo_title] = attrs__hx0
remembered__hx0 = self.session()[:last_todo_title]
self.cookies().delete(:stale_filter)
```

Request/response facades stay Rails-native:

```haxe
var method = request.requestMethod();
var path = request.path();
var wantsJson = request.format().json();
var formatName = request.format().toString();
var negotiatedFormats = request.formats();
var contentMimeType = request.contentMimeType();
var mediaType = request.mediaType();
var wantsPhone = request.variant().phone();
var variantName = request.variant().toString();
var status = response.status();
```

Generated Ruby:

```ruby
method__hx0 = self.request().request_method()
path__hx0 = self.request().path()
wants_json__hx0 = self.request().format().json?()
format_name__hx0 = self.request().format().to_s()
negotiated_formats__hx0 = self.request().formats()
content_mime_type__hx0 = self.request().content_mime_type()
media_type__hx0 = self.request().media_type()
wants_phone__hx0 = self.request().variant().phone?()
variant_name__hx0 = self.request().variant().to_s()
status__hx0 = self.response().status()
```

`request.format()` returns `RequestFormat`, not `Dynamic`, so common MIME
checks such as `html()`, `json()`, `turboStream()`, `xml()`, and `any()` are
completed and type-checked while still lowering to Rails' normal MIME object.
`request.formats()` returns `Array<RequestFormat>`, and
`request.contentMimeType()` returns `Null<RequestFormat>`, so custom
negotiation can stay typed without stringly MIME checks. `request.mediaType()`
is intentionally `Null<String>` because Rails exposes the media type as a
runtime string.
`request.variant()` follows the same rule for Rails variants: `phone()`,
`tablet()`, `desktop()`, and `nativeApp()` lower to the ordinary Rails
`phone?`/`tablet?`/`desktop?`/`native_app?` variant inquirer methods.

Use typed status tokens where Rails expects symbols:

```haxe
render({json: attrs, status: Status.created});
head(Status.noContent);
```

Generated Ruby:

```ruby
self.render(json: attrs__hx0, status: :created)
self.head(:no_content)
```

Use `redirectTo("/path")` for location redirects and
`redirectToOptions({action: "index", status: Status.seeOther})` for Rails
option-hash redirects. Raw string status values are rejected; use `Status.*` or
`Status.named("custom_status")` at the typed boundary.

Use `sendFile(...)` and `sendData(...)` for Rails download responses:

```haxe
sendFile("/tmp/todos.csv", {
	filename: "todos.csv",
	type: "text/csv",
	disposition: SendDisposition.attachment,
	status: Status.ok
});

sendData(csvBody, {
	filename: "todos.csv",
	type: "text/csv",
	disposition: SendDisposition.inlineContent,
	status: Status.ok
});
```

Generated Ruby remains ordinary Rails:

```ruby
self.send_file("/tmp/todos.csv", filename: "todos.csv", type: "text/csv", disposition: "attachment", status: :ok)
self.send_data(csv_body__hx0, filename: "todos.csv", type: "text/csv", disposition: "inline", status: :ok)
```

`SendDisposition.inlineContent` uses the Rails value `"inline"` while avoiding
Haxe's reserved `inline` keyword. Raw string statuses are rejected here too;
use `Status.*` or `Status.named(...)`.

Use `freshWhen(...)` and `stale(...)` for Rails conditional GET helpers:

```haxe
freshWhen({etag: "todos-index"});
var cacheIsStale = stale({weakEtag: "todos-index", template: "controllers/todos/index"});
```

Generated Ruby remains ordinary Rails:

```ruby
self.fresh_when(etag: "todos-index")
cache_is_stale__hx0 = self.stale?(weak_etag: "todos-index", template: "controllers/todos/index")
```

`FreshnessOptions` keeps the common ETag/template kwargs typed and lowers Haxe
camelCase fields such as `weakEtag` to Rails `weak_etag:`. Broader Rails
freshness shapes can be added as typed options instead of raw kwargs when the
compiler has enough evidence to validate them.

Rails `respond_to` blocks use the typed responder collector:

```haxe
respondTo(function(format) {
	format.html(function() {
		redirectToOptions({action: "index"});
	});
	format.json(function() {
		render({json: attrs, status: Status.created});
	});
});
```

Generated Ruby remains ordinary Rails:

```ruby
self.respond_to() do |format|
  format.html() { self.redirect_to(action: "index") }
  format.json() { self.render(json: attrs, status: :created) }
end
```

The responder methods require blocks, so accidental calls such as
`format.json("bad")` fail during Haxe compilation instead of becoming a broken
Rails response branch.

## Rendering Typed Templates

Controllers render RailsHx-owned templates through `Template<TLocals>`:

```haxe
var locals:TodoIndexLocals = {
	todos: todos,
	todoCount: todos.length,
	typedColumnCount: Todo.typedColumnCount(),
	sampleUser: User.first()
};

ViewMacro.renderTemplate(this, (Template.of(TodoIndexView) : Template<TodoIndexLocals>), locals);
```

Haxe checks the locals object before Rails runs. Generated Ruby is ordinary
Action View rendering:

```ruby
self.render(template: "controllers/todos/index", locals: {
  todos: todos__hx0,
  todo_count: todos__hx0.length,
  typed_column_count: Models::Todo.typed_column_count(),
  sample_user: Models::User.first()
})
```

For existing ERB, use `Template.existing("path") : Template<TLocals>` from the
gradual-adoption guide. RailsHx should not overwrite Rails-owned ERB.

## Dev And Test Flow

Use the todoapp as the executable controller reference:

```bash
npm run test:action-controller-params
npm run test:todoapp-rails
npm run test:rails-integration
npm run test:rails-runtime
```

`npm run test:rails-integration` always compiles and syntax-checks generated
Rails Ruby. It runs `rails db:migrate` and Rails tests when local Rails gems are
available. `npm run test:rails-runtime` sets `REQUIRE_RAILS=1` and makes missing
Rails runtime dependencies fail instead of skip.

For browser UX regression coverage:

```bash
npm run test:todoapp-playwright
```

## Design Rules

- Keep controller APIs Rails-shaped. Haxe improves type safety; it does not
  invent a Phoenix clone.
- Prefer generated field refs and typed template refs over strings.
- Use strings only for Rails concepts that are naturally string/symbol-based,
  and keep them inside macros that can fail at compile time where practical.
- Prefer typed facades over `Dynamic`; reserve `Dynamic` for Rails runtime
  objects whose shape is intentionally broad.
- Do not use raw `__ruby__` in app code. If Rails needs a special shape, add a
  typed std facade and compiler lowering, as `PermitSpec` does for nested strong
  params.
