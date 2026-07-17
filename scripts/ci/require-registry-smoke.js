#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "require_metadata");
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
  console.error("Unable to compile require_metadata through Reflaxe.");
  process.exit(1);
}

for (const file of ["main.rb", "run.rb"]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

for (const file of ["native_json.rb", "native_date.rb"]) {
  if (existsSync(join(outputDir, file))) {
    console.error(`Extern should not be emitted: ${file}`);
    process.exit(1);
  }
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
assertOrdered(runRuby, [
  'require "date"',
  'require "json"',
  'require "set"',
  "$LOAD_PATH.unshift(__dir__)",
  'require_relative "./support/native_date"',
  'require_relative "./support/native_time"',
  'require_relative "hxruby/core"',
  'require_relative "main"',
]);

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
assertOrdered(mainRuby, [
  'require "date"',
  'require "json"',
  'require "set"',
  'require_relative "./support/native_date"',
  'require_relative "./support/native_time"',
]);

if (count(runRuby, 'require "json"') !== 1) {
  console.error("Duplicate require metadata was not deduplicated.");
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
      join(root, "examples", "require_metadata"),
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

function assertOrdered(haystack, needles) {
  let lastIndex = -1;
  for (const needle of needles) {
    const index = haystack.indexOf(needle);
    if (index === -1) {
      console.error(`Missing expected line: ${needle}`);
      process.exit(1);
    }
    if (index <= lastIndex) {
      console.error(`Require line out of order: ${needle}`);
      process.exit(1);
    }
    lastIndex = index;
  }
}

function count(haystack, needle) {
  return haystack.split(needle).length - 1;
}
