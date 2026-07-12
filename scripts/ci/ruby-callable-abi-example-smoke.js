#!/usr/bin/env node

const { existsSync, readFileSync, readdirSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "ruby_callable_abi");
const fixtureDir = join(root, "test", "fixtures", "ruby_callable_abi");
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
    env: options.env ?? process.env,
  });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

rmSync(outputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for the Ruby callable ABI example.");
  process.exit(1);
}

run("haxe", [
  "-D",
  `ruby_output=${outputDir}`,
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  join(root, "examples", "ruby_callable_abi"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "--macro",
  'haxe.macro.Compiler.keep("Main")',
  "--dce",
  "full",
  "-main",
  "Main",
]);

for (const file of ["callable_api.rb", "main.rb", "run.rb"]) {
  if (!existsSync(join(outputDir, file))) {
    console.error(`Expected generated Ruby file missing: ${file}`);
    process.exit(1);
  }
}
if (existsSync(join(outputDir, "hxruby", "core.rb"))) {
  console.error("The pure RubyHx callable example must not emit hxruby/core.rb.");
  process.exit(1);
}

for (const file of readdirSync(outputDir).filter((name) => name.endsWith(".rb"))) {
  const syntax = run("ruby", ["-c", join(outputDir, file)]).stdout;
  if (syntax !== "Syntax OK\n") {
    console.error(`Ruby syntax check failed for ${file}: ${JSON.stringify(syntax)}`);
    process.exit(1);
  }
  const source = readFileSync(join(outputDir, file), "utf8");
  if (source.includes("HXRuby") || source.includes("array_map") || source.includes("array_filter")) {
    console.error(`Runtime helper leakage in ${file}.`);
    process.exit(1);
  }
}

const callableRuby = readFileSync(join(outputDir, "callable_api.rb"), "utf8");
const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
for (const expected of [
  /def self\.direct\(value\)/,
  /yield\(value\)/,
  /def self\.capture\(&block\)/,
  /def self\.forward\(value, &block\)/,
  /direct\(value, &block\)/,
  /def self\.optional\(value, &block\)/,
  /def self\.decorate\(value, prefix:, suffix:\)/,
]) {
  if (!expected.test(callableRuby)) {
    console.error(`Expected Haxe-owned callable shape missing: ${expected}`);
    console.error(callableRuby);
    process.exit(1);
  }
}
for (const expected of [
  /Kernel\.puts\(CallableApi\.direct\(3\) \{ \|value\| \(value \* 2\) \}\)/,
  /CallableApi\.capture \{ \|value(?:__hx\d+)?\| \(value(?:__hx\d+)? \+ 10\) \}/,
  /CallableApi\.forward\(4\) \{ \|value(?:__hx\d+)?\| \(value(?:__hx\d+)? \* 3\) \}/,
  /CallableApi\.decorate\("ruby", prefix: "typed-", suffix: "!"\) \{ \|value(?:__hx\d+)?\| value(?:__hx\d+)?\.upcase\(\) \}/,
  /Tempfile\.create\("rubyhx-callable-"\) do \|file\|/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected Haxe-origin callable shape missing: ${expected}`);
    console.error(mainRuby);
    process.exit(1);
  }
}
if (!runRuby.includes('require "tempfile"') || runRuby.includes("hxruby/core")) {
  console.error("run.rb must require Ruby Tempfile directly and remain helper-runtime free.");
  console.error(runRuby);
  process.exit(1);
}

const haxeActual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const haxeExpected = readFileSync(join(fixtureDir, "expected.stdout"), "utf8");
if (haxeActual !== haxeExpected) {
  console.error("Ruby callable ABI Haxe-origin stdout mismatch.");
  console.error(`expected: ${JSON.stringify(haxeExpected)}`);
  console.error(`actual:   ${JSON.stringify(haxeActual)}`);
  process.exit(1);
}

const rubyActual = run("ruby", ["-I", outputDir, join(fixtureDir, "ruby_origin.rb")]).stdout;
const rubyExpected = readFileSync(join(fixtureDir, "ruby_origin.expected.stdout"), "utf8");
if (rubyActual !== rubyExpected) {
  console.error("Ruby callable ABI Ruby-origin stdout mismatch.");
  console.error(`expected: ${JSON.stringify(rubyExpected)}`);
  console.error(`actual:   ${JSON.stringify(rubyActual)}`);
  process.exit(1);
}

console.log("[ruby-callable-abi-example] OK: Haxe and handwritten Ruby callers share one runtime-free ABI");
