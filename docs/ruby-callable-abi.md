# Ruby Callable And Method ABI

This document defines how typed Haxe function signatures map to Ruby method
signatures and calls. It owns the cross-cutting contract for native blocks,
keyword arguments, rest arguments, method values, constructors, forwarding,
and Haxe-owned methods that Ruby code can call directly.

The goal is one predictable Haxe authoring model that emits ordinary Ruby. Ruby
syntax such as `yield`, `&block`, `**options`, and `*args` is compiler output;
application code should not have to select a lowering strategy or introduce an
untyped `Proc` boundary.

## Authoring Contract

An ordinary typed final function parameter represents the block at the Haxe
boundary. `@:rubyBlockArg` belongs on the method, not on the callback value:

```haxe
@:rubyBlockArg
function visit<T>(value:Int, block:Int->T):T;
```

The callback type owns its parameter and result types. Inline functions,
stored functions, closures, and method values all use that same Haxe type.
`Dynamic`, `Any`, raw Ruby, and arbitrary `to_proc` objects are not canonical
block arguments.

Keyword arguments use one typed anonymous object or typedef carrier:

```haxe
typedef SubscribeOptions = {
	var once:Bool;
	@:native("queue_name")
	@:optional var queue:String;
}

@:rubyKwargs
@:rubyBlockArg
function subscribe<T>(name:String, options:SubscribeOptions, block:String->T):T;
```

The parameter order is always:

1. Ordinary positional parameters.
2. The `@:rubyKwargs` carrier, when present.
3. The `@:rubyBlockArg` function, when present.

Both metadata markers take no arguments. The typed parameters are the schema;
there is no second string/index declaration that can drift from the Haxe
signature.

The keyword carrier parameter itself is required. Put optionality on individual
fields with `@:optional`; making the whole carrier optional would collapse “no
keyword object” and “an object with omitted fields” into an ambiguous ABI. A
field-level `@:native("ruby_name")` can override normal camelCase-to-snake_case
mapping. Keyword native names must be plain Ruby identifiers: `?`, `!`, `=`,
and operators are method spellings, not keyword labels.

Compiler-generated overload families may contain both a keyword-carrier form
and a positional form, such as typed ActiveRecord criteria versus an expression
predicate. Haxe retains field metadata while selecting an overload, so the
compiler activates keyword peeling only when that generated invocation's
actual parameter has the declared anonymous-object/typedef shape. This narrow
exception is keyed by the internal generated-stub contract; user-authored
metadata remains strict and cannot silently fall back to positional behavior.

## Generated Call Shapes

An inline keyword carrier emits direct, schema-mapped labels:

```haxe
NativeApi.subscribe("events", {once: true}, value -> value.length);
```

```ruby
NativeApi.subscribe("events", once: true) { |value| value.length }
```

A stored carrier is a Haxe anonymous object, represented as a string-key Ruby
hash. The compiler projects only declared fields instead of forwarding the hash
blindly. This makes structural narrowing truthful: a wider Haxe value may be
assigned to the carrier type, but its extra runtime fields cannot become
undeclared Ruby keywords. Optional fields use `key?` plus a conditional keyword
splat, so an absent field emits no keyword while an explicitly stored null emits
`name: nil`:

```ruby
NativeApi.subscribe(
  "events",
  once: options["once"],
  **(options.key?("queue") ? {queue_name: options["queue"]} : {})
) { |value| value.length }
```

If the carrier is a function call or another effectful expression, the compiler
uses a small structured `begin` projection with meaningful
`keyword_options`/`projected_keywords` locals. It evaluates the expression once,
filters it through the schema, and emits a generated comment explaining why the
temporary code exists. This scaffolding is required by Haxe evaluation order;
plain literals and stored locals do not pay for it.

Projection applies only when the selected callable overload actually declares
the anonymous keyword carrier. A nominal target-owned value can select a
separate positional overload. RailsHx uses this for
`PermittedParams<TModel>`: `Todo.create({title: "typed"})` emits typed keywords,
while `Todo.create(permittedParams)` preserves the single Rails
`ActionController::Parameters` argument and its permitted/indifferent-access
semantics. The generic callable ABI keys off the selected types, not Rails or
facade names.

Tail-safe inline callbacks become native Ruby blocks:

```haxe
NativeApi.visit(1, value -> value + 1);
```

```ruby
NativeApi.visit(1) { |value| value + 1 }
```

A stored Haxe function is already a strict Ruby lambda and is forwarded with
`&`:

```haxe
var callback = (value:Int) -> value + 1;
NativeApi.visit(1, callback);
```

```ruby
callback = ->(value) { value + 1 }
NativeApi.visit(1, &callback)
```

