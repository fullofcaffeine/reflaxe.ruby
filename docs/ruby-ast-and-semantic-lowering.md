# Ruby AST And Semantic Lowering

RubyHx keeps one compiler pipeline:

```text
Haxe TypedExpr -> focused Ruby semantic plans -> RubyAST -> RubyASTPrinter -> .rb
```

This is the implemented architecture contract for
[GitHub issue #20](https://github.com/fullofcaffeine/reflaxe.ruby/issues/20).
The issue was sound and worth implementing in a bounded form. RubyHx already
had a target AST, so a universal IR or a duplicate Haxe AST would have added
cost without a new correctness boundary. The real gap was that ordinary Ruby
syntax and several observable Ruby-specific decisions became text or ambient
state too early.

## Live Assessment

At this slice:

- `RubyCompiler.hx` is 14,527 lines and remains the Reflaxe orchestration
  entrypoint.
- `RubyAST.hx` is 123 lines and owns closed expression/statement syntax.
- `RubyExceptionLowering.hx` is 133 lines and owns pre-filter typed catch
  dispatch through structural RubyAST plus an exact core-runtime-use count.
- `RubyInt32Lowering.hx` is 46 lines and owns signed 32-bit clamping plus
  five-bit signed/unsigned shift shaping through ordinary structural RubyAST.
- `RubyLoopLowering.hx` owns the fixed structural iterator/`while` expansion
  without retaining a semantic loop node or depending back on the compiler.
- `RubyASTChildren` exhaustively owns every immediate structural child and the
  declaration-versus-executable role of every statement body.
- `RubyASTValidator` checks cross-node invariants before either a file or a
  standalone expression is printed.
- `RubyCallablePlan` records definition-side block and keyword decisions once
  per method.
- `RubyRuntimePlan` closes the 49 compiler-selected hxruby helpers and gives
  each emitted use a semantic intent.
- The checked inventory currently classifies 294 raw or print-reembed source
  sites: 14 core-lowering, 101 validated-framework, and 126 print-reembed
  sites, with the remaining categories recorded in the inventory. The count is
  planning evidence, not a product-quality score.

The root compiler ceiling moved down with the extraction. Rails-specific
extraction remains governed separately by
[Ruby Compiler Rails Module Extraction](ruby-compiler-rails-module-extraction.md);
it was intentionally not folded into this core AST slice.

## Layer Ownership

| Layer | Owns | Must not own |
| --- | --- | --- |
| Haxe `TypedExpr` | Resolved Haxe meaning, types, declarations, and source positions | Ruby punctuation |
| Focused semantic plans | Observable Ruby choices that need independent validation | A second copy of every `TypedExprDef` |
| Focused vertical lowerings | One source/target semantic gap through structural AST plus explicit runtime requirements | Global compiler state or printer-side repair |
| `RubyAST` | Ruby declarations, expressions, statements, control flow, calls, and runtime-use nodes | Haxe type analysis or target text |
| `RubyASTChildren` | Exhaustive immediate children, deterministic child order, and declaration/executable body roles | Semantic lowering, raw-text inspection, or pass scheduling |
| `RubyASTValidator` | Cross-node shape, executable/declaration contexts, and plan/use agreement | Syntax formatting |
| `RubyASTPrinter` | Tokens, precedence, escaping, indentation, and line endings | Semantic rediscovery |
| `RubyOutputIterator` | The single final AST-to-file print boundary | Compiler-side print/re-embedding |

## Structural Syntax Contract

Ordinary migrated syntax is structural:

- `TArray` uses `RubyIndex` in value and assignment positions.
- expression `TIf` uses `RubyConditional`;
- expression `TBlock` uses `RubyBegin`;
- statement `TBlock` uses `RubyStatementSequence`;
- enum tag/parameter access uses `RubyMember`;
- statement and expression `TSwitch` use `RubyCase` with structural arms and
  an optional default body;
- statement and expression `TTry` use `RubyBeginRescue`;
- statement and expression `TThrow` use `RubyRaise`;
- statement and expression `TBreak`/`TContinue` use payload-free `RubyBreak`
  and `RubyNext`; and
- residual `TFor` uses structural assignment, calls, and `RubyWhileStmt`;
- `haxe.Int32` casts, arithmetic result clamps, and signed/unsigned shifts use
  nested `RubyBinary`/`RubyCall` expressions rather than rendered fragments;
  and
- `ruby.Symbol.of`, canonical Rails `PermitSpec.field`, and literal-key
  `PermitSpec.nested` use `RubySymbol`, `RubyCall`, and `RubySymbolHash` rather
  than rendered symbol/hash fragments.

These paths do not print a child AST and insert the resulting string into a raw
node. The switch migration preserves the existing Ruby runtime behavior and
the committed `switch_cases` snapshot byte for byte.

Exception lowering is a bounded semantic migration because Reflaxe captures
the typed tree before Haxe target exception filtering. One structural
`rescue StandardError` therefore unwraps only the compiler-owned carrier and
dispatches Haxe catch arms in source order with typed `HXRuby.is_of_type`
checks. `Dynamic` receives the unwrapped thrown value. The exact
`haxe.Exception` wildcard receives an `HxException.caught` adapter so its
typed message accessor works for native Ruby errors; an explicit throw of that
adapter restores the original native exception. A nonmatching arm emits a bare
`raise`, preserving Ruby identity and backtrace, and `HxException.wrap`
evaluates the thrown expression once.

This slice deliberately has no `ensure` field or general control-flow IR:
Haxe `TTry` has no cleanup payload, so no current producer or independent
consumer earns that representation.

Haxe 4.3 normalizes many authored `for` loops to `TWhile` before Reflaxe sees
them, but `TFor` remains part of the typed input contract for explicitly
assembled or otherwise unnormalized trees. `RubyLoopLowering` owns that
residual path as ordinary target structure: the caller selects and compiles the
iterator expression once, allocates its readable source-position temporary in
the request-local collision domain, and supplies the compiled body. The focused
contract pre-reserves that exact temporary and proves deterministic suffixing,
while runtime evidence covers one-time iterable evaluation and nested
`break`/`continue` behavior. A `LoopPlan` would retain no additional fact and
therefore does not pass the semantic-plan admission test.

Fixed-width Int32 lowering is another target-earned semantic boundary, but it
does not earn an `Int32Plan` or IR node. `RubyCompiler` still owns the typed
decision that a value is `haxe.Int32`; after that decision, Ruby's
arbitrary-precision Integer only needs a closed structural recipe: centered
modulo for the signed range, low-five-bit shift counts, and an unsigned mask
for logical right shift. `RubyInt32Lowering` owns that recipe without source
typing, mutable state, raw text, printer access, or a dependency back on the
compiler. Exact AST tests own shape and the provenance-locked upstream
`haxe.Int32` fixture owns runtime parity.

Ruby symbol lowering does not earn a plan or a new AST constructor. Literal
symbols retain only their string payload in `RubySymbol`, so
`RubyASTPrinter` alone decides compact `!`/`?`/`=` spelling and escaping.
The printer uses a strict whole-string identifier scan and escapes Ruby's
double-quoted interpolation prefixes as well as control characters. Runtime
`String` values compile once as an ordinary receiver followed by a structural
`to_sym` call. The canonical `PermitSpec` macro path supplies literal field
names, so empty and literal-key nested specs fit the existing `RubySymbolHash`
node.

The low-level direct-extern `PermitSpec.nested` path can still present an
expression-valued key. Current hash nodes intentionally carry static string
keys, and one non-canonical fallback does not justify broadening the schema.
Calling `::Hash.[]` or staging an empty hash plus `[]=` would avoid literal
syntax but introduce observable, monkey-patchable method dispatch that a Ruby
hash literal does not perform.
That path therefore remains one explicit raw/print-reembed boundary. A direct
extern fixture verifies its generated shape and real Rails strong-params
behavior. The inventory records its raw node and both rendered children
separately; this is why the reviewed total is 294 rather than the initially
estimated 292.

The architecture pressure test also considered a broader place plan. An
authored `receiver()[index()] += 5` probe compiled to one receiver temporary,
one index temporary, and a structural read/write, then ran with the expected
`15:1:1` value/call counts. Reflaxe therefore already preserves one-evaluation
place scheduling for normal source. That counter-evidence rejects a
`RubyPlacePlan` until an actual unsupported typed path proves otherwise.

`RubyExceptionLowering` owns this vertical feature without depending back on
`RubyCompiler`. The orchestration entrypoint supplies typed callbacks for
ordinary expression/body compilation, local allocation, and Ruby type naming;
the service returns structural AST plus the exact number of `HXRuby` core
uses it introduced. `RubyCompiler` alone applies those request-local runtime
requirements.

`RubyASTValidator` also rejects declarations inside method/expression bodies,
invalid structural member names, empty `case` arms, and runtime uses whose
intent does not match their helper.

## Exhaustive Child Contract

`RubyASTChildren` is the one authoritative child schema for statements,
expressions, method-parameter defaults, callable arguments, native blocks,
hash fields, and case branches. Its immediate mappers have an explicit case for
every constructor and deliberately have no catch-all. Raw statement and
expression nodes are opaque leaves because the compiler cannot safely infer
children, bindings, or control flow from their target text.

The schema also assigns every nested statement body one of two structural
roles:

- declaration bodies may contain modules, classes, and methods; and
- executable bodies reject declarations before Ruby punctuation is emitted.

Deterministic preorder walking is derived from the immediate mapping rather
than maintained through another recursive switch. `RubyASTValidator` owns only
node-local and cross-node invariants, then delegates child recursion and role
propagation to this schema. Adding or changing an AST constructor therefore
requires an explicit child/scope decision plus identity, sentinel-child, and
scope-order evidence in `npm run test:ruby-ast`.

## When A Semantic Plan Earns Its Cost

A plan is justified only when it records an observable decision that would
otherwise require synchronized side tables, independent ambient flags, or
target-text inspection.

`RubyCallablePlan` earns that cost for Haxe-owned methods. It composes the
existing `RubyCallableShape`, `RubyBlockSemantics`, and
`RubyKeywordSemantics` results into one request-local plan before AST
construction:

- no block, direct `yield`, or captured `&block`;
- no keywords, direct keyword locals, or a materialized Haxe carrier;
- the validated callable ABI contract;
- the Haxe source position; and
- a reason for every non-obvious representation choice.

Recursive expression lowering sees one scoped callable context containing that
plan plus allocation-dependent keyword local names. The former independent
direct-yield and keyword-carrier ambient states no longer exist. Call-site
attached blocks and method-value adapters remain focused later slices; copying
their `TypedExpr` shapes into this definition plan would not improve
validation.

## Runtime Intent

Every compiler-selected runtime call through `hxrubyCall` or a focused
lowering such as `RubyExceptionLowering` selects a `RubyRuntimeHelper`.
`RubyRuntimePlan.select` attaches one of these closed reasons before a
`RubyRuntimeCall` AST node is created:

- array semantics;
- iterator compatibility;
- numeric semantics;
- primitive conversion semantics;
- reflection semantics;
- string semantics;
- type semantics; or
- exception-boundary semantics.

The same plan selects the runtime receiver: ordinary helpers target `HXRuby`,
while `ExceptionCaught` and `ExceptionWrap` target `HxException`. The
validator recomputes the exhaustive helper-to-intent mapping before printing.
A misspelled helper cannot type-check, a new helper cannot compile without
receiver and intent decisions, and a mismatched use fails before Ruby source
exists. The existing runtime-use counter still owns per-file `require`
placement; it is no longer the first observable record of why a helper was
selected.

## Raw And Print-Reembed Inventory

[ruby-ast-lowering-inventory.json](ruby-ast-lowering-inventory.json) is
generated from every `RubyRawExpr`, `RubyRawStatement`,
`RubyASTPrinter.printExpr`, `RubyASTPrinter.printFile`,
`printInlineExpr`, and legacy inline-statement-renderer source site below
`src/reflaxe/ruby`.

Each category records an owner, executable evidence, and a disposition:

- explicit authorized raw Ruby;
- validated framework artifacts;
- core lowering migration debt;
- callable lowering migration debt;
- compatibility semantic boundaries;
- target declaration migration debt;
- print-reembed debt;
- AST infrastructure; and
- the single final output boundary.

Regenerate only after reviewing the classified diff:

```bash
UPDATE_RUBY_AST_INVENTORY=1 npm run test:ruby-ast-inventory
npm run test:ruby-ast-inventory
```

The gate also asserts the completed structural source contracts and forbids the
removed raw/ambient paths. Raw-node count alone must never be used to claim
compiler quality: an authorized native seam can be correct, while one
print-reembedded semantic transform can be dangerous.

## Contributor Rule

When adding lowering:

1. Keep Haxe meaning in `TypedExpr`.
2. Use or add a closed `RubyAST` form for ordinary Ruby syntax.
3. Update `RubyASTChildren` and its exhaustive child/scope tests for every new
   constructor or nested child carrier.
4. Add a focused semantic plan only when it records an observable target
   decision that needs validation before AST construction.
5. Give every hxruby helper use a closed runtime intent.
6. Do not print an AST subtree for insertion into another raw node.
7. If raw Ruby is genuinely required, keep it at an explicit authority seam,
   document why structure is impractical, and update the inventory owner and
   focused evidence.
8. Preserve source-positioned fail-closed diagnostics for unsupported Haxe
   input.

## Remaining Incremental Debt

The inventory intentionally keeps future work visible. More declarations,
Rails artifact IRs, and remaining call/template adapters should move in
independently tested slices. Ruby
`ensure` should be admitted only when an actual source or framework producer
owns its semantics. This work does not require:

- a C-like control-flow graph;
- a universal runtime IR;
- a ban on checked native/raw boundaries;
- a rewrite of `RubyCompiler`; or
- coupling the core AST to Rails-specific domain concepts.

Focused evidence for this contract includes:

```bash
npm run test:ruby-ast
npm run test:ruby-call-shapes
npm run test:action-controller-params
npm run test:ruby-compiler-decomposition
npm run test:ruby-loop-control
npm run test:ruby-ast-inventory
npm run test:switch-cases
npm run test:exception-flow
npm run test:ruby-unsupported-expressions
npm run test:ruby-owned-blocks
npm run test:ruby-keyword-rest
npm run test:ruby-callable-inheritance
npm run test:ruby-callable-abi-example
npm run test:runtime-usage
npm run test:runtime-minitest
npm run test:unitstd-ruby
npm run test:snapshots
```
