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

The todoapp chatroom now proves the baseline:

- `channels/ChatMessagesChannel.hx` owns a typed `ChatBroadcast` payload and
  a typed `Stream<ChatBroadcast>`.
- `controllers/ChatMessagesController.hx` creates an ActiveRecord row, then
  broadcasts the typed payload.
- `client/TodoClient.hx` subscribes through `rails.action_cable.Consumer` and
  renders received payloads through `Turbo.renderStreamMessage(...)`.
- `shared/TodoHooks.hx` centralizes DOM ids, data attrs, selectors, and
  Playwright hooks.
- Playwright opens two browser sessions and verifies realtime delivery.

That is good, but still too manual. The client currently builds a small HTML
template string because the server broadcast only carries data. The long-term
Rails-native destination should make the easiest path either server-rendered
Turbo Streams from typed HHX partial locals, or generated client stream helpers
when client rendering is deliberately chosen.

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
| Server Turbo Streams | `TurboStreams.append/prepend/...` and `broadcast*To` lower to Rails helpers with typed `Template<TLocals>` and `StreamTarget`. | Needs model/callback ergonomics, stream contracts, and todoapp dogfood using server-rendered broadcasts. |
| ActionCable channels | `@:railsChannel`, `Channel<TParams, TPayload>`, `Stream<TPayload>`, and `ActionCable.broadcast(...)` emit normal Rails channels/broadcasts. | Client channel names are still strings; server data payloads are not tied to Turbo partial locals. |
| Haxe JS Turbo client | `Turbo.on*`, `Turbo.renderStreamMessage`, `Turbo.stream`, and Genes ES modules work with importmap. | Client stream HTML remains stringly; common subscription/lifecycle binding is verbose. |
| Shared hooks | `TodoHooks` centralizes ids, attrs, classes, selectors, storage keys, and Playwright exports. | Needs a reusable generator/macro pattern, not only a hand-written sample. |
| Browser tests | Playwright imports generated hook constants and verifies two-session updates. | Needs typed Haxe-authored browser test layer later, but TS Playwright can remain first-class. |

## Rendering Strategy Comparison

| Strategy | Example | Best for | Tradeoffs |
| --- | --- | --- | --- |
| Server-rendered Turbo broadcast | `TurboStreams.broadcastPrependTo(Chat.roomStream(), Chat.targets.list(), Template.of(ChatMessageRowView), locals)` | Database-backed UI, Rails partial reuse, accessibility/HTML owned by HHX. | Requires server-side stream contract and async broadcast timing tests. |
| Client-rendered Turbo stream | `Turbo.renderStreamMessage(Chat.streams.prependMessage(payload))` | Small client-owned widgets, optimistic UI, low-latency affordances. | Template can become stringly unless generated from HHX or a typed builder. |
| Raw ActionCable data update | `received(payload) { element.textContent = payload.body; }` | Non-DOM state updates, charts/canvas, intentionally low-level UI. | Not canonical for Rails DOM mutation; easy to drift from HHX/CSS/tests. |
| Turbo Stream response to submitter | Controller `respond_to { turbo_stream { render turbo_stream: ... } }` | Form submitter feedback and progressive enhancement. | Does not update other browser sessions by itself. |

The preferred default for Rails UI is:

1. Use the normal Turbo Stream response for the submitting browser.
2. Use server-rendered `Turbo::StreamsChannel.broadcast_*_to` for other
   subscribers.
3. Use typed client-rendered streams only when the UI fragment is intentionally
   client-owned or optimistic.

## Proposed Contract Shape

Create small Haxe-owned contract classes that describe one Hotwire surface:

```haxe
package hotwire;

import rails.action_view.Template;
import rails.action_cable.Stream;
import rails.turbo.StreamName;
import rails.turbo.StreamTarget;
import shared.TodoHooks;
import views.ChatMessageRowView;

typedef ChatMessageRowLocals = {
	var id:Int;
	var body:String;
	var userId:Int;
}

typedef ChatMessageBroadcast = ChatMessageRowLocals;

class ChatRoomContract {
	public static inline function cableStream():Stream<ChatMessageBroadcast> {
		return Stream.named("todoapp:chat");
	}

	public static inline function turboStream():StreamName<ChatMessageRowLocals> {
		return StreamName.named("todoapp:chat");
	}

	public static inline function listTarget():StreamTarget {
		return StreamTarget.named(TodoHooks.chatListId);
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
  { channel: "Channels::ChatMessagesChannel" },
  callbacks
)
```

The Haxe-facing API should infer the channel name from
`@:railsChannel class ChatMessagesChannel` rather than making users repeat
`"Channels::ChatMessagesChannel"` in app code.

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
	static final cable = ChatMessagesChannel;
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

The current todoapp chat is a good baseline and should stay as a regression
sentinel. The next dogfood step should add a row HHX partial:

```haxe
@:railsTemplate("controllers/todos/_chat_message")
@:railsTemplateAst("render")
class ChatMessageRowView {
	public static function render(locals:ChatMessageRowLocals):HtmlNode {
		return <li class=${TodoHooks.chatMessageClass} data-railshx-chat-message-key=${locals.id}>
			<span class="avatar">#</span>
			<div>
				<strong>User ${locals.userId}</strong>
				<p>${locals.body}</p>
			</div>
		</li>;
	}
}
```

Then replace the data-only broadcast with a server-rendered Turbo Stream
broadcast. The two-session Playwright test should remain the user-facing proof.

## Phased Plan

1. **Design and contracts**: land this design, then split implementation beads.
2. **Server-rendered todoapp row broadcast**: add a typed row HHX partial and
   dogfood `TurboStreams.broadcastPrependTo(...)`.
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
