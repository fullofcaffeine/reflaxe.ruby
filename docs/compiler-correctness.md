# Ruby Compiler Correctness Contract

RubyHx must fail closed when a typed Haxe construct has no supported Ruby
representation. Emitting `nil`, a TODO marker, or partially formed Ruby would
turn a compiler gap into an application behavior change and is not an
acceptable compatibility strategy.

## Typed Expression Ownership

`RubyCompiler.compileExpr` exhaustively owns Haxe's `TypedExprDef` variants:

- Value-capable forms such as constants, fields, calls, functions, blocks,
  conditionals, switches, exceptions, construction, and enum access have
  explicit lowerings.
- `TVar`, `TFor`, `TWhile`, and `TReturn` are statement-only forms. They must be
  consumed by statement lowering; reaching value lowering is an internal
  correctness error.
- `TIdent` represents a compiler intrinsic or target-specific identifier. A
  supported intrinsic must be consumed by a named lowering before generic
  expression compilation. An unrecognized bare identifier fails with its typed
  expression kind, identifier, and Haxe source position.

The switch intentionally has no wildcard fallback. If Haxe adds another typed
expression variant, the compiler must make an explicit support decision rather
than inheriting a silent default.

## Structural Ruby Validation

Typed Haxe meaning lowers into structural `RubyAST` before target syntax is
printed. Ordinary migrated forms such as array access, expression
conditionals/blocks, statement sequences, enum members, and `case` cannot
fall back to raw strings or print a child AST for re-embedding.

`RubyASTValidator` runs before file and standalone-expression printing. It
keeps declarations out of executable bodies, validates closed control shapes,
and cross-checks every typed hxruby runtime use. The checked source inventory
and contributor rules are documented in
[Ruby AST And Semantic Lowering](ruby-ast-and-semantic-lowering.md).

## Intentional Erasure Is Different

Compiler-erased declarations and marker APIs remain explicit, documented
cases. Their lowering returns `RubyNoop` or another named representation before
general expression compilation. Likewise, conservative decoding of untyped
`@:value` metadata is a separate provenance boundary used by Haxe std fallbacks;
it does not authorize a fallback for typed application expressions.

Ruby AST declarations are also forbidden from reaching the inline-statement
renderer. Such a path is an internal compiler error because declarations need
file/class/module ownership and cannot be safely represented by an inline
comment or placeholder.

## Executable Gate

Run:

```bash
npm run test:ruby-unsupported-expressions
npm run test:ruby-ast
npm run test:ruby-ast-inventory
```

The positive fixture proves variable declarations, loops, `continue`, `break`,
and `return` remain in statement lowering and execute correctly. The negative
fixture deliberately retains Haxe's `__unprotect__` compiler intrinsic so a
bare `TIdent` reaches the boundary; compilation must fail with an actionable,
source-positioned diagnostic. The intrinsic is confined to that negative test
and is not an application-facing escape hatch.
