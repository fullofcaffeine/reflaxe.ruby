# RailsHx Turbo Guide

RailsHx Turbo support is a typed Haxe facade over Rails-native Hotwire/Turbo
behavior. Haxe authors write checked browser code; Rails still serves normal
importmap assets and Turbo still owns navigation, form submission, frames, and
streams.

## Haxe-Authored Client Philosophy

RailsHx client code should be more ergonomic than hand-written JavaScript or
TypeScript while staying transparent to Rails. The goal is not a parallel Turbo
runtime. The goal is typed authoring for ordinary Turbo behavior:

- Put behavior hooks, DOM ids, data attributes, storage keys, stream targets,
  and selectors behind shared Haxe constants/abstracts that HHX, Haxe JS, and
  Playwright can all consume.
- Prefer typed Turbo event/detail helpers over raw `CustomEvent` casts.
- Prefer small typed behavior helpers for common lifecycle binding, submit
  tracking, stream rendering, frame updates, and fetch-header mutation.
- Keep `js.Syntax.code(...)` at the narrow browser/Turbo boundary when Haxe std
  lacks a typed DOM shape; do not spread raw JS snippets through app code.
- Generated Rails apps should default to the Genes-backed client lane for
  readable ES module output and typed `@:async`/`@:await` authoring, while
  plain Haxe JS remains the minimal fallback.

PhoenixHx uses this architecture for LiveView clients: app-local
`build-client.hxml`, `-lib genes`, typed hook registries shared with templates,
and framework-owned runtime boot. RailsHx should adapt that pattern to
Turbo/importmap rather than copying Phoenix hook APIs directly.

For the broader backend-plus-frontend contract direction, including shared
ActionCable payloads, Turbo Stream targets, HHX partial locals, generated
subscription helpers, and Playwright hooks, see
[RailsHx Full-Stack Hotwire Design](railshx-full-stack-hotwire-design.md).

## Client Events

Use `rails.turbo.Turbo` from Haxe-authored JavaScript:

```haxe
import rails.turbo.Turbo;
import rails.turbo.TurboVisitAction;

class Client {
	static function main():Void {
		Turbo.onBeforeVisit(function(event) {
			var url:Null<String> = event.detail.url;
			if (url != null && url.indexOf("/admin") == 0) {
				event.preventDefault();
			}
		});

		Turbo.visit("/todos", {
			action: TurboVisitAction.Replace,
			frame: "todos"
		});
	}
}
```

This keeps event names and visit actions out of app-level string literals.
Editors should complete `Turbo.onBeforeVisit`, `Turbo.visit`, and
`TurboVisitAction.Replace`.

## Form And Fetch Hooks

Turbo submit and fetch events expose typed structural detail objects:

```haxe
Turbo.onSubmitEnd(function(event) {
	var ok:Null<Bool> = event.detail.success;
	var form = event.detail.formSubmission == null
		? null
		: event.detail.formSubmission.formElement;
});

Turbo.onBeforeFetchRequest(function(event) {
	Turbo.addFetchRequestHeader(event, "X-RailsHx", "typed");
});
```

`Turbo.addFetchRequestHeader(...)` is the preferred typed helper for common
header mutation. `fetchOptions` and `fetchResponse` remain runtime-owned
browser/Rails objects inside the lower-level detail typedefs, so repeated behavior
should live in typed helpers instead of app code touching those objects directly.

For common composer-style behavior, use the higher-level Hotwire helper instead
of wiring keydown listeners in every app:

```haxe
import rails.hotwire.TextAreaComposer;

TextAreaComposer.bindEnterSubmit(form);
TextAreaComposer.clear(form);
```

`bindEnterSubmit` preserves the normal Hotwire path by calling
`requestSubmit`: browser validation, Rails CSRF, Turbo form submission, and
`turbo:submit-*` events all still run. See
[RailsHx Haxe-Level Hotwire Layer](railshx-hotwire-haxe-layer-design.md) for the
package split between `rails.turbo`, `rails.dom`, and `rails.hotwire`.

