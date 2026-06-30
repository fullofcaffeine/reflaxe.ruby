#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "rails_autoload");
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
  console.error("Unable to compile rails_autoload through Reflaxe.");
  process.exit(1);
}

for (const file of [
  "app/lib/railshx/generated/admin/todo_item.rb",
  "app/lib/railshx/generated/main.rb",
  "app/lib/railshx/runtime/hxruby/core.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected Rails output file missing: ${fullPath}`);
    process.exit(1);
  }
}

for (const legacyFile of [
  "app/haxe_gen/admin/todo_item.rb",
  "app/haxe_gen/hxruby/core.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
]) {
  const fullPath = join(outputDir, legacyFile);
  if (existsSync(fullPath)) {
    console.error(`Rails autoload smoke should not emit legacy haxe_gen/autoload file: ${fullPath}`);
    process.exit(1);
  }
}

const todoRuby = readFileSync(join(outputDir, "app", "lib", "railshx", "generated", "admin", "todo_item.rb"), "utf8");
for (const expected of ["module Admin", "class TodoItem", "attr_accessor :title"]) {
	if (!todoRuby.includes(expected)) {
		console.error(`Rails autoload file is missing expected constant shape: ${expected}`);
    process.exit(1);
	}
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
assertOrdered(runRuby, [
  'require_relative "app/lib/railshx/runtime/hxruby/core"',
  'require_relative "app/lib/railshx/generated/admin/todo_item"',
  'require_relative "app/lib/railshx/generated/main"',
]);

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = readFileSync(join(root, "test", "fixtures", "rails_autoload", "expected.stdout"), "utf8");

if (actual !== expected) {
  console.error("rails_autoload stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
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
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      join(root, "examples", "rails_autoload"),
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
      console.error(`Line out of order: ${needle}`);
      process.exit(1);
    }
    lastIndex = index;
  }
}
