# RailsHx View-Local Helpers R&D

RailsHx HHX views should be allowed to keep small, pure presentation helpers
next to the markup that uses them. This is the same ergonomic pressure React
components solve with local functions, but the RailsHx output must remain normal
Rails ERB and must not turn view classes into query, mutation, or controller
objects.

This document is the design packet for the `haxe_ruby-7yo` R&D bead. It is
written so a beginner can understand the intended authoring model before reading
the compiler implementation.

## Problem

Today, a RailsHx-owned template is usually a static view class:

```haxe
@:railsTemplate("todos/_card")
@:railsTemplateAst("render")
class TodoCardView {
	public static function render(locals:TodoCardLocals):HtmlNode {
		return <article class="todo-card">
			<h2>${locals.todo.title}</h2>
		</article>;
	}
}
```

That is good for type safety, but view files quickly need tiny formatting
choices:

- choose a CSS class from a model state;
- format a short label;
- choose empty-state copy;
- normalize display-only text;
- keep repeated HHX fragments readable.

Without a first-class rule, authors either push those decisions into extra
view-model objects, duplicate expressions inline, or add ad hoc helper classes
that are far away from the markup. That is unnecessary ceremony for pure
presentation logic.

## Goals

- Let view authors define pure helper methods in the same class as the HHX
  template.
- Keep helper calls typed by Haxe and discoverable in editors.
- Emit boring Rails ERB/Ruby, with no custom view-helper runtime.
- Make the boundary obvious: helpers may format, branch, compose local markup,
  and call typed RailsHx view/helper facades; helpers must not query databases,
  mutate records, touch sessions, enqueue jobs, or perform controller work.
- Reduce view-model/helper boilerplate when the logic is genuinely local to one
  view.
- Preserve the current `@:railsTemplateAst("render")` authoring path and make
  this an additive feature.

## Non-Goals

- Do not introduce stateful view component instances in the first slice.
- Do not replace Rails helpers, Rails partials, or typed RailsHx components.
- Do not allow view helpers to become service objects.
- Do not add hidden compiler globals.
- Do not emit helper methods into app-facing Rails classes unless that output is
  necessary and clearly documented.

## Recommended Authoring Shape

The first supported shape should be static/private helper methods in the same
view class:

```haxe
typedef TodoCardLocals = {
	var todo:Todo;
}

@:railsTemplate("todos/_card")
@:railsTemplateAst("render")
class TodoCardView {
	public static function render(locals:TodoCardLocals):HtmlNode {
		return <article class=${cardClass(locals.todo)}>
			<h2>${titleText(locals.todo)}</h2>
			<if ${locals.todo.isCompleted}>
				<p>${statusLabel(locals.todo)}</p>
			</if>
		</article>;
	}

	static function cardClass(todo:Todo):String {
		return todo.isCompleted ? "todo-card is-complete" : "todo-card";
	}

	static function titleText(todo:Todo):String {
		return todo.title.trim();
	}

	static function statusLabel(todo:Todo):String {
		return todo.isCompleted ? "Done" : "Open";
	}
}
```

Beginners only need to learn one rule: if the helper is just about displaying
this template, put it in the view class; if it loads data or changes state, keep
it in the controller/model/service layer.

## Helper Kinds

### String Helpers

String, number, bool, enum, and date-ish helpers are the safest first slice.
They can appear in text or attributes:

```haxe
<span class=${roleClass(locals.user)}>${displayName(locals.user)}</span>
```

Desired ERB shape:

```erb
<span class="<%= role_class(user) %>"><%= display_name(user) %></span>
```

For RailsHx-owned static helpers, the compiler may also inline very small pure
expressions when that keeps output clearer, but direct ERB helper calls are
easier to debug and should be the initial contract.

### Markup Helpers

A helper that returns `HtmlNode` can keep repeated HHX fragments close to the
view:

```haxe
static function badge(text:String):HtmlNode {
	return <span class="badge">${text}</span>;
}
```

Supported lowering:

```haxe
${badge("New")}
```

should emit the helper's markup at the call site when all arguments can be
lowered through HHX. The first supported markup slice is same-class static
helpers returning `HtmlNode`, used as HHX child markup. Text and attribute
positions still require scalar helpers so markup fragments do not accidentally
become escaped strings.

### Shared Helpers

If a helper becomes useful across multiple views, move it to a typed shared
facade:

```haxe
import views.helpers.UserDisplay.displayName;
```

Shared helpers should follow the same purity rule and can later become
generated Rails helpers only when Ruby/Rails interop makes that the clearest
output.

## Compiler Contract

The implementation should add an explicit RailsHx view-helper contract instead
of relying on incidental expression printing.

