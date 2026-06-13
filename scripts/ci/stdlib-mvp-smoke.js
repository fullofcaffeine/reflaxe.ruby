#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "stdlib_mvp");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

rmSync(outputDir, { force: true, recursive: true });

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile stdlib_mvp through Reflaxe.");
  process.exit(1);
}

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = readFileSync(join(root, "test", "fixtures", "stdlib_mvp", "expected.stdout"), "utf8");

if (actual !== expected) {
  console.error("stdlib_mvp stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

const mathRuby = readFileSync(join(outputDir, "math.rb"), "utf8");
for (const expectedMathShape of [
  /def self\.abs\(v__hx\d+\)\n\s+return v__hx\d+\.abs/,
  /def self\.is_finite\(f__hx\d+\)\n\s+return f__hx\d+\.finite\?/,
]) {
  if (!expectedMathShape.test(mathRuby)) {
    console.error(`Expected idiomatic direct Ruby Math lowering missing: ${expectedMathShape}`);
    console.error(mathRuby);
    process.exit(1);
  }
}
for (const helperCall of ["HXRuby.math_abs", "HXRuby.math_finite?"]) {
  if (mathRuby.includes(helperCall)) {
    console.error(`Math output should not delegate to ${helperCall} when Ruby has matching receiver semantics.`);
    console.error(mathRuby);
    process.exit(1);
  }
}

function compileWithFirstAvailableReflaxe() {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${outputDir}`,
      "-D",
      "reflaxe_runtime",
      "-cp",
      join(root, "src"),
      "-cp",
      join(root, "examples", "stdlib_mvp"),
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "Main",
    ], { allowFailure: true });
    if (result.status === 0) {
      return result;
    }
  }
  return null;
}
