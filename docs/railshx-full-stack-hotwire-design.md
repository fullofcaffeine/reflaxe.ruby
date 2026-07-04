# RailsHx Full-Stack Hotwire Design

RailsHx can do something vanilla Rails, JavaScript, and TypeScript cannot do as
comfortably: keep server HHX, generated Ruby, browser JavaScript, ActionCable
payloads, Turbo Stream targets, routes, params, and browser tests on one typed
Haxe contract surface.

The goal is not a new frontend framework. The goal is better Rails Hotwire:
Haxe authors get typed contracts and compile-time drift checks, while Rails
still receives ordinary `ActionCable::Channel::Base`, `turbo_stream.*`,
`Turbo::StreamsChannel.broadcast_*_to`, importmap assets, and browser Turbo
runtime calls.

## Motivation

The todoapp chatroom now proves the Rails-native baseline:

- `views/ChatPanelView.hx` subscribes with typed HHX
  `<turbo_stream_from stream=${...} />`.
- `views/ChatMessageView.hx` owns the typed row partial.
- `shared/ChatRoomHooks.hx` owns browser-safe stream and readiness hook
  constants, while `shared/ChatRoomContract.hx` adds typed Turbo stream,
  target, template, and locals helpers for server HHX/controllers.
- `controllers/ChatMessagesController.hx` creates an ActiveRecord row, then
  broadcasts the server-rendered HHX partial through
  `TurboStreams.broadcastPrependTo(...)`.
- `client/TodoClient.hx` stays out of chat DOM mutation and only owns
  progressive browser behavior such as form/session hooks and transient flashes.
- `shared/TodoHooks.hx` centralizes DOM ids, classes, selectors, storage keys,
  and Playwright hooks.
- Playwright opens two browser sessions and verifies realtime delivery through
  Rails/Turbo, not a custom client renderer.

That is the canonical path. Haxe-owned ActionCable channels and client
subscriptions remain valuable for custom payload protocols, presence, telemetry,
canvas/charts, and other non-DOM or deliberately client-owned behavior, but a
basic Rails list/panel update should not need more code than a classic Hotwire
app.

## Principles

- Rails owns runtime behavior. ActionCable transports, Turbo mutates the DOM,
  Rails renders templates, and Rails route/helper naming remains Rails-owned.
- Haxe owns contracts. Stream names, targets, payloads, partial locals, DOM
  hooks, route refs, params roots, and test selectors should be typed or
  generated from typed Haxe metadata.
- Prefer server-rendered Turbo Streams for UI fragments. When the payload is a
  database-backed UI row, Rails should usually render an HHX partial and
  broadcast it through `Turbo::StreamsChannel`.
- Client-rendered streams are valid for small latency-sensitive UI or fully
  client-owned widgets, but the template should be generated or typed rather
  than hand-written string HTML.
- No parallel runtime. Compiler-erased helpers and generated facades are fine;
  a RailsHx-specific Hotwire runtime is not.
- Fail closed on drift. Missing partials, wrong locals, missing stream targets,
  invalid payload fields, unchecked selector strings, and unconnected Cable
  tests should fail at Haxe compile time or in focused runtime gates.
- Keep generated output pleasant to Rails developers. The Ruby should look like
  idiomatic Rails, not a translation artifact that fights the framework.

## Current Surfaces

| Surface | Current state | Gap |
| --- | --- | --- |
| Server Turbo Streams | `TurboStreams.append/prepend/...` and `broadcast*To` lower to Rails helpers with typed `Template<TLocals>`, `StreamName<TLocals>`, and `StreamTarget`. The todoapp now dogfoods this with `turbo_stream_from`, server-rendered broadcasts, and a hand-written shared chat room contract. | Needs model/callback ergonomics and reusable stream contract generation. |
| ActionCable channels | `@:railsChannel`, `Channel<TParams, TPayload>`, `Stream<TPayload>`, and `ActionCable.broadcast(...)` emit normal Rails channels/broadcasts. | Useful for custom payload protocols, but not the canonical DOM update path when Turbo Streams can render a partial. |
| Haxe JS Turbo client | `Turbo.on*`, `Turbo.renderStreamMessage`, `Turbo.stream`, and Genes ES modules work with importmap. | Client-rendered stream HTML should be generated/typed when deliberately chosen; canonical Hotwire examples should not hand-build DOM fragments. |
| Shared hooks | `TodoHooks` centralizes app-wide ids, attrs, classes, selectors, storage keys, and Playwright exports. `ChatRoomHooks` adds a focused browser-safe Hotwire hook layer for the chat room. | Needs a reusable generator/macro pattern, not only hand-written samples. |
| Browser tests | Playwright imports generated hook constants and verifies two-session updates. | Needs typed Haxe-authored browser test layer later, but TS Playwright can remain first-class. |

