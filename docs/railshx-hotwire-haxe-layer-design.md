# RailsHx Haxe-Level Hotwire Layer

RailsHx should expose Hotwire at three Haxe levels, each with a different job:

| Layer | Package | Purpose |
| --- | --- | --- |
| Turbo primitives | `rails.turbo` | Typed access to Turbo events, visits, frames, stream actions, stream names, stream targets, and server-side `TurboStreams.*` helpers. Use this when app code is intentionally working at the Turbo API boundary. |
| DOM compatibility | `rails.dom` | Small typed facades for browser APIs that Haxe's shipped DOM externs do not expose yet, such as `HTMLFormElement.requestSubmit`. This keeps raw `js.Syntax.code(...)` out of apps. |
| Hotwire UX helpers | `rails.hotwire` | Higher-level typed affordances for common Rails/Hotwire behavior that would otherwise become repeated selectors and event listeners in every app. These helpers must still emit ordinary browser/Turbo behavior. |

The goal is not a RailsHx frontend runtime. The goal is typed Haxe authoring for
normal Hotwire patterns.

When an app-local pattern becomes useful twice, move it into one of these
layers. Canonical examples should be small because RailsHx centralizes the
boring contracts: event names, form submission semantics, frame ids, stream
targets, DOM compatibility gaps, and repeated lifecycle binding.

## Concrete Patterns

### Textarea Composer

`rails.hotwire.TextAreaComposer` is the first concrete helper:

```haxe
TextAreaComposer.bindEnterSubmit(form);
TextAreaComposer.clear(form);
```

It implements the chat/composer convention Rails apps often want:

- `Enter` submits the form.
- `Shift+Enter` keeps the native textarea newline.
- IME composition does not submit.
- Submission uses `requestSubmit`, preserving browser validation, Rails CSRF,
  Turbo form submission, and `turbo:submit-*` events.
- Clearing happens after the app has observed a successful Turbo submit.

The todoapp dogfoods this helper so the sample demonstrates Rails-native
Hotwire behavior without app-local raw JS escapes or duplicate client rendering.

### Turbo Frames

RailsHx HHX has a typed `<turbo_frame>` tag:

```haxe
<turbo_frame id=${TodoHooks.userFrameId} class="user-management-frame">
	<div>Frame placeholder</div>
</turbo_frame>
```

The compiler emits ordinary Hotwire HTML:

```erb
<turbo-frame id="<%= ... %>" class="user-management-frame">
  ...
</turbo-frame>
```

Use this for standard Rails/Turbo frame navigation. The todoapp uses a typed
`data-turbo-frame=${TodoHooks.userFrameId}` link and returns a matching
`<turbo_frame>` from the users page, so Turbo performs normal frame extraction.
No custom Haxe fetch, duplicated HTML builder, or client-side router is needed.

## Design Rules

- Prefer `rails.hotwire` when the code is a reusable Hotwire UX pattern.
- Prefer `rails.turbo` when the code maps directly to a Turbo primitive.
- Prefer `rails.dom` when the only gap is a missing browser extern.
- Prefer typed HHX primitives such as `<turbo_frame>` and
  `<turbo_stream_from>` before adding JavaScript.
- Do not hide server-rendered Turbo Streams behind client-side HTML builders.
- Do not add helpers that make Rails behavior less recognizable to Rails
  developers.
- If a helper needs selectors, targets, or storage keys, accept typed constants
  or app-owned hook registries rather than repeated strings.

## Future Helpers

Potential follow-ups:

- `SubmitTracker` for storing per-form submit state and success flashes.
- `StreamSourceStatus` for typed native `turbo-cable-stream-source` status
  affordances.
- `ScrollRestoration` for same-page Turbo form workflows.
- Typed lifecycle binding helpers that centralize `data-railshx-bound`.

These should be added only when the todoapp or another real sample repeats the
pattern enough to justify the abstraction.
