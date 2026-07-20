#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const generatedRoot = join(root, "test", ".generated", "ruby_unsupported_expressions");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];
const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));

if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for unsupported-expression diagnostics.");
  process.exit(1);
}

rmSync(generatedRoot, { force: true, recursive: true });
mkdirSync(generatedRoot, { recursive: true });

const positive = compileCase("statement_forms", `
class Main {
  static function main():Void {
    var total = 0;
    for (value in [1, 2, 3]) {
      if (value == 2) continue;
      total += value;
    }
    while (total < 5) {
      total++;
      if (total == 5) break;
    }
    Sys.println(total);
    return;
  }
}
`);
if (positive.status !== 0) {
  process.stdout.write(positive.stdout);
  process.stderr.write(positive.stderr);
  console.error("Supported statement-only typed expressions must remain in statement lowering.");
  process.exit(positive.status ?? 1);
}
const positiveOutput = join(generatedRoot, "statement_forms", "out");
const positiveRuby = readFileSync(join(positiveOutput, "main.rb"), "utf8");
if (positiveRuby.includes("TODO: unsupported expression") || positiveRuby.includes("TODO: inline statement")) {
  console.error("Supported statement lowering emitted an internal TODO fallback.");
  process.exit(1);
}
const runtime = spawnSync("ruby", [join(positiveOutput, "run.rb")], { cwd: root, encoding: "utf8" });
if (runtime.status !== 0 || runtime.stdout !== "5\n") {
  process.stdout.write(runtime.stdout);
  process.stderr.write(runtime.stderr);
  console.error(`Supported statement runtime mismatch: ${JSON.stringify(runtime.stdout)}`);
  process.exit(runtime.status ?? 1);
}

// `__unprotect__` deliberately asks Haxe to retain a bare compiler TIdent. It
// is used only in this negative compiler-boundary fixture; application code
// must use typed constructs and must never depend on this intrinsic.
const negative = compileCase("bare_tident", `
class Main {
  static function main():Void {
    untyped __unprotect__(1);
  }
}
`);
const diagnostics = `${negative.stdout}${negative.stderr}`;
if (negative.status === 0) {
  console.error("Expected an unconsumed compiler TIdent to fail Ruby lowering.");
  process.exit(1);
}
for (const expected of ["RubyHx cannot lower typed expression `TIdent` in value position", "unconsumed compiler identifier `__unprotect__`"]) {
  if (!diagnostics.includes(expected)) {
    console.error(`Unsupported-expression diagnostic missing: ${expected}`);
    console.error(diagnostics);
    process.exit(1);
  }
}

// An unresolved identifier inside `untyped` survives as a TIdent assignment
// target. Valid Haxe source cannot otherwise construct an invalid lvalue, so
// this negative boundary fixture proves compiler-generated typed trees fail at
// their source position instead of falling back to raw Ruby.
const invalidAssignment = compileCase("invalid_assignment_target", `
class Main {
  static function main():Void {
    untyped __rubyhx_invalid_assignment_target__ = 1;
  }
}
`);
const assignmentDiagnostics = `${invalidAssignment.stdout}${invalidAssignment.stderr}`;
if (invalidAssignment.status === 0) {
  console.error("Expected an unsupported typed assignment target to fail Ruby lowering.");
  process.exit(1);
}
for (const expected of [
  "RubyHx cannot lower this typed expression as an assignment target",
  "use a local, field, or indexed value",
  "Main.hx:3:",
]) {
  if (!assignmentDiagnostics.includes(expected)) {
    console.error(`Unsupported-assignment diagnostic missing: ${expected}`);
    console.error(assignmentDiagnostics);
    process.exit(1);
  }
}

console.log("[ruby-unsupported-expressions] OK: statement forms lower and invalid values/assignment targets fail closed");

function compileCase(name, source) {
  const caseRoot = join(generatedRoot, name);
  const sourceRoot = join(caseRoot, "src");
  const outputRoot = join(caseRoot, "out");
  mkdirSync(sourceRoot, { recursive: true });
  writeFileSync(join(sourceRoot, "Main.hx"), source.trimStart());
  return spawnSync("haxe", [
    "-D",
    `ruby_output=${outputRoot}`,
    "-D",
    "reflaxe_runtime",
    "-cp",
    join(root, "src"),
    "-cp",
    sourceRoot,
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  ], {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
}