## Rendering Strategy Comparison

| Strategy | Example | Best for | Tradeoffs |
| --- | --- | --- | --- |
| Server-rendered Turbo broadcast | `TurboStreams.broadcastPrependTo(Chat.roomStream(), Chat.targets.list(), Template.of(ChatMessageRowView), locals)` | Database-backed UI, Rails partial reuse, accessibility/HTML owned by HHX. | Requires server-side stream contract and async broadcast timing tests. |
| Client-rendered Turbo stream | `Turbo.renderStreamMessage(Chat.streams.prependMessage(payload))` | Small client-owned widgets, optimistic UI, low-latency affordances. | Template can become stringly unless generated from HHX or a typed builder. |
| Raw ActionCable data update | `received(payload) { element.textContent = payload.body; }` | Non-DOM state updates, charts/canvas, intentionally low-level UI. | Not canonical for Rails DOM mutation; easy to drift from HHX/CSS/tests. |
| Turbo Stream response to submitter | Controller `respond_to { turbo_stream { render turbo_stream: ... } }` | Form submitter feedback and progressive enhancement. | Does not update other browser sessions by itself. |

The preferred default for Rails UI is:

1. Render current state from HHX on the page/frame.
2. Subscribe with typed HHX `<turbo_stream_from>`.
3. Broadcast server-rendered HHX partials with
   `Turbo::StreamsChannel.broadcast_*_to`.
4. Return `head :no_content` or a form-specific Turbo Stream response to the
   submitter, but avoid duplicating the same target mutation in both response
   and broadcast.
5. Use typed client-rendered streams only when the UI fragment is intentionally
   client-owned, optimistic, or not a normal Rails DOM partial.

## Proposed Contract Shape

Create small Haxe-owned contract classes that describe one Hotwire surface:

```haxe
package hotwire;

import rails.action_view.Template;
import rails.turbo.StreamName;
import rails.turbo.StreamTarget;
import shared.ChatRoomHooks;
import views.ChatMessageRowView;

typedef ChatMessageRowLocals = {
	var id:Int;
	var body:String;
	var userId:Int;
}

typedef ChatMessageBroadcast = ChatMessageRowLocals;

class ChatRoomContract {
	public static inline function turboStream():StreamName<ChatMessageRowLocals> {
		return StreamName.named(ChatRoomHooks.streamName);
	}

	public static inline function listTarget():StreamTarget {
		return StreamTarget.named(ChatRoomHooks.listTargetId);
	}

	public static inline function rowTemplate():Template<ChatMessageRowLocals> {
		return Template.of(ChatMessageRowView);
	}
}
```

This is intentionally boring. Boring is good here: editors can complete it,
macros can inspect it, and generated Ruby remains normal Rails.

### Server-Rendered Broadcast

Controller or model code should be able to write:

```haxe
TurboStreams.broadcastPrependTo(
	ChatRoomContract.turboStream(),
	ChatRoomContract.listTarget(),
	ChatRoomContract.rowTemplate(),
	{
		id: message.id,
		body: message.body,
		userId: message.userId
	}
);
```

Generated Ruby should remain Rails-shaped:

```ruby
Turbo::StreamsChannel.broadcast_prepend_to(
  "todoapp:chat",
  target: "railshx-chat-list",
  partial: "controllers/todos/chat_message_row",
  locals: { id: message.id, body: message.body, user_id: message.user_id }
)
```

This removes the client HTML string and lets HHX own the row markup.

### Client Subscription Helper

For data broadcasts or client-rendered streams, app code should not repeat the
channel constant or payload type. A generated helper can wrap
`Consumer.subscribe(...)`:

```haxe
ChatRoomClient.subscribe(Consumer.create(), {
	connected: () -> ChatRoomHooks.markReady(),
	disconnected: () -> ChatRoomHooks.markDisconnected(),
	received: payload -> ChatRoomStreams.prependClientRendered(payload)
});
```

Generated Haxe can still lower to:

```js
consumer.subscriptions.create(
  { channel: "Channels::PresenceChannel" },
  callbacks
)
```

The Haxe-facing API should infer the channel name from
`@:railsChannel class PresenceChannel` rather than making users repeat
`"Channels::PresenceChannel"` in app code.

### Typed Client-Rendered Stream

If client rendering is chosen, it should be isolated behind a typed stream
builder:

```haxe
ChatRoomStreams.prependClientRendered(payload);
```

Internally, the first implementation may still call:

```haxe
Turbo.renderStreamMessage(
	Turbo.stream(TurboStreamAction.Prepend, TodoHooks.chatListId, html)
);
```

But the app-facing API should be generated from the contract and should own
escaping. Canonical samples should not inline `createElement`, `innerHTML`, or
ad-hoc HTML strings at call sites.

