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

The separate maintained [`shared_domain`](../examples/shared_domain) example
owns the deeper pure-domain proof. It executes one typed normalization,
validation, error, and serialization module against seven identical vectors on
generated Ruby and JavaScript. Keeping that proof separate prevents Rails,
Turbo, DOM, or stdout APIs from leaking into the shared module.

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
| ActionCable channels | `@:railsChannel`, `Channel<TParams, TPayload>`, `Stream<TPayload>`, and `ActionCable.broadcast(...)` emit normal Rails channels/broadcasts. JavaScript builds derive `MyChannel.client:ChannelRef<TParams, TPayload>` for native subscriptions without repeated channel strings. | Useful for custom payload protocols, but not the canonical DOM update path when Turbo Streams can render a partial. The broader contract macro still needs to connect subscriptions to streams, targets, and templates. |
| Haxe JS Turbo client | `Turbo.on*`, `Turbo.renderStreamMessage`, `Turbo.stream`, and Genes ES modules work with importmap. | Client-rendered stream HTML should be generated/typed when deliberately chosen; canonical Hotwire examples should not hand-build DOM fragments. |
| Shared hooks | `TodoHooks` centralizes app-wide ids, attrs, classes, selectors, and storage keys. `@:hotwireHooks` generates the focused browser-safe stream/target/readiness accessors that `ChatRoomHooks`, Playwright exports, and Haxe-authored browser tests consume. | Generator integration should emit this pattern for new realtime scaffolds. |
| Shared pure domain behavior | `shared_domain` compiles one typed todo-draft contract and common vectors to Ruby and JavaScript, then requires byte-identical validation, ordered errors, and serialization output. | One bounded contract is proven; new domain claims need their own vectors and target-edge documentation. |
| Browser tests | Playwright imports generated hook constants and verifies two-session updates. | Needs typed Haxe-authored browser test layer later, but TS Playwright can remain first-class. |

## Maintained Two-Target Domain Proof

`npm run test:full-stack-shared-behavior` compiles the exact same contract and
vector module through Reflaxe.Ruby's `portable` profile and Haxe's JavaScript
target. It executes both generated artifacts under Ruby and Node and compares
their JSONL bytes with a committed expectation. The vectors cover whitespace
normalization, Unicode preservation, JSON escaping, required and length errors,
priority bounds, and deterministic multi-error ordering.

Only the pure middle is shared. Tiny target entrypoints own stdout; Rails owns
params, persistence, transactions, and presentation; JavaScript owns DOM,
storage, and network effects. The title limit explicitly follows Haxe UTF-16
units, and the writer is one-way over a closed typed result. These edges are part
of the contract rather than portability assumptions.

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

## Contract Shape

Create small Haxe-owned contract classes that describe one Hotwire surface:

```haxe
package hotwire;

import rails.action_view.Template;
import shared.ChatRoomHooks;
import views.ChatMessageRowView;

typedef ChatMessageRowLocals = {
	var id:Int;
	var body:String;
	var userId:Int;
}

typedef ChatMessageBroadcast = ChatMessageRowLocals;

@:hotwireContract
class ChatRoomContract {
	static final stream = ChatRoomHooks.streamName();
	static final target = ChatRoomHooks.targetId();
	static final row:Template<ChatMessageRowLocals> = Template.of(ChatMessageRowView);

	public static inline function locals(message:ChatMessage):ChatMessageRowLocals {
		return {
			id: message.id,
			body: message.body,
			userId: message.userId
		};
	}
}
```

The macro consumes the three private declaration fields and generates
`streamName():StreamName<ChatMessageRowLocals>`,
`streamTarget():StreamTarget`, and
`rowTemplate():Template<ChatMessageRowLocals>`. The explicit row annotation is
the single owner of the locals type; the model-to-locals mapping stays visible
because guessing business-data transformations would be unsafe. Ruby builds
enable the macro through RubyHx compiler initialization, while
`-lib railshx.client` enables the same expansion without loading the Ruby
compiler.

### Server-Rendered Broadcast

Controller or model code should be able to write:

