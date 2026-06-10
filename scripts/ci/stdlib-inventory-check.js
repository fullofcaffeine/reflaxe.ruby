#!/usr/bin/env node

const { existsSync, readdirSync, readFileSync } = require("node:fs");
const { join, relative, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const inventoryPath = join(root, "docs", "stdlib-inventory.json");
const inventory = JSON.parse(readFileSync(inventoryPath, "utf8"));
const allowedOwners = new Set(["std", "std/_std", "runtime/hxruby"]);
const allowedStatuses = new Set(["planned", "missing", "implemented", "deferred"]);

failIf(inventory.schemaVersion !== 1, "schemaVersion must be 1");
failIf(!Array.isArray(inventory.entries), "entries must be an array");

const ids = new Set();
const paths = new Set();
for (const entry of inventory.entries) {
  failIf(!entry.id || typeof entry.id !== "string", "entry id is required");
  failIf(ids.has(entry.id), `duplicate entry id: ${entry.id}`);
  ids.add(entry.id);

  failIf(!allowedOwners.has(entry.owner), `invalid owner for ${entry.id}: ${entry.owner}`);
  failIf(!allowedStatuses.has(entry.status), `invalid status for ${entry.id}: ${entry.status}`);
  failIf(!entry.path || typeof entry.path !== "string", `entry path is required: ${entry.id}`);
  failIf(paths.has(entry.path), `duplicate inventory path: ${entry.path}`);
  paths.add(entry.path);
  failIf(!entry.surface || !entry.reason, `surface and reason are required: ${entry.id}`);

  const pathOwner = ownerForPath(entry.path);
  failIf(pathOwner !== entry.owner, `owner/path mismatch for ${entry.id}: owner=${entry.owner}, path=${entry.path}`);
  if (entry.status === "implemented") {
    failIf(!existsSync(join(root, entry.path)), `implemented file missing: ${entry.path}`);
  }
}

for (const file of committedStdRuntimeFiles()) {
  failIf(!paths.has(file), `committed std/runtime file missing inventory entry: ${file}`);
}

function ownerForPath(path) {
  if (path.startsWith("std/_std/")) return "std/_std";
  if (path.startsWith("std/")) return "std";
  if (path.startsWith("runtime/hxruby/")) return "runtime/hxruby";
  return "";
}

function committedStdRuntimeFiles() {
  const roots = ["std", "runtime/hxruby"];
  const out = [];
  for (const dir of roots) {
    walk(join(root, dir), out);
  }
  return out
    .map((path) => relative(root, path).split("\\").join("/"))
    .filter((path) => !path.endsWith("README.md"));
}

function walk(dir, out) {
  if (!existsSync(dir)) return;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(path, out);
    } else {
      out.push(path);
    }
  }
}

function failIf(condition, message) {
  if (condition) {
    console.error(`[stdlib-inventory] ${message}`);
    process.exit(1);
  }
}