The compiler evaluates receivers, keyword carriers, and callback expressions
once and in Haxe order. An omitted or literal-null optional callback emits no
Ruby block. A nullable callback value is forwarded with `&callback`; Ruby treats
`&nil` as no block, so the expression stays single-evaluation and needs no
wrapper or untyped presence probe.

Inline callback bodies with only an optional final Haxe `return` can use a
normal Ruby block because the final value is the block result. Any non-tail
Haxe `return` requires a strict lambda passed with `&`; emitting it as Ruby
`return` inside an ordinary block would incorrectly return from the enclosing
Ruby method. This choice is semantic and automatic.

## Haxe-Owned Method Definitions

`@:rubyBlockArg` is a method ABI, not an extern-only call hint. Definition-side
lowering follows this compiler policy:

- A required callback used only through direct invocation is removed from the
  Ruby parameter list and its calls become `yield(...)`.
- An optional callback is captured as `&block` so the body can observe its
  absence.
- Assignment, return, storage, positional passing, forwarding, or capture by a
  nested function counts as escape and therefore emits `&block` plus
  `block.call(...)`.
- Forwarding to another block method uses `&block`.
- A required captured block gets an entry diagnostic (`ArgumentError`) when a
  Ruby caller omits it, before nil can be stored, returned, or forwarded.

If a Ruby caller reaches a direct `yield` without a block, Ruby raises its
normal `LocalJumpError`. Captured required blocks use the explicit
`ArgumentError` guard because otherwise `&block` would silently bind `nil` and
could escape before the missing-block mistake became visible.

Authors do not choose between `yield` and `&block`. Both are generated forms of
the same typed Haxe parameter. The compiler may refine its analysis without
changing source APIs, provided observable behavior remains the same.

For example, direct use stays as small as handwritten Ruby:

```haxe
@:rubyBlockArg
static function visit<T>(value:Int, block:Int->T):T {
	return block(value);
}
```

```ruby
def self.visit(value)
  return yield(value)
end
```

Optional or first-class use captures the block:

```haxe
@:rubyBlockArg
static function keep(block:Int->String):Int->String {
	return block;
}
```

```ruby
def self.keep(&block)
  if (block == nil)
    raise(ArgumentError, "required block missing for self.keep")
  end
  return block
end
```

The same definition policy applies to static and instance methods,
constructors, `@:rubyModule` methods, and `@:rubyConcern` methods. A typed
`@:rubyPatch` contract keeps an existing receiver method call direct and passes
its callback as a normal Ruby block. Ruby-origin callers use `{ ... }` or
`do ... end`; no Haxe runtime wrapper is part of the method ABI.

Exceptions thrown by a callback still propagate through the Ruby call and
through the existing Haxe exception boundary. The yield/capture choice changes
representation only; it does not swallow exceptions or invent cleanup.

Keyword definitions similarly remove the carrier from positional parameters.
Required carrier fields become required Ruby keywords. Optional fields preserve
absence, unknown keys are rejected, and the carrier is materialized only when
the Haxe body uses it as a whole instead of reading known fields.

For example:

```haxe
typedef ConfigureOptions = {
	var name:String;
	@:optional var note:Null<String>;
}

@:rubyKwargs
static function configure(options:ConfigureOptions):String {
	return Reflect.hasField(options, "note")
		? options.name + ":" + Std.string(options.note)
		: options.name + ":missing";
}
```

```ruby
def self.configure(name:, **optional_keywords)
  # Preserve optional keyword presence separately from explicit nil and reject undeclared keys.
  unknown_keywords = optional_keywords.keys - [:note]
  if !unknown_keywords.empty?
    raise ArgumentError, "unknown keyword(s) for self.configure: " + unknown_keywords.inspect
  end
  return optional_keywords.key?(:note) ? name + ":" + optional_keywords[:note].to_s : name + ":missing"
end
```

Ruby's conventional `note: nil` default cannot implement this contract: both an
omitted keyword and an explicitly supplied `note: nil` bind the same local
value. The checked `**optional_keywords` bucket is therefore deliberate, not
generic hash indirection. It records presence with `key?` and rejects keys that
are not declared by the Haxe type.

Direct typed field reads bind to `name` or
`optional_keywords[:note]`; no carrier object or runtime reflection helper is
emitted. If the body returns, stores, mutates, dynamically reflects over, or
passes `options` as a value, the compiler conservatively reconstructs the Haxe
string-key hash. Generated Ruby includes a nearby comment explaining that the
method needs the carrier as a value. This keeps the common Ruby shape small
without changing Haxe anonymous-object behavior in the uncommon first-class
case.

## Native Method Names

