# RailsHx Typed Views And HHX

RailsHx gives server-rendered Rails views a TSX-like typed authoring surface.
Authors write valid Haxe methods containing HHX markup. Haxe parses and types
the view, RailsHx lowers its typed markup AST, and the compiler emits ordinary
ActionView ERB.

This is a compile-time authoring layer, not a browser view framework. There is
no virtual DOM, hydration pass, or RailsHx rendering server. Rails still owns
ActionView, helpers, escaping, partials, layouts, caching, request state, and the
final rendered response.

## The Basic Shape

A view is a Haxe class with a typed locals contract and an HHX render method:

```haxe
import rails.action_view.HtmlNode;

typedef CardLocals = {
	var eyebrow:String;
	var title:String;
}

@:railsTemplate("shared/_card")
@:railsTemplateAst("render")
class CardView {
	public static function render(locals:CardLocals):HtmlNode {
		return <section class="card">
			<span class="eyebrow">${locals.eyebrow}</span>
			<h2>${locals.title}</h2>
		</section>;
	}
}
```

The source looks and composes like typed JSX/TSX, but its destination is a
server-rendered `_card.html.erb` partial. A caller that omits `title`, passes a
non-`String` value, references an unknown local, or breaks the HHX structure
fails during Haxe compilation.

## What The Compiler Can Check

| Surface | Compile-time value |
| --- | --- |
| Haxe and HHX syntax | Parser-valid Haxe, a balanced HHX tree, and valid embedded expression syntax. |
| Embedded values | `${...}` expressions, conditions, loops, and view-local helper calls use normal Haxe type checking. |
| Locals and assigns | Typedefs and model types provide required fields, nullability, completion, and refactorable member access. |
| Rails helpers | Supported HHX tags such as forms, links, partials, content slots, Turbo helpers, and formatting helpers validate their known argument shapes. |
| Templates and layouts | `Template.of(ViewClass)` and `Template.layout(ViewClass)` prove that a Haxe-owned view class exists and owns a template path. |
| Partials and components | Typed locals objects and `Component<TLocals>` contracts catch missing or wrongly typed composition inputs and invalid slot names. |
| Routes and model/form fields | Generated route helpers and model field refs replace many repeated strings and catch supported rename or schema drift. |
| Existing ERB | `Template.existing(...)` and `Component.existing(...)` check discoverable Rails-owned files while keeping their Haxe locals boundary typed. |

The compiler then emits recognizable Rails constructs such as `render partial:`,
`form_with`, `link_to`, `content_for`, `capture`, and normal ERB control flow.
Ruby-owned code and helpers can consume the output as ordinary Rails artifacts.

## Why This Is More Than Template Syntax

Standard Rails ERB can be parsed, linted, rendered in tests, and improved with
third-party typing tools. Its default authoring model does not put markup,
locals, embedded expressions, partial contracts, routes, and model fields into
one statically typed language compilation.

HHX provides several related advantages:

- **Earlier feedback.** Supported markup, syntax, type, helper, locals, route,
  field, and composition mistakes fail before a request renders the template.
- **Editor tooling.** Locals, model values, helpers, components, route refs, and
  shared hooks participate in completion, go-to-definition, and typed renames.
- **Typed component composition.** Partial locals and captured ActionView slots
  have explicit contracts instead of relying only on runtime hash keys.
- **Safer refactoring.** Moving or renaming a typed view, field, helper, or
  locals member can produce compiler diagnostics at affected call sites.
- **One typed vocabulary across boundaries.** Server HHX and Haxe-authored
  browser code can share enums, payload types, Turbo targets, DOM hooks, and
  route tokens when that boundary genuinely belongs on both sides.
- **Rails-native runtime behavior.** The result remains ERB and ActionView, so
  Rails helpers, caching, Turbo, existing Ruby partials, logs, and deployment
  tooling keep their normal roles.
- **No client rendering tax.** Typed view authoring does not require React, a
  client component runtime, hydration, or duplicated client-side templates.
- **Reviewable output.** Generated ERB snapshots make lowering changes visible
  and allow Ruby/Rails developers to inspect the deployed artifact.
- **Gradual adoption.** New HHX views can render beside Rails-owned ERB, and
  typed wrappers can consume existing partials without rewriting them first.

## HHX Is TSX-Like, Not React

The useful analogy is lexical and ergonomic: markup is embedded in a typed
language, expressions use `${...}`, and components/locals have typed contracts.
The runtime model is deliberately different.

| TSX in a client framework | RailsHx HHX |
| --- | --- |
| Commonly creates client component or virtual-DOM values | Creates a typed compile-time ActionView AST |
| Usually renders or hydrates in JavaScript | Emits ERB rendered by Rails on the server |
| Uses framework component/runtime semantics | Uses Rails helpers, partials, layouts, capture, and Turbo |
| Ships the view framework to the browser | Adds no HHX view runtime to the browser |

RailsHx components are typed partial composition over ActionView. See
[RailsHx Components](railshx-components-guide.md) for typed locals and captured
slot content.

## Honest Limits

HHX only claims what the compiler and typed facades can prove:

- parser-valid HHX does not by itself prove semantic HTML validity,
  accessibility, correct CSS, responsive layout, or browser behavior;
- plain CSS class strings and deliberately open `data-*` attributes are not all
  schema-checked unless a typed shared token owns them;
- external Ruby helpers, database values, authorization state, and dynamic gem
  behavior may still fail at runtime;
- supported helper tags have typed coverage, but an unmodeled Rails helper may
  require a typed extern/facade or an explicit escape hatch;
- generated ERB still needs Rails request/view tests, and user-visible behavior
  still needs browser tests where the compiler cannot prove it.

The todoapp therefore combines compiler diagnostics and snapshots with Rails
runtime tests, real Chromium tests, and a production build. Typed views reduce
the runtime error surface; they do not replace runtime QA.

## Ownership And Adoption

- For RailsHx-owned views, use HHX plus `@:railsTemplateAst(...)` and prefer
  `Template.of(...)` or `Template.layout(...)` references.
- For existing Rails-owned ERB, prefer `Template.existing(...)` or
  `Component.existing(...)` with a precise locals type.
- Use unchecked external template refs only when filesystem validation is not
  possible and document that boundary.
- Treat generated `.html.erb` as a build artifact. Change its Haxe/HHX source
  rather than hand-editing the output.

Continue with the [RailsHx Skeleton And Todoapp Tutorial](railshx-skeleton-and-todoapp-tutorial.md)
for a full page, typed partials, forms, routes, Turbo, and production workflow.

## Evidence

```bash
npm run test:components
npm run test:todoapp-rails
rake test:rails:runtime
rake todoapp:playwright
rake todoapp:production
```

Compiler snapshots own exact ERB shape and negative fixtures own knowable type
errors. Rails, browser, and production gates own runtime behavior that HHX
compilation cannot establish.
