#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "set_facade");
const invalidOutputRoot = join(root, "test", ".generated", "set_facade_invalid");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function fail(message) {
  console.error(`[set-facade] ERROR: ${message}`);
  process.exit(1);
}

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

const facadePath = "std/ruby/Set.hx";
const facadeSource = readFileSync(join(root, facadePath), "utf8");
const facadeCode = facadeSource.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");
for (const forbidden of [/\bDynamic\b/, /\bAny\b/, /\buntyped\b/, /\bcast\b/, /__ruby__/, /#if\s+ruby/]) {
  if (forbidden.test(facadeCode)) fail(`${facadePath} widens the typed native boundary with ${forbidden}`);
}
if (!facadeSource.includes("extern class Set<T>")) fail("ruby.Set must remain a generic native extern");
if (/\biterator\s*\(/.test(facadeCode)) fail("ruby.Set must not pretend to implement portable Haxe iteration");

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidOutputRoot, { force: true, recursive: true });
const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) fail("unable to find vendored Reflaxe source");

const baseHaxeArgs = [
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
];

run("haxe", [
  "-D",
  `ruby_output=${outputDir}`,
  "-cp",
  join(root, "test", "set_facade", "src_haxe"),
  ...baseHaxeArgs,
  "-main",
  "Main",
]);

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  if (!existsSync(join(outputDir, file))) fail(`expected generated Ruby file missing: ${file}`);
}

for (const file of ["main.rb", "run.rb"]) {
  const generated = readFileSync(join(outputDir, file), "utf8");
  if ((generated.match(/require "set"/g) ?? []).length !== 1) {
    fail(`${file} must contain exactly one deduplicated require "set"`);
  }
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /Set\.new\(\)/,
  /Set\.new\(\["alpha", "beta", "alpha"\]\)/,
  /values(?:__hx\d+)?\.size\(\)/,
  /values(?:__hx\d+)?\.empty\?\(\)/,
  /values(?:__hx\d+)?\.include\?\("alpha"\)/,
  /values(?:__hx\d+)?\.add\?\("alpha"\)/,
  /values(?:__hx\d+)?\.delete\?\("missing"\)/,
  /values(?:__hx\d+)?\.each \{ \|value(?:__hx\d+)?\|/,
  /left(?:__hx\d+)?\.union\(right(?:__hx\d+)?\)/,
  /left(?:__hx\d+)?\.intersection\(right(?:__hx\d+)?\)/,
  /left(?:__hx\d+)?\.difference\(right(?:__hx\d+)?\)/,
  /alpha_only(?:__hx\d+)?\.subset\?\(left(?:__hx\d+)?\)/,
  /alpha_only(?:__hx\d+)?\.proper_subset\?\(left(?:__hx\d+)?\)/,
  /left(?:__hx\d+)?\.superset\?\(alpha_only(?:__hx\d+)?\)/,
  /left(?:__hx\d+)?\.proper_superset\?\(alpha_only(?:__hx\d+)?\)/,
  /left(?:__hx\d+)?\.intersect\?\(right(?:__hx\d+)?\)/,
  /left(?:__hx\d+)?\.disjoint\?\(Set\.new\(\["delta"\]\)\)/,
  /filtered(?:__hx\d+)?\.delete_if \{ \|value(?:__hx\d+)?\|/,
  /filtered(?:__hx\d+)?\.keep_if \{ \|value(?:__hx\d+)?\|/,
  /mutable(?:__hx\d+)?\.merge\(Set\.new\(\["gamma"\]\)\)/,
  /mutable(?:__hx\d+)?\.subtract\(Set\.new\(\["beta"\]\)\)/,
  /mutable(?:__hx\d+)?\.replace\(Set\.new\(\["replacement"\]\)\)/,
  /mutable(?:__hx\d+)?\.clear\(\)/,
  /values(?:__hx\d+)?\.to_a\(\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(mainRuby);
    fail(`expected direct Set shape missing from main.rb: ${expected}`);
  }
}
if (/class Set(?:\s|$)|Ruby::Set|HXRuby\.(?:set|Set)/.test(mainRuby)) {
  fail("Set facade must dispatch directly without a generated wrapper or runtime helper");
}

assertCompileFailure("InvalidConstruction", "Int should be String");
assertCompileFailure("InvalidElement", "Int should be String");
assertCompileFailure("InvalidEnumerable", "Array<String> should be ruby.Set<String>");
assertCompileFailure("InvalidArrayAccess", "ruby.Set<String> should be Array<String>");
assertCompileFailure("InvalidIdentityMode", "ruby.Set<String> has no field compareByIdentity");

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "true",
  "2",
  "false",
  "true",
  "false",
  "true",
  "true",
  "true",
  "true",
  "alpha,beta",
  "alpha,beta,gamma",
  "beta",
  "alpha",
  "alpha,beta",
  "true",
  "true",
  "true",
  "true",
  "true",
  "true",
  "alpha",
  "alpha,gamma",
  "replacement",
  "true",
  "0",
].join("\n") + "\n";
if (actual !== expected) {
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  fail("runtime stdout mismatch");
}

const versions = run("ruby", [
  "-rset",
  "-e",
  'spec = Gem.loaded_specs["set"]; print RUBY_VERSION, " / set ", (spec ? spec.version : "core")',
]).stdout;
console.log(`[set-facade] OK: generic direct Set behavior and native blocks pass MRI ${versions}`);

function assertCompileFailure(mainClass, expectedDiagnostic) {
  const result = run(
    "haxe",
    [
      "-D",
      `ruby_output=${join(invalidOutputRoot, mainClass)}`,
      "-cp",
      join(root, "test", "set_facade", "invalid"),
      ...baseHaxeArgs,
      "-main",
      mainClass,
    ],
    { allowFailure: true },
  );
  if (result.status === 0) fail(`${mainClass} unexpectedly compiled`);
  const diagnostic = `${result.stdout}\n${result.stderr}`;
  if (!diagnostic.includes(expectedDiagnostic)) {
    console.error(diagnostic);
    fail(`${mainClass} did not produce expected diagnostic: ${expectedDiagnostic}`);
  }
}