Field-level `@:native` is symmetric too. A Haxe-owned method such as
`@:native("ready?") function ready():Bool` emits `def ready?`; bang methods,
writers, and supported operators follow the same validated mapping. Calls from
Haxe use those native names, and ordinary Ruby callers see the exact method
spelling without a wrapper alias. Keyword-carrier fields use the narrower label
rule described above.

## Method Values And Inheritance

Direct annotated calls remain wrapper-free. When an annotated method becomes a
first-class Haxe function value, its type is still an ordinary Haxe function:
keyword carriers and callbacks arrive positionally through `Proc#call`. The
compiler therefore emits an adapter only at genuine method-value capture. The
adapter accepts `*haxe_args`, removes the validated keyword/block carriers,
projects keywords through the declared schema, and invokes the original method
with `**`/`&`. Keeping the remaining arguments as a splat preserves omission of
ordinary optional positional arguments instead of replacing an omitted default
with an explicit `nil`.

```haxe
var visit = worker.visit;
visit("events", {once: true}, value -> value.length);
```

```ruby
visit = ->(*haxe_args) do
  # Adapt this Haxe function value's positional carriers to Ruby keywords and block syntax.
  callable_block = haxe_args.pop
  keyword_options = haxe_args.delete_at(1)
  worker.visit(*haxe_args, once: keyword_options["once"], &callable_block)
end
visit.call("events", {"once" => true}, ->(value) { value.length })
```

This adapter is not a general wrapper runtime and is not emitted for direct
calls. A local/`this` receiver is closed over directly. A call, constructor, or
other effectful receiver is first assigned to a collision-safe
`callable_receiver` local inside `begin`, with a generated comment explaining
why; later invocations reuse that single captured value. Ordinary/rest-only
method values remain native Ruby `Method` objects, and Haxe Rest calls through
them still lower written values/spreads to positional arguments/`*values`.

Callable ABI metadata is inherited as part of the method contract. Calls made
through a base class, interface, concrete class, included module, concern, or
patch must agree. An unannotated override inherits the one effective contract,
including a native Ruby method name. Definitions use that inherited contract to
choose keywords and `yield`/`&block`; calls through every static type use the
same shape. Multiple interfaces, or an explicit override that changes a
previously public positional/keyword/block/rest/native-name contract, fail at
compile time instead of producing static-type-dependent Ruby dispatch.

Recursive calls and same-method Haxe `super.method(...)` forwarding consult the
same effective declaration. Ruby output uses native `super(...)` with projected
keywords and/or `&block`; it does not call a method on the return value of
`super`. Constructors continue to use their existing native keyword/block rules.

## Behavior-Preserving Std Calls

The same callable representation now removes the old `array_map` and
`array_filter` runtime bridges. Haxe's frontend may normalize statically typed
`Array.map`/`filter` calls into direct loops before the Ruby compiler sees them.
When an Array call reaches this backend, RubyHx emits `Array#map` or
`Array#select` directly:

```ruby
values.select { |value| value.ready? }.map(&stored_mapper)
```

Ruby and Haxe agree on new-array allocation, element order, and one callback
invocation per element for these operations. Haxe also requires the filter
callback to return `Bool`. Tail-safe inline callbacks can therefore use normal
Ruby blocks. A stored callback, or an inline callback containing a non-tail
Haxe `return`, remains a strict lambda passed with `&` so Ruby's block return
semantics cannot escape the enclosing generated method. Other Array operations
remain on semantic helpers where boundary normalization, mutation return
values, stringification, or comparator shape still differs.

The canonical authoring example is
[`examples/ruby_callable_abi`](../examples/ruby_callable_abi). It emits a
Haxe-owned library with direct, captured, forwarded, optional, and
keyword-plus-block methods, exercises a precisely typed Ruby stdlib extern,
and is invoked both from Haxe and from committed handwritten Ruby. Its focused
gate proves Ruby syntax, app-facing snapshots, both caller directions, and the
absence of `hxruby/core.rb`/`HXRuby.*` semantic helper calls. The small
`hxruby/data_define.rb` compatibility file may still be retained by the global
Haxe enum support graph; it is unrelated to this ABI.

## Rest And Splat

Haxe's native final `haxe.Rest<T>` parameter is the canonical authoring surface
for Ruby `*args`, and Haxe spread calls lower to Ruby splats. No Ruby-specific
rest metadata is needed for shapes Haxe can express directly.

```haxe
static function join(prefix:String, ...values:Int):String {
	return prefix + values.toArray().join(",");
}

join("values:", 1, 2);
var stored = [3, 4];
join("stored:", ...stored);
```

```ruby
def self.join(prefix, *values)
  return prefix + values.dup.join(",")
end

join("values:", 1, 2)
join("stored:", *stored)
```

