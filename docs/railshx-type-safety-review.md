# RailsHx Type Safety Review

RailsHx should use strings only where they are the best Rails/Ruby output representation, and those strings should be compile-time checked whenever practical.

## Todoapp Findings

The todoapp already has strong typed seams:

- Route calls use generated externs such as `Routes.todosPath()`.
- Template locals use `Template<TLocals>` and object-literal locals, so missing/wrong locals fail in Haxe.
- HHX embedded expressions, conditionals, loops, and route helper calls are typed before ERB is emitted.
- RailsHx-owned templates can be referenced through `Template.of(ViewClass)`/`Template.layout(LayoutViewClass)`, so missing or renamed Haxe view classes fail at compile time.
- Rails-owned ERB interop is separated through checked `Template.existing(...)` where the ERB file is discoverable, with lower-level `Template.external(...)` reserved for explicit escapes.
- ActiveRecord columns generate typed field refs such as `Todo.fields.title` and `Todo.f.title : Field<Todo, String>`, plus a typed params/form scope `Todo.railsParamKey : ModelKey<Todo>`. HHX form helpers and `ParamsMacro.requirePermit(...)` can share those refs, so unknown fields and wrong-model strong params fail during Haxe compilation while generated ERB/Ruby still uses normal Rails names and symbols.

The remaining stringly seams are the next targets:

- Template identity: `Template.of(...)`, `Template.layout(...)`, and `Template.existing(...)` cover the default owned/external cases. Remaining `@:railsTemplate("...")`, `Template.named("...")`, and layout strings are literal-only and path-shape checked, but should continue moving behind typed references or generated constants where possible.
- Form and params fields: the todoapp now uses typed field refs for the default path. Remaining raw string support exists for compatibility and low-level Rails interop, but canonical RailsHx examples should keep model-owned form fields and strong params behind generated refs.
- Slots and DOM hooks: the todoapp now uses `shared.TodoHooks` for `"head"`, `"#open-work"`, `"data-railshx-scroll"`, `"data-railshx-flash"`, storage keys, and selectors shared across HHX, Haxe JS, and Playwright. Future samples should follow that pattern instead of copying hook strings.
- CSS classes: local one-off styling strings are fine, but behavior-bearing classes such as `"todo-form"` should be centralized as typed hooks when JS or tests depend on them.

## Direction

- Prefer generated constants, abstracts, typedefs, and macros over free strings in Haxe-facing APIs.
- Keep Rails-native output: typed Haxe constructs should lower to normal Rails strings, symbols, route helpers, partial names, params keys, and attributes.
- Validate literal strings at macro/compiler time when a typed replacement is not yet available.
- Add negative tests whenever a stringly surface becomes typed, for example missing partial path, unknown model field, wrong locals key, or invalid slot name.
