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

Compiler-generated overload families may contain both a keyword-carrier form
and a positional form, such as typed ActiveRecord criteria versus an expression
predicate. Haxe retains field metadata while selecting an overload, so the
compiler activates keyword peeling only when that generated invocation's
actual parameter has the declared anonymous-object/typedef shape. This narrow
exception is keyed by the internal generated-stub contract; user-authored
metadata remains strict and cannot silently fall back to positional behavior.

## Generated Call Shapes

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
Ruby block. A non-null nullable callback is forwarded with `&callback`, which
lets Ruby treat `nil` as no block without a wrapper.

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
- Forwarding to another block method or `super` uses `&block`.

Authors do not choose between `yield` and `&block`. Both are generated forms of
the same typed Haxe parameter. The compiler may refine its analysis without
changing source APIs, provided observable behavior remains the same.

Keyword definitions similarly remove the carrier from positional parameters.
Required carrier fields become required Ruby keywords. Optional fields preserve
absence, unknown keys are rejected, and the carrier is materialized only when
the Haxe body uses it as a whole instead of reading known fields.

## Method Values, Inheritance, And Modules

Direct annotated calls remain wrapper-free. When an annotated method becomes a
first-class Haxe function value, the compiler emits an adapter whose Haxe-facing
last positional callback is forwarded as a Ruby block. Instance receivers are
evaluated once when the adapter is created.

Callable ABI metadata is inherited as part of the method contract. Calls made
through a base class, interface, concrete class, included module, concern, or
patch must agree. A conflicting override is a compile error instead of a
static-type-dependent Ruby call shape.

The same rules apply to constructors and `super`. Ruby callers invoke generated
Haxe-owned methods with normal `do ... end` or `{ ... }` blocks; no Haxe runtime
wrapper is part of the public Ruby API.

## Rest And Splat

Haxe's native final `haxe.Rest<T>` parameter is the canonical authoring surface
for Ruby `*args`, and Haxe spread calls lower to Ruby splats. No Ruby-specific
rest metadata is needed for shapes Haxe can express directly.

Haxe requires `Rest` to be its final parameter, which conflicts with the
trailing keyword-carrier/block convention for Ruby methods combining all three
features. That combined shape remains fixture-driven follow-up work; the
compiler will not add speculative index metadata or weaken the types to model
it.

## Structured Compiler Representation

The Ruby AST distinguishes:

- Required, optional, rest, required-keyword, optional-keyword, keyword-rest,
  and captured-block method parameters.
- Positional, splat, keyword, keyword-splat, and block-pass call arguments.
- A native block attached to a call versus a first-class strict lambda.
- `yield` as a dedicated expression.

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
- Callable metadata on Haxe `dynamic function` fields, whose rebinding would
  discard the declared ABI.
- Invalid field-level `@:native` Ruby method names.
- Eventually, incompatible override/interface shapes and unsupported combined
  rest shapes before code generation.

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
  Ruby 3.2/3.3/4.0 CI matrix.

Current implementation status is intentionally explicit: extern inline/stored
block calls are implemented; structured AST nodes and declaration validation
form the shared foundation; symmetric Haxe-owned definitions, full keyword/rest
lowering, method-value adapters, and inheritance checks land in the ordered
follow-up slices tracked under the callable-ABI epic.
