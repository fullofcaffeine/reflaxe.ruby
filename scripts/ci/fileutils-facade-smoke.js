#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "fileutils_facade");
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
  console.error("Unable to find vendored Reflaxe source for fileutils_facade.");
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
  join(root, "test", "fileutils_facade", "src_haxe"),
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
if (!runRuby.includes('require "fileutils"')) {
  console.error('Expected require "fileutils" missing from run.rb.');
  process.exit(1);
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /FileUtils\.remove_entry_secure\(root(?:__hx\d+)?, true\)/,
  /FileUtils\.mkdir_p\(nested(?:__hx\d+)?\)/,
  /FileUtils\.mkdir\(empty(?:__hx\d+)?\)/,
  /FileUtils\.cp\(source(?:__hx\d+)?, copied(?:__hx\d+)?\)/,
  /FileUtils\.compare_file\(source(?:__hx\d+)?, copied(?:__hx\d+)?\)/,
  /FileUtils\.mv\(copied(?:__hx\d+)?, moved(?:__hx\d+)?\)/,
  /FileUtils\.cp_r\(source_tree(?:__hx\d+)?, copied_tree(?:__hx\d+)?\)/,
  /FileUtils\.touch\(touched(?:__hx\d+)?\)/,
  /FileUtils\.uptodate\?\(moved(?:__hx\d+)?, \[\]\)/,
  /FileUtils\.rm\(touched(?:__hx\d+)?\)/,
  /FileUtils\.rm_f\(/,
  /FileUtils\.rmdir\(empty(?:__hx\d+)?\)/,
  /FileUtils\.remove_entry_secure\(copied_tree(?:__hx\d+)?\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected direct FileUtils shape missing from main.rb: ${expected}`);
    console.error(mainRuby);
    process.exit(1);
  }
}

if (mainRuby.includes("Ruby::FileUtils") || mainRuby.includes("HXRuby.file_utils")) {
  console.error("FileUtils facade should dispatch directly without a generated wrapper or runtime helper.");
  process.exit(1);
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = Array(14).fill("true").concat("").join("\n");

if (actual !== expected) {
  console.error("fileutils_facade stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

if (existsSync(runtimeDir)) {
  console.error(`FileUtils facade fixture did not clean its isolated runtime directory: ${runtimeDir}`);
  process.exit(1);
}
