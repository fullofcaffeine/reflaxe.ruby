#!/usr/bin/env node

const { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } = require("node:fs");
const { delimiter, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");

const root = resolve(__dirname, "..", "..");
const fixtureRoot = join(root, "test", "fixtures", "rbs_generator");
const outputRoot = join(root, "test", ".generated", "rbs_generator");
const generatedSourceRoot = join(outputRoot, "src_haxe");
const rubyOutput = join(outputRoot, "ruby");
const script = join(root, "scripts", "rbs", "generate-extern.rb");
const snapshot = join(root, "test", "snapshots", "m1", "rbs_generator", "generated", "rbs", "FixtureCatalog.hx");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function fail(message) {
  console.error(`[rbs-generator] ERROR: ${message}`);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
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

function generate(input, extra = []) {
  return run("ruby", [
    "-I",
    join(root, "lib"),
    script,
    "--root",
    fixtureRoot,
    "--input",
    input,
    "--constant",
    "FixtureCatalog",
    "--package",
    "generated.rbs",
    "--require",
    "fixture_catalog",
    "--source-label",
    "catalog.rbs",
    ...extra,
  ]).stdout;
}

const first = generate("catalog.rbs");
const repeated = generate("catalog.rbs");
const permuted = generate("catalog_permuted.rbs");
if (first !== repeated || first !== permuted) {
  fail("identical contracts did not produce byte-identical canonical output");
}
if (!existsSync(snapshot) || readFileSync(snapshot, "utf8") !== first) {
  fail("generated extern does not match the committed canonical snapshot");
}
for (const forbidden of [/\bDynamic\b/, /\bAny\b/, /\buntyped\b/, /\bcast\b/, /__ruby__/]) {
  if (forbidden.test(first)) fail(`generated extern contains forbidden broad escape ${forbidden}`);
}
const help = run("ruby", ["-I", join(root, "lib"), script, "--help"]).stdout;
if (!help.includes("Usage: generate-rbs-extern") || !help.includes("--source-label")) {
  fail("generator help does not describe the checked stdout-only command");
}
expectFailure([], "Missing required option --root");

rmSync(outputRoot, { force: true, recursive: true });
const generatedPath = join(generatedSourceRoot, "generated", "rbs", "FixtureCatalog.hx");
mkdirSync(resolve(generatedPath, ".."), { recursive: true });
writeFileSync(generatedPath, first);

const reflaxeSrc = reflaxeCandidates.find((candidate) => existsSync(join(candidate, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) fail("unable to find vendored Reflaxe source");
run("haxe", [
  "-D",
  `ruby_output=${rubyOutput}`,
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  generatedSourceRoot,
  "-cp",
  join(root, "test", "rbs_generator", "src_haxe"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "-main",
  "Main",
]);

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  if (!existsSync(join(rubyOutput, file))) fail(`expected generated Ruby file missing: ${file}`);
}
const runRuby = readFileSync(join(rubyOutput, "run.rb"), "utf8");
if ((runRuby.match(/require "fixture_catalog"/g) ?? []).length !== 1) {
  fail('run.rb must contain exactly one require "fixture_catalog"');
}
const mainRuby = readFileSync(join(rubyOutput, "main.rb"), "utf8");
for (const expected of [
  /FixtureCatalog\.new\("typed"\)/,
  /\.label_for\("item", 2\)/,
  /\.maybe_label\(nil\)/,
  /\.empty\?\(\)/,
  /\.nested_rows\(/,
  /FixtureCatalog\.normalize\("  READY  "\)/,
]) {
  if (!expected.test(mainRuby)) fail(`expected direct generated Ruby call missing: ${expected}`);
}
if (/HXRuby\.Rbs|class FixtureCatalog/.test(mainRuby)) {
  fail("generated extern introduced a wrapper instead of direct native dispatch");
}
const runtime = run("ruby", [join(rubyOutput, "run.rb")], {
  env: {
    ...process.env,
    RUBYLIB: [join(fixtureRoot, "runtime"), process.env.RUBYLIB].filter(Boolean).join(delimiter),
  },
});
const expectedStdout = ["typed:item:2", "", "false", "a:b", "ready", ""].join("\n");
if (runtime.stdout !== expectedStdout) {
  fail(`runtime stdout mismatch: ${JSON.stringify(runtime.stdout)}`);
}

expectFailure([
  "--root", fixtureRoot,
  "--input", "missing.rbs",
  "--constant", "Missing",
  "--package", "generated.rbs",
], "RBS source does not exist");
expectFailure([
  "--root", fixtureRoot,
  "--input", "../catalog.rbs",
  "--constant", "FixtureCatalog",
  "--package", "generated.rbs",
], "safe forward-slash relative path");
expectFailure([
  "--root", fixtureRoot,
  "--input", "catalog.rbs",
  "--constant", "Missing",
  "--package", "generated.rbs",
], "RBS constant Missing was not found");

const unsafeRoot = mkdtempSync(join(tmpdir(), "hxruby-rbs-root."));
const outsideRoot = mkdtempSync(join(tmpdir(), "hxruby-rbs-outside."));
try {
  const outside = join(outsideRoot, "outside.rbs");
  writeFileSync(outside, "class Outside\nend\n");
  symlinkSync(outside, join(unsafeRoot, "escape.rbs"));
  expectFailure([
    "--root", unsafeRoot,
    "--input", "escape.rbs",
    "--constant", "Outside",
    "--package", "generated.rbs",
  ], "must resolve to a file inside");

  writeFileSync(join(unsafeRoot, "malformed.rbs"), "class Broken\n  def value: () -> String\n");
  expectFailure([
    "--root", unsafeRoot,
    "--input", "malformed.rbs",
    "--constant", "Broken",
    "--package", "generated.rbs",
  ], "Unterminated RBS declaration");
} finally {
  rmSync(unsafeRoot, { force: true, recursive: true });
  rmSync(outsideRoot, { force: true, recursive: true });
}

console.log("[rbs-generator] OK: deterministic extern compiles, dispatches directly, and fails closed");

function expectFailure(args, expected) {
  const result = run("ruby", ["-I", join(root, "lib"), script, ...args], { allowFailure: true });
  if (result.status === 0 || !result.stderr.includes(expected)) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    fail(`expected generator failure containing ${JSON.stringify(expected)}`);
  }
}
