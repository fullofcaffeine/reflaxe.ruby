#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "open3_facade");
const invalidOutputRoot = join(root, "test", ".generated", "open3_facade_invalid");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function fail(message) {
  console.error(`[open3-facade] ERROR: ${message}`);
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

const facadePaths = [
  "std/ruby/Open3.hx",
  "std/ruby/Open3Executable.hx",
  "std/ruby/Open3Capture.hx",
  "std/ruby/Open3Status.hx",
];
for (const path of facadePaths) {
  const source = readFileSync(join(root, path), "utf8");
  const code = source.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");
  for (const forbidden of [/\bDynamic\b/, /\bAny\b/, /\buntyped\b/, /\bcast\b/, /__ruby__/, /#if\s+ruby/]) {
    if (forbidden.test(code)) fail(`${path} widens the typed native boundary with ${forbidden}`);
  }
}

const executableSource = readFileSync(join(root, "std", "ruby", "Open3Executable.hx"), "utf8");
if (!executableSource.includes("abstract Open3Executable(Array<String>)")) {
  fail("Open3Executable must retain its private native [path, argv0] representation");
}
if (/abstract Open3Executable\([^)]*\)\s+(?:from|to)\b/.test(executableSource)) {
  fail("Open3Executable must not expose arbitrary Array conversions");
}

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
  join(root, "test", "open3_facade", "src_haxe"),
  ...baseHaxeArgs,
  "-main",
  "Main",
]);

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  if (!existsSync(join(outputDir, file))) fail(`expected generated Ruby file missing: ${file}`);
}

for (const file of ["main.rb", "run.rb"]) {
  const generated = readFileSync(join(outputDir, file), "utf8");
  if ((generated.match(/require "open3"/g) ?? []).length !== 1) {
    fail(`${file} must contain exactly one deduplicated require "open3"`);
  }
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /Open3\.capture3\(\["ruby", "rubyhx-open3-child"\], \*arguments(?:__hx\d+)?\)/,
  /Open3\.capture3\(\["ruby", "ruby"\], "-e", "STDOUT\.write\('ok'\)"\)/,
  /failed(?:__hx\d+)?\.first\(\)/,
  /failed(?:__hx\d+)?\.fetch\(1\)/,
  /failed_status(?:__hx\d+)? = failed(?:__hx\d+)?\.last\(\)/,
  /failed_status(?:__hx\d+)?\.exitstatus\(\)/,
  /failed_status(?:__hx\d+)?\.success\?\(\)/,
  /failed_status(?:__hx\d+)?\.exited\?\(\)/,
  /failed_status(?:__hx\d+)?\.signaled\?\(\)/,
  /failed_status(?:__hx\d+)?\.termsig\(\)/,
  /failed_status(?:__hx\d+)?\.pid\(\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(mainRuby);
    fail(`expected direct Open3 shape missing from main.rb: ${expected}`);
  }
}
if (/class Open3(?:\s|$)|Ruby::Open3|HXRuby\.(?:open3|Open3)|`[^`]+`|Kernel\.(?:system|exec)/.test(mainRuby)) {
  fail("Open3 facade must use direct capture3 dispatch without a shell, generated wrapper, or runtime helper");
}

assertCompileFailure("InvalidShellString", "String should be ruby.Open3Executable");
assertCompileFailure("InvalidOptions", "{ chdir : String } should be String");
assertCompileFailure("InvalidExecutableAccess", "ruby.Open3Executable should be Array<String>");
assertCompileFailure("InvalidTupleAccess", "ruby.Open3Capture should be Array<String>");

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "literal;$(not-run)",
  "problem",
  "7",
  "false",
  "true",
  "false",
  "true",
  "true",
  "ok",
  "0",
  "0",
  "true",
  "",
].join("\n");
if (actual !== expected) {
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  fail("runtime stdout mismatch");
}

const versions = run("ruby", ["-ropen3", "-e", "print RUBY_VERSION, ' / open3 ', Gem.loaded_specs.fetch('open3').version"]).stdout;
console.log(`[open3-facade] OK: shell-free direct capture and typed status pass MRI ${versions}`);

function assertCompileFailure(mainClass, expectedDiagnostic) {
  const result = run(
    "haxe",
    [
      "-D",
      `ruby_output=${join(invalidOutputRoot, mainClass)}`,
      "-cp",
      join(root, "test", "open3_facade", "invalid"),
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
