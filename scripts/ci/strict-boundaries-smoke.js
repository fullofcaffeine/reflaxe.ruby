#!/usr/bin/env node

const { existsSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for strict boundary tests.");
  process.exit(1);
}

expectFailure({
  name: "strict examples",
  fixture: "strict_examples",
  define: "reflaxe_ruby_strict_examples",
  expected: "BoundaryEnforcer: __ruby__ is not allowed in strict examples",
});

expectFailure({
  name: "strict mode",
  fixture: "strict_mode",
  define: "reflaxe_ruby_strict",
  expected: "StrictModeEnforcer: __ruby__ is not allowed in strict mode",
});

function expectFailure({ name, fixture, define, expected }) {
  const result = run("haxe", [
    "-D",
    `ruby_output=${join(root, "test", ".generated", "strict_boundaries", fixture)}`,
    "-D",
    "reflaxe_runtime",
    "-D",
    define,
    "-cp",
    join(root, "src"),
    "-cp",
    join(root, "test", "fixtures", "strict_boundaries", fixture),
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  ]);

  if (result.status === 0) {
    console.error(`Expected ${name} compile to fail.`);
    process.exit(1);
  }

  const output = `${result.stdout}\n${result.stderr}`;
  if (!output.includes(expected)) {
    console.error(`${name} failure did not include expected diagnostic: ${expected}`);
    console.error(output);
    process.exit(1);
  }
}

function run(command, args) {
  return spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
}
