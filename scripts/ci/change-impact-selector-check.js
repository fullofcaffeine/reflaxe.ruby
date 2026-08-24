#!/usr/bin/env node

"use strict";

const { mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { loadManifest, selectForPaths } = require("./change-impact-selector.js");

const root = resolve(__dirname, "..", "..");
const packageJson = JSON.parse(readFileSync(resolve(root, "package.json"), "utf8"));
const manifest = loadManifest();
const expectedSurfaces = [
  "compiler-conformance",
  "ruby-runtime-stdlib",
  "ruby-native-gem-package",
  "upstream-provenance",
  "examples-downstream",
];

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function assertThrows(callback, message) {
  let threw = false;
  try { callback(); } catch { threw = true; }
  assert(threw, message);
}

function ids(selection) {
  return new Set(selection.selected.map((shard) => shard.id));
}

assert(manifest.schemaVersion === 1 && manifest.mode === "observe-only", "selector manifest contract changed");
assert(JSON.stringify(manifest.productSurfaces) === JSON.stringify(expectedSurfaces), "claim-bearing product surfaces drifted");
assert(new Set(manifest.shards.map((shard) => shard.id)).size === manifest.shards.length, "duplicate shard id");
const knownShardIds = new Set(manifest.shards.map((shard) => shard.id));
for (const id of [...manifest.alwaysRun, ...manifest.fullBackstop]) assert(knownShardIds.has(id), `manifest references unknown shard ${id}`);
for (const rule of manifest.rules) {
  assert(Array.isArray(rule.owners) && rule.owners.length > 0, `rule ${rule.id} lacks a semantic owner`);
  assert(Array.isArray(rule.surfaces), `rule ${rule.id} lacks product surfaces`);
  for (const surface of rule.surfaces) assert(expectedSurfaces.includes(surface), `rule ${rule.id} references unknown surface ${surface}`);
  for (const id of rule.select ?? []) assert(knownShardIds.has(id), `rule ${rule.id} references unknown shard ${id}`);
}
for (const shard of manifest.shards) {
  assert(shard.localCommand && shard.remoteOwner && shard.ring, `shard ${shard.id} lacks an executable ownership contract`);
  assert(Number.isInteger(shard.timeoutSeconds) && shard.timeoutSeconds > 0, `shard ${shard.id} lacks a positive timeout`);
  for (const script of shard.localScripts) assert(packageJson.scripts[script], `shard ${shard.id} references missing npm script ${script}`);
  for (const surface of shard.surfaces) assert(expectedSurfaces.includes(surface), `shard ${shard.id} references unknown surface ${surface}`);
}
for (const remoteOwner of [
  "Haxe formatter",
  "Node.js compatibility",
  "Ruby 3.3/3.4/4.0 full matrix",
  "RailsHx runtime integration",
  "RailsHx browser sentinel",
  "RailsHx production dogfood",
  "Release contracts",
  "Locked dependency + secret audit",
]) {
  assert(manifest.shards.some((shard) => shard.remoteOwner === remoteOwner), `hosted shard lacks local command: ${remoteOwner}`);
}

const documentation = selectForPaths(manifest, ["docs/development.md"]);
assert(!documentation.fullFallback, "ordinary documentation unexpectedly selected full");
assert(ids(documentation).has("agent-canary") && ids(documentation).has("selector-contract"), "central sentinels were omitted");
assert(ids(documentation).size === 2, "documentation selected unrelated behavior evidence");
const unavailableDiff = selectForPaths(manifest, []);
assert(unavailableDiff.fullFallback, "missing or unreadable Git diff did not fail safely to full");

const trackedImplementation = selectForPaths(manifest, [
  ".beads/issues.jsonl",
  "src/reflaxe/ruby/rails/RailsArtifactPlanner.hx",
]);
assert(!trackedImplementation.fullFallback && ids(trackedImplementation).has("rails-runtime"), "Bead bookkeeping hid the implementation owner");

const rails = selectForPaths(manifest, ["src/reflaxe/ruby/rails/RailsArtifactPlanner.hx"]);
assert(
  !rails.fullFallback && ids(rails).has("rails-runtime") && ids(rails).has("rails-generators") && ids(rails).has("examples"),
  "Rails owner mapping drifted"
);
assert(!ids(rails).has("rails-browser"), "Rails compiler change borrowed browser evidence without a browser owner");

const migrationInventory = selectForPaths(manifest, ["lib/hxruby/generators/migration_inventory.rb"]);
assert(
  !migrationInventory.fullFallback && ids(migrationInventory).has("rails-generators") &&
    !ids(migrationInventory).has("examples") && !ids(migrationInventory).has("rails-runtime"),
  "migration inventory borrowed evidence from another product surface"
);

const browser = selectForPaths(manifest, ["examples/todoapp_rails/src/client/Main.hx"]);
assert(ids(browser).has("rails-browser") && ids(browser).has("rails-runtime"), "browser vertical owner mapping drifted");

for (const path of [
  "src/reflaxe/ruby/compiler/RubyCompiler.hx",
  "runtime/hxruby/Runtime.rb",
  "std/ruby/_std/Date.hx",
  "package-lock.json",
  ".github/workflows/ci.yml",
  "test/change-impact-ownership.json",
  "unowned/new-surface.txt",
]) {
  const selection = selectForPaths(manifest, [path]);
  assert(selection.fullFallback, `${path} did not fail safely to full`);
  for (const id of manifest.fullBackstop) assert(ids(selection).has(id), `${path} omitted full backstop ${id}`);
}

const miss = selectForPaths(manifest, ["docs/development.md"], ["rails-browser"]);
assert(miss.selectorMisses.length === 1 && miss.selectorMisses[0].id === "rails-browser", "omitted failure was not reported as a selector miss");
const selectedFailure = selectForPaths(manifest, ["examples/todoapp_rails/src/client/Main.hx"], ["rails-browser"]);
assert(selectedFailure.selectorMisses.length === 0, "selected failure was incorrectly reported as a miss");
assertThrows(() => selectForPaths(manifest, ["docs/development.md"], ["not-a-shard"]), "unknown observed shard did not fail closed");

const temporaryRoot = mkdtempSync(join(tmpdir(), "rubyhx-change-impact."));
try {
  const reportPath = join(temporaryRoot, "report.json");
  const cli = spawnSync(process.execPath, [
    resolve(root, "scripts", "ci", "change-impact-selector.js"),
    "--path",
    "docs/development.md",
    "--observed-failure",
    "rails-browser",
    "--report",
    reportPath,
  ], { cwd: root, encoding: "utf8" });
  assert(cli.status === 0, `explain CLI failed: ${cli.stderr}`);
  assert(cli.stdout.includes("PATH docs/development.md: focused (documentation-only; owners=documentation-and-issue-tracking; surfaces=none)"), "explain CLI omitted the semantic-owner decision");
  assert(cli.stdout.includes("MISS rails-browser"), "explain CLI omitted the selector miss");
  const report = JSON.parse(readFileSync(reportPath, "utf8"));
  assert(report.mode === "observe-only" && report.selectorMisses.length === 1, "explain report contract drifted");
  assert(Number.isInteger(report.durationMs) && report.durationMs >= 0, "explain report omitted timing");
} finally {
  rmSync(temporaryRoot, { recursive: true, force: true });
}

console.log("[change-impact-selector-check] OK: ownership, fallback, explain, and miss contracts are intact");