## Frames And Streams

Frames stay normal `<turbo-frame>` elements in generated Rails output. In HHX,
author them with the typed RailsHx tag:

```haxe
<turbo_frame id=${TodoHooks.userFrameId} class="user-management-frame">
	<div>Frame placeholder</div>
</turbo_frame>
```

The todoapp demonstrates the full standard Hotwire flow: a typed
`data-turbo-frame=${TodoHooks.userFrameId}` link points at `/users`, and the
users page returns the matching `<turbo_frame>` so Turbo extracts it into the
current page. RailsHx adds typed ids and route helpers; Turbo still owns the
navigation.

RailsHx also provides typed client helpers for common frame attributes:

```haxe
import rails.turbo.TurboFrameLoading;
import rails.turbo.TurboFrameTarget;

var frame = Turbo.frameById("todos");
if (frame != null) {
	Turbo.setFrameLoading(frame, TurboFrameLoading.Lazy);
	Turbo.setFrameTarget(frame, TurboFrameTarget.Top);
	Turbo.setFrameSrc(frame, "/todos");
	Turbo.reloadFrame(frame);
}
```

Client-side stream rendering uses Turbo's own runtime:

```haxe
import rails.turbo.TurboStreamAction;

Turbo.renderStreamMessage(
	Turbo.stream(TurboStreamAction.Append, "todos", "<div>Typed</div>")
);
```

The stream helper is intentionally low-level: the `template` argument should
already be trusted/generated HTML.

## Server-Side Streams

Server-side streams use `rails.turbo.TurboStreams`. The Haxe API checks targets,
stream names, typed partial refs, and locals; the compiler emits normal Rails
helpers:

```haxe
import rails.action_view.Template;
import rails.turbo.StreamName;
import rails.turbo.StreamTarget;
import rails.turbo.TurboStreams;

typedef TodoRowLocals = {
	var domId:String;
	var title:String;
	var completed:Bool;
}

class TodoStreams {
	public static inline function listTarget():StreamTarget {
		return StreamTarget.named("todos");
	}

	public static inline function listStream():StreamName<TodoRowLocals> {
		return StreamName.named("todos");
	}
}

var locals:TodoRowLocals = {
	domId: "todo_1",
	title: "Ship typed streams",
	completed: false
};

TurboStreams.append(TodoStreams.listTarget(), (Template.of(TodoRowView) : Template<TodoRowLocals>), locals);
TurboStreams.before(TodoStreams.listTarget(), (Template.of(TodoRowView) : Template<TodoRowLocals>), locals);
TurboStreams.after(TodoStreams.listTarget(), (Template.of(TodoRowView) : Template<TodoRowLocals>), locals);

TurboStreams.broadcastAppendTo(TodoStreams.listStream(), TodoStreams.listTarget(),
	(Template.of(TodoRowView) : Template<TodoRowLocals>), locals);
TurboStreams.broadcastReplaceTo(TodoStreams.listStream(), TodoStreams.listTarget(),
	(Template.of(TodoRowView) : Template<TodoRowLocals>), locals);
```

Generated Ruby stays Rails-shaped:

```ruby
turbo_stream.append("todos", partial: "todos/todo",
  locals: {completed: locals["completed"], dom_id: locals["domId"], title: locals["title"]})
turbo_stream.before("todos", partial: "todos/todo",
  locals: {completed: locals["completed"], dom_id: locals["domId"], title: locals["title"]})
turbo_stream.after("todos", partial: "todos/todo",
  locals: {completed: locals["completed"], dom_id: locals["domId"], title: locals["title"]})

Turbo::StreamsChannel.broadcast_append_to("todos", target: "todos",
  partial: "todos/todo",
  locals: {completed: locals["completed"], dom_id: locals["domId"], title: locals["title"]})
Turbo::StreamsChannel.broadcast_replace_to("todos", target: "todos",
  partial: "todos/todo",
  locals: {completed: locals["completed"], dom_id: locals["domId"], title: locals["title"]})
```

