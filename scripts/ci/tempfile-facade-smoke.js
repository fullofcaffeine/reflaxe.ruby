#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, readdirSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "tempfile_facade");
const runtimeDir = join(outputDir, "runtime");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    rmSync(runtimeDir, { force: true, recursive: true });
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

rmSync(outputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for tempfile_facade.");
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
  join(root, "test", "tempfile_facade", "src_haxe"),
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
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
if (!runRuby.includes('require "tempfile"')) {
  console.error('Expected require "tempfile" missing from run.rb.');
  process.exit(1);
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /Tempfile\.create\("hxruby-scoped-"\) do \|file\|/,
  /File\.exist\?\(file\.path\(\)\)/,
  /file\.write\("scoped tempfile"\)/,
  /file\.flush\(\)/,
  /file\.rewind\(\)/,
  /file\.read\(\)/,
  /Tempfile\.create\(\) do \|file(?:__hx\d+)?\|/,
  /Tempfile\.create\("hxruby-named-", &named_callback(?:__hx\d+)?\)/,
  /Tempfile\.create\("hxruby-in-", runtime_directory(?:__hx\d+)?\)/,
  /Tempfile\.new\("hxruby-explicit-", runtime_directory(?:__hx\d+)?\)/,
  /explicit(?:__hx\d+)?\.close!\(\)/,
  /explicit(?:__hx\d+)?\.closed\?\(\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected direct Tempfile/File shape missing from main.rb: ${expected}`);
    console.error(mainRuby);
    process.exit(1);
  }
}

if (mainRuby.includes("Ruby::Tempfile") || mainRuby.includes("HXRuby.tempfile")) {
  console.error("Tempfile facade should dispatch directly without a generated wrapper or runtime helper.");
  process.exit(1);
}

mkdirSync(runtimeDir, { recursive: true });
const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "true",
  "15",
  "15",
  "0",
  "scoped tempfile",
  "true",
  "7",
  "5",
  "true",
  "true",
  "17",
  "17",
  "0",
  "explicit tempfile",
  "false",
  "true",
  "true",
  "true",
  "",
].join("\n");

if (actual !== expected) {
  console.error("tempfile_facade stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

const leftovers = readdirSync(runtimeDir);
if (leftovers.length !== 0) {
  console.error(`Tempfile facade left files behind: ${leftovers.join(", ")}`);
  process.exit(1);
}
rmSync(runtimeDir, { force: true, recursive: true });
