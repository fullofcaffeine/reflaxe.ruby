# RailsHx Turbo Guide

RailsHx Turbo support is a typed Haxe facade over Rails-native Hotwire/Turbo
behavior. Haxe authors write checked browser code; Rails still serves normal
importmap assets and Turbo still owns navigation, form submission, frames, and
streams.

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
	if (event.detail.fetchOptions != null) {
		js.Syntax.code(
			"{0}.headers = Object.assign({}, {0}.headers || {}, {'X-RailsHx': 'typed'})",
			event.detail.fetchOptions
		);
	}
});
```

`fetchOptions` and `fetchResponse` remain `Dynamic` because Turbo forwards
browser/Rails runtime objects there. Keep raw JavaScript at the smallest possible
boundary and wrap repeated behavior in typed helpers.

## Frames And Streams

Frames stay normal `<turbo-frame>` elements. RailsHx provides typed helpers for
common frame attributes:

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
already be trusted/generated HTML. Server-side Rails stream helpers and
broadcasting remain future work and should lower to normal Rails
`turbo_stream.*`/broadcast APIs, not a RailsHx runtime.

## Rails Workflow

In RailsHx apps, Haxe-authored JS compiles into importmap-friendly assets under
`app/javascript/railshx`:

```bash
bundle exec rake hxruby:compile:client
bundle exec rake hxruby:watch:client
```

The todoapp sample wires this through `examples/todoapp_rails/build-client.hxml`
and imports the compiled asset from `app/javascript/application.js` alongside
`@hotwired/turbo-rails`.

## Tests

Use the static Turbo smoke for typed API coverage:

```bash
npm run test:turbo
```

Use the real-browser todoapp sentinel for Rails/importmap/Turbo integration:

```bash
npm run test:todoapp-playwright
```

`npm test` includes the static Turbo smoke. Browser and Rails runtime lanes stay
separate so local compiler work remains fast while CI can require full Rails
coverage.
