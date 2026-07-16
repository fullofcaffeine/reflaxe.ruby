# Shared Ruby/JavaScript Domain Behavior

This example proves one deliberately bounded full-stack contract. The same
typed Haxe source normalizes and validates a todo draft, returns closed typed
errors, and serializes the result with deterministic field ordering. CI compiles
the same `domain/TodoDraftVectors.hx` vectors through small Ruby and JavaScript
entrypoints, executes both, and requires byte-identical JSONL matching
`expected.jsonl`.

Run the focused contract with:

```bash
npm run test:full-stack-shared-behavior
```

`domain/TodoDraftContract.hx` demonstrates the useful shared middle of a
full-stack application. Rails params, persistence, transactions, and localized
error presentation remain Ruby/Rails-owned. DOM events, browser storage, and
network requests remain JavaScript-owned.

The contract intentionally collapses only ASCII form whitespace and otherwise
preserves Unicode text. Its title limit follows Haxe/JavaScript UTF-16 units on
both targets, so a non-BMP character such as an emoji counts as two units. The
writer is one-way and typed: it serializes the closed result model, while
parsing untrusted transport input remains a target-specific boundary.

The parity lane uses Haxe's stock JavaScript emitter so target semantics can run
directly under Node. The canonical Rails todoapp separately proves that Genes
emits importmap-friendly browser modules and that Rails, Turbo, and Playwright
work in development and production. This example does not claim arbitrary
Ruby/JavaScript code is isomorphic or that framework code belongs in shared
modules.