The same rule covers static and instance definitions, constructors, and rest
forwarding. Ruby-origin callers pass ordinary positional arguments. The Haxe
Cross target represents both an inline rest list and an explicit spread as one
typed `Rest` carrier; RubyHx unwraps that compiler identity carrier before
printing the splat, which is why generated output contains the original array
rather than `haxe.Rest.of` scaffolding.

Haxe requires `Rest` to be its final parameter, which conflicts with the
trailing keyword-carrier/block convention for Ruby methods combining all three
features. RubyHx rejects that combined declaration with a focused diagnostic;
the compiler will not add speculative index metadata or weaken the types to
model it. A native API with such a shape should expose a narrow typed facade
whose implementation owns the target-specific adaptation.

## Structured Compiler Representation

The Ruby AST distinguishes:

- Required, optional, rest, required-keyword, optional-keyword, keyword-rest,
  and captured-block method parameters.
- Positional, splat, keyword, keyword-splat, and block-pass call arguments.
- A native block attached to a call versus a first-class strict lambda.
- A structured callable-adapter lambda with typed rest parameters.
- `yield` as a dedicated expression.
- Symbols, symbol-key hashes, indexed access, conditional expressions, and
  statement-bearing `begin` expressions used by typed keyword projection.

The AST printer owns Ruby punctuation. Compiler passes must not concatenate
`*`, `**`, `&`, keyword labels, or block delimiters into generic argument
strings. Raw Ruby remains reserved for explicitly audited seams that the AST
cannot yet represent.

## Validation And Diagnostics

The compiler rejects:

- Callable metadata on variables or non-method fields.
- Metadata arguments or duplicate markers.
- `@:rubyBlockArg` without a final precise function parameter.
- `@:rubyKwargs` without an anonymous-object/typedef carrier in the required
  position.
- An optional `@:rubyKwargs` carrier parameter; individual fields own
  optionality.
- Invalid or duplicate Ruby names in a keyword schema.
- A `haxe.Rest` declaration combined with keyword/block metadata.
- Callable metadata on Haxe `dynamic function` fields, whose rebinding would
  discard the declared ABI.
- Invalid field-level `@:native` Ruby method names.
- Incompatible override/interface callable shapes or native method names.

Diagnostics point at the declaration because that is the source of the invalid
ABI promise. Haxe's own type checker continues to own missing required
arguments, callback arity/result types, and keyword carrier field types.

## Verification Contract

Every callable-ABI change must cover the applicable parts of this matrix:

- Extern and Haxe-owned static, instance, patch, module, concern, and
  constructor methods.
- Inline, stored, nullable, method-reference, generic, capturing, zero-argument,
  and multi-argument callbacks.
- Final and early returns, loops, nested functions, throws, and forwarding.
- Inline and stored keyword carriers, required/optional fields, unknown fields,
  native names, rest parameters, and spread calls.
- Ruby-origin callers, generated snapshots, `ruby -c`, runtime behavior, and
  negative compiler diagnostics.
- All examples, todoapp QA, Playwright browser E2E, packages, and the supported
  Ruby 3.3/3.4/4.0 CI matrix.

The focused executable gates are `npm run test:ruby-owned-blocks`,
`npm run test:ruby-keyword-rest`,
`npm run test:ruby-callable-inheritance`,
`npm run test:ruby-callable-abi-example`, and
`npm run test:ruby-callable-diagnostics`.

Focused smoke tests and snapshots own different failure modes. Smoke tests
compile fixtures, run `ruby -c`, execute Haxe-origin and Ruby-origin behavior,
compare stdout and, especially for the diagnostics gate, prove intentionally
invalid programs fail with a useful message. Snapshots own the complete exact
Ruby text for valid programs. A snapshot cannot prove that invalid input emits
no output, while a pattern/runtime smoke test should not approve unrelated
whole-file changes. Both are required, and neither replaces the full repository,
todoapp, production, or Playwright checks.

Current implementation status is intentionally explicit: extern and Haxe-owned
block calls/definitions are symmetric, including constructor, module, concern,
patch-call, optional/captured/forwarded, Ruby-origin, and callback-return
coverage. Keyword calls/definitions are symmetric for required/optional/native
fields, stored and effectful carriers, structural narrowing, constructor,
instance, keyword-plus-block, and Ruby-origin shapes. Native method names and
Rest/splat definitions, calls, constructors, and forwarding are executable and
snapshotted. Static/instance/effectful receiver method values, inherited and
interface ABI resolution, unannotated overrides, recursion, module/concern
captures, native `super` forwarding, and conflict diagnostics are executable and
snapshotted. The pure RubyHx callable example and handwritten Ruby consumer are
executable and snapshotted, and Array map/filter calls reaching the backend use
native Ruby blocks without semantic runtime helpers. Structured AST nodes and
declaration validation own the foundation.
