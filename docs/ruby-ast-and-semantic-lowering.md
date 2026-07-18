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

- `RubyCompiler.hx` is 14,575 lines and remains the Reflaxe orchestration
  entrypoint.
- `RubyAST.hx` is 101 lines and owns closed expression/statement syntax.
- `RubyASTValidator` checks cross-node invariants before either a file or a
  standalone expression is printed.
- `RubyCallablePlan` records definition-side block and keyword decisions once
  per method.
- `RubyRuntimePlan` closes the 47 compiler-selected hxruby helpers and gives
  each emitted use a semantic intent.
- The checked inventory currently classifies 322 raw or print-reembed source
  sites. The count is planning evidence, not a product-quality score.

The root compiler ceiling moved down with the extraction. Rails-specific
extraction remains governed separately by
[Ruby Compiler Rails Module Extraction](ruby-compiler-rails-module-extraction.md);
it was intentionally not folded into this core AST slice.

## Layer Ownership

| Layer | Owns | Must not own |
| --- | --- | --- |
| Haxe `TypedExpr` | Resolved Haxe meaning, types, declarations, and source positions | Ruby punctuation |
| Focused semantic plans | Observable Ruby choices that need independent validation | A second copy of every `TypedExprDef` |
| `RubyAST` | Ruby declarations, expressions, statements, control flow, calls, and runtime-use nodes | Haxe type analysis or target text |
| `RubyASTValidator` | Cross-node shape, executable/declaration contexts, and plan/use agreement | Syntax formatting |
| `RubyASTPrinter` | Tokens, precedence, escaping, indentation, and line endings | Semantic rediscovery |
| `RubyOutputIterator` | The single final AST-to-file print boundary | Compiler-side print/re-embedding |

## Structural Syntax Contract

Ordinary migrated syntax is structural:

- `TArray` uses `RubyIndex` in value and assignment positions.
- expression `TIf` uses `RubyConditional`;
- expression `TBlock` uses `RubyBegin`;
- statement `TBlock` uses `RubyStatementSequence`;
- enum tag/parameter access uses `RubyMember`; and
- statement and expression `TSwitch` use `RubyCase` with structural arms and
  an optional default body.

These paths do not print a child AST and insert the resulting string into a raw
node. The switch migration preserves the existing Ruby runtime behavior and
the committed `switch_cases` snapshot byte for byte.

`RubyASTValidator` also rejects declarations inside method/expression bodies,
invalid structural member names, empty `case` arms, and runtime uses whose
intent does not match their helper.

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

Every compiler call through `hxrubyCall` now selects a
`RubyRuntimeHelper`. `RubyRuntimePlan.select` attaches one of these closed
reasons before a `RubyRuntimeCall` AST node is created:

- array semantics;
- iterator compatibility;
- numeric semantics;
- primitive conversion semantics;
- reflection semantics;
- string semantics; or
- type semantics.

The validator recomputes the exhaustive helper-to-intent mapping before
printing. A misspelled helper cannot type-check, a new helper cannot compile
without an intent case, and a mismatched use fails before Ruby source exists.
The existing runtime-use counter still owns per-file `require` placement; it
is no longer the first observable record of why a helper was selected.

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
3. Add a focused semantic plan only when it records an observable target
   decision that needs validation before AST construction.
4. Give every hxruby helper use a closed runtime intent.
5. Do not print an AST subtree for insertion into another raw node.
6. If raw Ruby is genuinely required, keep it at an explicit authority seam,
   document why structure is impractical, and update the inventory owner and
   focused evidence.
7. Preserve source-positioned fail-closed diagnostics for unsupported Haxe
   input.

## Remaining Incremental Debt

The inventory intentionally keeps future work visible. Structural
`begin/rescue/ensure`, raises and loop exits, iterator lowering, more
declarations, Rails artifact IRs, and remaining call/template adapters should
move in independently tested slices. This work does not require:

- a C-like control-flow graph;
- a universal runtime IR;
- a ban on checked native/raw boundaries;
- a rewrite of `RubyCompiler`; or
- coupling the core AST to Rails-specific domain concepts.

Focused evidence for this contract includes:

```bash
npm run test:ruby-ast
npm run test:ruby-ast-inventory
npm run test:switch-cases
npm run test:ruby-unsupported-expressions
npm run test:ruby-owned-blocks
npm run test:ruby-keyword-rest
npm run test:ruby-callable-inheritance
npm run test:ruby-callable-abi-example
npm run test:runtime-usage
npm run test:snapshots
```