## Macro And Generator Opportunities

### `@:hotwireContract`

A future `@:hotwireContract` macro can validate and generate helper surfaces:

```haxe
@:hotwireContract
class ChatRoom {
	static final cable = PresenceChannel;
	static final stream = "todoapp:chat";
	static final target = TodoHooks.chatListId;
	static final row = Template.of(ChatMessageRowView);
}
```

The macro should generate or validate:

- `Stream<TPayload>` for ActionCable.
- `StreamName<TLocals>` for Turbo broadcasts.
- `StreamTarget` from a shared DOM id.
- `Template<TLocals>` for HHX row partials.
- JS subscription helpers with inferred channel names.
- Playwright hook exports when a target/readiness attr is public.

The macro must reject dynamic paths/names by default. Checked literals are fine
only when they validate safe shape and are attached to a typed contract.

### Model Callback Convenience

After server-rendered broadcast helpers are stable, model/controller ergonomics
can improve:

```haxe
ChatRoom.afterCreatePrepend(ChatMessage, message -> ({
	id: message.id,
	body: message.body,
	userId: message.userId
}));
```

This should lower to Rails-native callback or controller code only when the
callback ordering and transaction semantics are explicit. Avoid hiding Rails
transaction behavior behind magical callbacks too early.

### Test Helper Generation

Contracts should generate test helpers:

- Rails channel tests can assert `assert_has_stream ChatRoom.streamName`.
- Rails request tests can assert `assert_broadcasts ChatRoom.streamName, 1`.
- Playwright can wait for `ChatRoom.readyAttr`.
- Haxe-authored browser tests can later consume the same hooks.

## Diagnostics

Good diagnostics are part of the product:

- `ChatRoom.rowTemplate()` locals do not match the broadcast payload.
- `TodoHooks.chatListId` is missing from the HHX template expected to receive
  stream updates.
- Client subscription references a channel that is not `@:railsChannel` or a
  checked external channel contract.
- A client-rendered stream uses raw HTML without a generated/checked builder.
- A Playwright hook export references a hook that is not in the shared registry.
- A contract tries to combine unrelated stream payload and partial locals
  without an explicit mapping function.

When the compiler cannot prove a DOM target exists because the target is
Rails-owned ERB, use an explicit checked interop form such as
`Target.existing("railshx-chat-list")` that inspects `app/views` and fails
closed when the file is missing.

## Todoapp Migration Path

The current todoapp chat is now the regression sentinel for this design:

- `ChatMessageView` is the HHX row partial.
- `ChatRoomHooks` owns browser-safe stream and readiness selector constants.
- `ChatRoomContract` owns server-side `StreamName<ChatMessageLocals>`,
  `StreamTarget`, `Template<ChatMessageLocals>`, and locals construction.
- `ExportTodoHooks` publishes the connected Turbo stream-source selector to
  Playwright so browser tests do not copy the selector literal.
- The two-session Playwright test remains the user-facing proof that Rails/Turbo
  performs the realtime DOM update.

## Phased Plan

1. **Design and contracts**: landed as this design plus the first todoapp
   `ChatRoomHooks`/`ChatRoomContract` slice.
2. **Server-rendered todoapp row broadcast**: landed with the typed
   `ChatMessageView` HHX partial and `TurboStreams.broadcastPrependTo(...)`.
3. **Typed channel subscription helper**: infer the channel identifier from
   `@:railsChannel` and remove string channel names from app-facing Haxe JS.
4. **Hotwire contract macro**: generate stream/target/template/subscription
   helpers from one declaration.
5. **Target existence validation**: validate owned HHX targets and add checked
   interop for Rails-owned ERB targets.
6. **Testing helpers**: generate Rails/Playwright helper constants from the
   contract and add negative compile tests for drift.
7. **Generator integration**: make `hxruby:scaffold` and the Rails app
   generator emit the contract pattern by default for realtime examples.

## Non-Goals

- Replacing Turbo with a RailsHx runtime.
- Replacing ActionCable with a custom websocket client.
- Hiding Rails transaction/broadcast timing behind magic callbacks before the
  semantics are documented and tested.
- Making server-rendered streams mandatory for every case. Client rendering is
  valid when it is explicit, typed, escaped, and tested.

## Acceptance Bar

This work is production-shaped when:

- A Rails developer can inspect generated Ruby/ERB/JS and recognize ordinary
  Rails Hotwire.
- A Haxe developer can rename a stream target, payload field, partial local, or
  channel class and get compile-time or focused test feedback instead of stale
  runtime behavior.
- The todoapp demonstrates both Turbo Stream submit responses and true
  cross-browser realtime updates.
- Static smoke and snapshots cover generated output, Rails tests cover channel
  and broadcast seams, and Playwright covers visible browser behavior.
