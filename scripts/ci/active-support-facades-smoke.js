#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "active_support_facades");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
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

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for active_support_facades.");
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
  join(root, "examples", "active_support_facades"),
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
for (const expected of [
  'require "active_support/core_ext/object/blank"',
  'require "active_support/core_ext/string/filters"',
]) {
  if (!runRuby.includes(expected)) {
    console.error(`Expected ActiveSupport require missing from run.rb: ${expected}`);
    console.error(runRuby);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /title(?:__hx\d+)?\.squish\(\)/,
  /normalized(?:__hx\d+)?\.presence\(\)/,
  /""\.blank\?\(\)/,
  /normalized(?:__hx\d+)?\.present\?\(\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected ActiveSupport receiver call shape missing from main.rb: ${expected}`);
    console.error(mainRuby);
    process.exit(1);
  }
}

const activeSupportCheck = run("ruby", [
  "-e",
  'require "active_support/core_ext/object/blank"; require "active_support/core_ext/string/filters"',
], { allowFailure: true });

if (activeSupportCheck.status !== 0) {
  console.log("[active-support-facades] ActiveSupport is unavailable; skipped runtime facade pass.");
  console.log("[active-support-facades] Static compile and generated Ruby shape checks passed.");
  process.exit(0);
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "true",
  "true",
  "true",
  "Ship typed Rails",
  "",
].join("\n");

if (actual !== expected) {
  console.error("active_support_facades stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}
