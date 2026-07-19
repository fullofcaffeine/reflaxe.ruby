#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "exception_flow");
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
  console.error("Unable to compile exception_flow through Reflaxe.");
  process.exit(1);
}

for (const file of ["hxruby/core.rb", "hxruby/hx_exception.rb", "main.rb", "run.rb"]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = readFileSync(join(root, "test", "fixtures", "exception_flow", "expected.stdout"), "utf8");

if (actual !== expected) {
  console.error("exception_flow stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

const generatedSource = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expectedShape of [
  "rescue StandardError => haxe_exception",
  "HxException.caught(haxe_exception)",
  "HXRuby.is_of_type(haxe_thrown, String)",
  "HXRuby.is_of_type(haxe_thrown, Int)",
  "HXRuby.is_of_type(haxe_thrown, StandardError)",
  "raise HxException.wrap(",
]) {
  if (!generatedSource.includes(expectedShape)) {
    console.error(`exception_flow missing structural shape: ${expectedShape}`);
    process.exit(1);
  }
}
if (generatedSource.includes("HxException.new(") || !/else\n\s+raise\n/.test(generatedSource)) {
  console.error("exception_flow must wrap through HxException.wrap and bare-reraise unmatched catches");
  process.exit(1);
}
if ((generatedSource.match(/HxException\.wrap\(Main\.next_thrown_value\(\)\)/g) ?? []).length !== 1) {
  console.error("exception_flow thrown expression must be emitted exactly once");
  process.exit(1);
}

const uncaught = run("ruby", [
  `-I${outputDir}`,
  "-e",
  'require "hxruby/core"; require "hxruby/hx_exception"; require "main"; Main.fail',
], { allowFailure: true });
const uncaughtOutput = `${uncaught.stdout}\n${uncaught.stderr}`;
const generatedMain = join(outputDir, "main.rb");
if (uncaught.status === 0 || !uncaughtOutput.includes(`${generatedMain}:`) || !uncaughtOutput.includes("HxException") || !uncaughtOutput.includes("boom")) {
  process.stdout.write(uncaught.stdout);
  process.stderr.write(uncaught.stderr);
  console.error("Uncaught Haxe exception did not retain a useful generated-Ruby backtrace.");
  process.exit(1);
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
      join(root, "examples", "exception_flow"),
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