1. When lowering `@:railsTemplateAst`, collect static methods declared on the
   view class.
2. Treat calls from `render(...)` to same-class static helpers as view-local
   helper calls.
3. Require helper arguments and return types to be known. `Dynamic` should fail
   unless a deliberately named escape hatch exists.
4. Allow only helper return types the template lowerer understands:
   `String`, `Bool`, `Int`, `Float`, Rails-safe scalar abstracts, and
   `HtmlNode` when the helper is used as child markup.
5. Reject or warn on helpers that touch obvious non-view surfaces such as
   `ActiveRecord` query methods, controller stores, session, cookies, jobs, file
   IO, raw Ruby, or `untyped`.
6. Emit Rails-native ERB:
   - scalar helpers lower to a Ruby method call or inlined expression;
   - markup helpers lower to HHX output at the call site or a small generated
     private ERB helper only if inlining would duplicate complex markup.
7. If generated support is needed, isolate it under the same generated support
   policy as other RailsHx output and add a generated comment explaining why it
   exists.

## Naming

Haxe authors should use Haxe names:

```haxe
static function displayName(user:User):String
```

Generated Ruby should use normal Ruby names:

```ruby
def display_name(user)
```

If the helper is inlined, no Ruby method is emitted. If the helper is emitted,
it should live as close as Rails convention allows, for example as a private
helper method associated with the generated template support, not as a random
`__hx_*` method on a model or controller.

## Diagnostics

Good beginner diagnostics matter more than clever lowering. Examples:

- `TodoCardView.cardClass returns Dynamic; view-local helpers must return a known display type such as String or HtmlNode.`
- `TodoCardView.loadTodos calls Todo.where(...). View-local helpers must not query the database; load data in the controller and pass it through typed locals.`
- `TodoCardView.saveLabel mutates locals.todo. View-local helpers must be pure presentation logic.`
- `badge(...) returns HtmlNode; use it as HHX child markup, not inside a text or attribute expression.`

## Tests

The implementation should include:

- a positive HHX template smoke for same-class scalar helpers in text and attrs;
- a positive snapshot proving generated ERB/Ruby has readable helper names and
  no `__hx*` scaffolding;
- a compile-fail test for `Dynamic` helper returns;
- a compile-fail test for database/query calls inside a helper;
- a compile-fail test for mutations inside a helper;
- a positive test for `HtmlNode` helper composition;
- a compile-fail test for using a `HtmlNode` helper in a scalar attribute/text
  position;
- todoapp coverage once the API is ready, because the todoapp is the canonical
  dogfood app for RailsHx ergonomics.

## Relationship To View Models

View-local helpers do not replace view models completely. Use this rule:

- If the value is derived from already-loaded locals and only affects this
  template, use a view-local helper.
- If the value is shared across views, move it to a shared typed helper.
- If the value represents a larger presentation contract, use a typed locals
  typedef or view model.
- If the value requires loading data, permissions, persistence, or side effects,
  compute it before rendering and pass it as typed locals.

## Implementation Slices

1. Document and test the current behavior around simple helper calls, so we know
   which cases already work by accident.
2. Add explicit same-class scalar helper recognition in template expression
   printing.
3. Add purity diagnostics for the most dangerous surfaces: queries, mutation,
   `untyped`, raw Ruby, controller/session/cookie/job/file IO calls.
4. Add todoapp examples where helpers remove noisy repeated presentation logic.
5. Add same-class static `HtmlNode` returning helpers after scalar helpers are
   stable.
6. Revisit an instance-style surface only after static helpers are proven:

   ```haxe
   class TodoCardView extends RailsView<TodoCardLocals> {
     function cardClass(todo:Todo):String;
     public function render():HtmlNode;
   }
   ```

   This may be nicer someday, but it is more magic and should not be the first
   contract.

## Review Packet For A Future GPT-5.5 Pro Pass

Ask the reviewer to challenge these points:

- Is the static helper surface enough, or should the first public API reserve
  syntax for an eventual instance-style view class?
- Should scalar helpers emit Ruby helper methods or inline their bodies by
  default?
- What purity checks are practical in Haxe typed AST without rejecting useful
  presentation code?
- Is `HtmlNode` helper inlining the right second slice, or should repeated
  markup always become typed partials/components?
- Which examples in `examples/todoapp_rails/src/views` would most clearly
  demonstrate the feature without making the sample clever?

## Recommendation

Keep static same-class scalar helpers as the base contract and support
same-class `HtmlNode` helpers for local markup fragments once the scalar path is
stable. Treat instance-style views and shared/generated Rails helper methods as
follow-up R&D after the static helper contract is exercised in the todoapp and
focused component fixtures.