Use typed target/stream constants for app-level names. Plain strings do not
implicitly satisfy server-side stream APIs; use `StreamTarget.named(...)` and
`StreamName.named(...)` at the boundary, then pass the typed constants through
the app. Use
`Template.of(ViewClass) : Template<TLocals>` for RailsHx-owned HHX partials and
`Template.existing("path") : Template<TLocals>` for Rails-owned ERB partials.
The typed action set currently covers `append`, `prepend`, `before`, `after`,
`replace`, `update`, `remove`, and the matching `broadcast*To` helpers.
Pass locals as object literals or typed anonymous-object/typedef values. In both
cases the compiler emits a Rails `locals: {snake_case: ...}` hash. Values typed
as `Dynamic` are treated as explicit Ruby/Rails-owned runtime hashes and are
passed through unchanged.

## Rails Workflow

In RailsHx apps, Haxe-authored JS compiles into importmap-friendly assets under
`app/javascript/railshx`:

```bash
bundle exec rake hxruby:compile:client
bundle exec rake hxruby:watch:client
```

The default RailsHx starter and the todoapp sample wire this through
`build-client.hxml` with Genes:

```hxml
-cp ${HXRUBY_GEM_ROOT}/std
-lib genes
-D js-es=6
--macro genes.Generator.use()
--macro addMetadata('@:genes.disableNativeAccessors', 'haxe.Exception')
-D js-unflatten
```

Genes keeps Haxe-authored client code in readable ES modules, which fits Rails'
importmap/Propshaft defaults better than a single flattened JavaScript blob. The
entry asset is still imported from `app/javascript/application.js` alongside
`@hotwired/turbo-rails`, while relative module imports stay inside
`app/javascript/railshx/**`.

RailsHx rake tasks set `HXRUBY_GEM_ROOT` before invoking Haxe so generated apps
can resolve the typed RailsHx client std and vendored Genes source shipped with
the `hxruby` package. After client compilation, `hxruby:compile:client` rewrites Genes' relative
`./module.js` imports to bare `railshx/module` importmap specifiers; this keeps
Rails asset digests from breaking nested module imports in development or
production. Direct manual `haxe build-client.hxml` runs should either happen
through those rake tasks or run the same rewrite step.

## Async/Await

Use `reflaxe.js.Async` for typed native async browser code:

```haxe
import js.html.Element;
import reflaxe.js.Async;

class TodoClient {
  @:async
  static function hideAfterDelay(element:Element):Void {
    @:await Async.delay(2200);
    element.setAttribute("hidden", "hidden");
  }
}
```

`@:async` is standard Haxe metadata consumed by Genes when it emits the ES
module. `@:await expr` is parser-valid Haxe expression metadata that RailsHx
desugars to the typed `await(expr)` helper, which then lowers to native
JavaScript `await`. The generated JavaScript is ordinary browser code:

```js
static async hideAfterDelay(element) {
  await Async.delay(2200);
  element.setAttribute("hidden", "hidden");
}
```

Inline callbacks can use `Async.async(() -> { ... })` when a callback expression
itself needs to become an async function. Prefer method-level `@:async` for
named behavior because it gives better stack traces and clearer generated JS.
The classic `await(promise)` helper remains supported and is useful when extra
parentheses make a complex expression clearer; prefer `@:await promise` for
straight-line RailsHx client code because it reads closer to JavaScript/TypeScript.

## Tests

Use the static Turbo smoke for typed API coverage:

```bash
npm run test:turbo
npm run test:turbo-streams
```

Use the real-browser todoapp sentinel for Rails/importmap/Turbo integration:

```bash
npm run test:todoapp-playwright
```

`npm test` includes the static Turbo and Turbo Streams smokes. Browser and Rails
runtime lanes stay separate so local compiler work remains fast while CI can
require full Rails coverage.