```haxe
TurboStreams.broadcastPrependTo(
	ChatRoomContract.streamName(),
	ChatRoomContract.streamTarget(),
	ChatRoomContract.rowTemplate(),
	ChatRoomContract.locals(message)
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

For data broadcasts or client-rendered streams, app code does not repeat the
channel constant or payload type. Every `@:railsChannel` class now receives a
browser-only typed `client` reference:

```haxe
ChatMessagesChannel.client.subscribe(Consumer.create(), {roomId: roomId}, {
	connected: () -> ChatRoomHooks.markReady(),
	disconnected: () -> ChatRoomHooks.markDisconnected(),
	received: payload -> ChatRoomStreams.prependClientRendered(payload)
});
```

The `Channel<TParams, TPayload>` base fixes both client types, and the build
macro derives the exact Rails constant from the channel class. Generated Haxe
still lowers to:

```js
consumer.subscriptions.create(
  Object.assign({ channel: "ChatMessagesChannel" }, { roomId: roomId }),
  callbacks
)
```

The reference is an inline abstract with no JavaScript wrapper, the server class
is not emitted into the browser bundle, and the generated field is absent from
Ruby output. `Consumer.subscribeExternal(...)` remains the explicit escape for
Rails-owned channels that have no Haxe channel contract. The next contract-macro
phase can build higher-level helpers on this landed primitive.

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

The shipped first slice validates and generates the server-rendered contract:

```haxe
@:hotwireContract
class ChatRoomContract {
	static final stream = "todoapp:chat";
	static final target = TodoHooks.chatListId;
	static final row:Template<ChatMessageLocals> = Template.of(ChatMessageRowView);
}
```

It currently generates and validates:

- `StreamName<TLocals>` for Turbo broadcasts.
- `StreamTarget` from a shared DOM id.
- `Template<TLocals>` for HHX row partials.

Haxe `Dynamic` sources or locals, missing declarations,
non-`Template<TLocals>` rows, and generated-name collisions fail closed.
Subscription composition and generator integration remain later phases.
DOM-target ownership is a separate proof at the view boundary:
RailsHx-owned HHX views declare `@:railsDomTargets(...)`, while Rails-owned ERB
uses `StreamTarget.existing(template, target)`.

### `@:hotwireHooks`

Browser builds should not import a server contract merely to reach selectors.
The shipped hook declaration keeps only browser-safe facts:

```haxe
@:hotwireHooks
class ChatRoomHooks {
	static final stream:ChatRoomStream = "todoapp:chat";
	static final target:DomId = TodoHooks.chatListId;
	static final ready:Selector = "turbo-cable-stream-source[connected]";
}
```

It generates typed `streamName()`, `targetId()`, `targetSelector()`, and
`readySelector()` accessors. The target selector is derived from the target id;
the macro therefore requires a compile-time id in its selector-safe
letters/digits/underscore/hyphen subset rather than pretending arbitrary CSS
escaping is safe. Readiness is explicit because a stream name and DOM receiver
do not identify the element that proves a browser subscription is connected. The todoapp
exports these accessors to TypeScript Playwright and imports them directly from
its Haxe-authored browser spec.

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

The shipped testing slice keeps server and browser ownership explicit:

- Rails Minitest request tests call
  `ActionCableAssert.assertBroadcasts(ChatRoomContract.streamName(), 1, body)`.
  The compiler includes native `ActionCable::TestHelper` and emits ordinary
  `assert_broadcasts`; RSpec fails closed because no equivalent matcher
  contract has been verified.
- `@:hotwireHooks` generates `streamName()`, `targetId()`,
  `targetSelector()`, and `readySelector()` from browser-safe declarations.
- TypeScript exports and Haxe-authored Playwright specs consume the same
  generated selectors.
- `assert_has_stream` remains a later channel-test slice. It requires a typed
  `ActionCable::Channel::TestCase` owner and must not be advertised on the
  current request/model test base classes.

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

RailsHx-owned HHX views declare their stable receivers beside the markup:

```haxe
@:railsTemplate("todos/_chat_panel")
@:railsTemplateAst("render")
@:railsDomTargets(TodoHooks.chatListId)
class ChatPanelView {}
```

The inline-markup owner verifies that the same compile-time token appears as a
static `id` in the structural HHX tree. This avoids project-wide text scanning
and avoids a contract/view typing cycle. When the target lives in Rails-owned
ERB, use the explicit checked interop form
`StreamTarget.existing("todos/chat_panel", TodoHooks.chatListId)`. It
resolves that one template under `app/views`, requires an exact static id, and
fails closed for an unsafe path, missing file, dynamic token, or missing id.

## Todoapp Migration Path

The current todoapp chat is now the regression sentinel for this design:

- `ChatMessageView` is the HHX row partial.
- `ChatRoomHooks` owns browser-safe stream and readiness selector constants.
- `ChatRoomContract` owns server-side `StreamName<ChatMessageLocals>`,
  `StreamTarget`, `Template<ChatMessageLocals>`, and locals construction.
- `ChatPanelView` declares `@:railsDomTargets(TodoHooks.chatListId)`, proving
  that the shared contract token has a static receiver in the owned HHX tree.
- `ExportTodoHooks` publishes the connected Turbo stream-source selector to
  Playwright so browser tests do not copy the selector literal.
- The two-session Playwright test remains the user-facing proof that Rails/Turbo
  performs the realtime DOM update.

## Phased Plan

1. **Design and contracts**: landed as this design plus the first todoapp
   `ChatRoomHooks`/`ChatRoomContract` slice.
2. **Server-rendered todoapp row broadcast**: landed with the typed
   `ChatMessageView` HHX partial and `TurboStreams.broadcastPrependTo(...)`.
3. **Typed channel subscription helper**: landed as the browser-only
   `MyChannel.client:ChannelRef<TParams, TPayload>` generated from
   `@:railsChannel`; app-facing Haxe JS no longer repeats the channel string or
   client types.
4. **Hotwire contract macro, first slice**: landed for generated typed
   stream/target/template accessors from one declaration, with Ruby and
   JavaScript compile evidence plus negative diagnostics. Connecting an
   optional `@:railsChannel` subscription remains a bounded follow-up rather
   than being inferred by this server-rendered Turbo contract.
5. **Target existence validation**: landed as `@:railsDomTargets(...)` for
   owned structural HHX plus `StreamTarget.existing(template, target)` for
   Rails-owned ERB, with focused missing/dynamic/owner diagnostics.
6. **Testing helpers**: landed as browser-safe `@:hotwireHooks` accessors,
   native Minitest `assert_broadcasts` lowering, Haxe/TypeScript Playwright
   reuse, and negative drift/adapter diagnostics.
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
