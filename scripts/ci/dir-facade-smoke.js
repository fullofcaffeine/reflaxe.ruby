#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "dir_facade");
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
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

rmSync(outputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for dir_facade.");
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
  join(root, "test", "dir_facade", "src_haxe"),
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
if (/require ["'](?:dir|fileutils|tmpdir)["']/.test(runRuby)) {
  console.error("Ruby's core Dir class should not introduce a stdlib require.");
  process.exit(1);
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /Dir\.pwd\(\)/,
  /Dir\.home\(\)/,
  /Dir\.exist\?\("std"\)/,
  /Dir\.empty\?\("std\/ruby"\)/,
  /Dir\.entries\("std"\)/,
  /Dir\.children\("std"\)/,
  /Dir\.glob\("std\/ruby\/\*\.hx", 0\)/,
  /Dir\.chdir\("std"\)/,
  /Dir\.chdir\(original(?:__hx\d+)?\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected direct Dir shape missing from main.rb: ${expected}`);
    console.error(mainRuby);
    process.exit(1);
  }
}

if (mainRuby.includes("Ruby::Dir") || mainRuby.includes("HXRuby.dir")) {
  console.error("Dir facade should dispatch directly without a generated wrapper or runtime helper.");
  process.exit(1);
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "true",
  "true",
  "true",
  "false",
  "false",
  "true",
  "true",
  "true",
  "0",
  "true",
  "0",
  "true",
  "",
].join("\n");

if (actual !== expected) {
  console.error("dir_facade stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}
