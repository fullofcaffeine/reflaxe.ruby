#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "structural_references");
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

let compiled = false;
for (const reflaxeSrc of reflaxeCandidates) {
  if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) continue;
  const result = run("haxe", [
    "-D",
    `ruby_output=${outputDir}`,
    "-D",
    "reflaxe_runtime",
    "-cp",
    join(root, "src"),
    "-cp",
    join(root, "test", "structural_references", "src_haxe"),
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
    compiled = true;
    break;
  }
  process.stdout.write(result.stdout);
  process.stderr.write(result.stderr);
}
if (!compiled) {
  console.error("Unable to compile the structural-reference contract through Reflaxe.");
  process.exit(1);
}

const mainPath = join(outputDir, "main.rb");
const runPath = join(outputDir, "run.rb");
if (!existsSync(mainPath) || !existsSync(runPath)) {
  console.error("Structural-reference compilation did not emit main.rb and run.rb.");
  process.exit(1);
}

const mainRuby = readFileSync(mainPath, "utf8");
for (const [label, expectedShape] of [
  ["enum constructor owner", /WorkState\.count\(3\)/],
  ["zero-argument enum owner", /WorkState\.idle\(\)/],
  ["member read", /observed = counter\.value/],
  ["member write", /counter\.value = \(observed \+ 1\)/],
  ["static field", /Helpers\.label/],
  ["static method value", /Helpers\.method\(:add_one\)/],
  ["iterator lambda", /iterator_factory = ->\(\) \{ HXRuby\.key_value_iterator\(values\) \}/],
  ["absolute Math constant", /::Math::PI/],
  ["structural negative infinity", /\(-Float::INFINITY\)/],
  ["type constant", /HXRuby\.is_of_type\(counter, Main::Counter\)/],
]) {
  if (!expectedShape.test(mainRuby)) {
    console.error(`Generated structural-reference Ruby is missing ${label}: ${expectedShape}.`);
    console.error(mainRuby);
    process.exit(1);
  }
}

run("ruby", ["-c", mainPath]);
const actual = run("ruby", [runPath]).stdout;
const expected = readFileSync(join(root, "test", "structural_references", "expected.stdout"), "utf8");
if (actual !== expected) {
  console.error("Structural-reference runtime output mismatch.");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

console.log("[structural-references] OK: constant, member, place, method-value, and iterator behavior preserved");
