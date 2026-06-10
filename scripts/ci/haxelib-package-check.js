#!/usr/bin/env node

const { mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");

const root = resolve(__dirname, "..", "..");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const archiveName = `reflaxe.ruby-${packageJson.version}.zip`;
const archivePath = join(root, "dist", archiveName);

function fail(message) {
  console.error(`[haxelib-package] ERROR: ${message}`);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
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

run("node", ["scripts/release/build-haxelib-package.js"]);

const entries = run("unzip", ["-Z1", archivePath]).stdout.trim().split("\n").filter(Boolean);
const entrySet = new Set(entries);

for (const required of [
  "haxelib.json",
  "extraParams.hxml",
  "src/reflaxe/ruby/RubyCompiler.hx",
  "src/reflaxe/ruby/CompilerBootstrap.hx",
  "std/Std.cross.hx",
  "std/rails/ActiveRecord.hx",
  "runtime/hxruby/core.rb",
  "vendor/reflaxe/src/reflaxe/ReflectCompiler.hx",
]) {
  if (!entrySet.has(required)) {
    fail(`archive missing required entry: ${required}`);
  }
}

for (const forbiddenPrefix of [".git/", ".beads/", ".github/", "node_modules/", "test/", "scripts/"]) {
  const match = entries.find((entry) => entry === forbiddenPrefix.slice(0, -1) || entry.startsWith(forbiddenPrefix));
  if (match) {
    fail(`archive contains forbidden entry: ${match}`);
  }
}

const tempRoot = mkdtempSync(join(tmpdir(), "reflaxe-ruby-package."));
try {
  run("unzip", ["-q", archivePath, "-d", tempRoot]);
  const outputDir = join(tempRoot, "out");
  run("haxe", [
    "-D",
    `ruby_output=${outputDir}`,
    "-D",
    "reflaxe_runtime",
    "-cp",
    join(tempRoot, "src"),
    "-cp",
    join(tempRoot, "examples", "hello_world"),
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  ]);
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log(`[haxelib-package] OK: ${archiveName} (${entries.length} files)`);
