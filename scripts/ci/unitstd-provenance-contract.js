#!/usr/bin/env node

"use strict";

const { mkdtempSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const checker = join(root, "scripts", "ci", "unitstd-provenance-check.js");
const sourceManifest = JSON.parse(readFileSync(join(root, "test", "upstream_unitstd", "manifest.json"), "utf8"));
const temporaryRoot = mkdtempSync(join(tmpdir(), "rubyhx-unitstd-provenance."));

function expectFailure(id, mutate, expectedMessage) {
  const manifest = structuredClone(sourceManifest);
  mutate(manifest);
  const path = join(temporaryRoot, `${id}.json`);
  writeFileSync(path, `${JSON.stringify(manifest, null, 2)}\n`);
  const result = spawnSync(process.execPath, [checker], {
    cwd: root,
    encoding: "utf8",
    env: { ...process.env, HAXE_RUBY_UNITSTD_MANIFEST: path },
  });
  const output = `${result.stdout}\n${result.stderr}`;
  if (result.status === 0 || !output.includes(expectedMessage)) {
    throw new Error(`${id} did not fail for ${JSON.stringify(expectedMessage)}: ${output}`);
  }
}

try {
  expectFailure("baseline", (manifest) => delete manifest.baseline.commit,
    "unitstd baseline identity does not match the reviewed Haxe 4.3.7 contract");
  expectFailure("fixture-hash", (manifest) => { manifest.modules[0].provenance.localSha256 = "0".repeat(64); },
    "checked-in fixture hash drifted");
  expectFailure("active-identity", (manifest) => { manifest.modules[0].activeAssertions.count += 1; },
    "active assertion summary drifted");
  expectFailure("adaptation-patch", (manifest) => {
    const adapted = manifest.modules.find((entry) => entry.provenance?.diff);
    adapted.provenance.diff.sha256 = "0".repeat(64);
  }, "adaptation diff hash drifted");
  expectFailure("inventory", (manifest) => { manifest.upstreamInventory.pop(); },
    "pinned upstream inventory identity drifted");
  console.log("[unitstd-provenance-contract] OK: baseline, local bytes, active identities, patches, and inventory fail closed");
} finally {
  rmSync(temporaryRoot, { force: true, recursive: true });
}
