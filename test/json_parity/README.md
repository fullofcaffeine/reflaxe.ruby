# Broader-Suite `haxe.Json` Parity

This focused lane covers `haxe.Json` because upstream Haxe has no direct
`tests/unit/src/unitstd` fixture for the module.

Provenance:

- scalar, structured, escaping, Unicode, and non-finite-number cases come from
  upstream `tests/unit/src/unit/TestJson.hx`;
- invalid-input catch behavior comes from upstream Issue4592;
- generated-class pretty printing comes from upstream Issue11560;
- replacer traversal follows the documented `haxe.Json.stringify` and
  `haxe.format.JsonPrinter` contract.

Run it with:

```bash
npm run test:json-parity
```

The smoke compiles the Haxe fixture through Reflaxe, executes the generated
Ruby, and checks that Ruby's native `JSON` library remains the parser and final
encoder. `HXRuby.json_prepare` is intentionally limited to projecting Haxe-only
writer semantics into JSON-ready Ruby values.
