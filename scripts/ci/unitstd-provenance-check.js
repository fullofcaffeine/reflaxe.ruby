#!/usr/bin/env node

"use strict";

const {
  copyFileSync,
  existsSync,
  mkdtempSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} = require("node:fs");
const { createHash } = require("node:crypto");
const { tmpdir } = require("node:os");
const { dirname, join, relative, resolve, sep } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const manifestPath = process.env.HAXE_RUBY_UNITSTD_MANIFEST
  ? resolve(process.env.HAXE_RUBY_UNITSTD_MANIFEST)
  : join(root, "test", "upstream_unitstd", "manifest.json");
const assertionInventoryPath = join(root, "test", "upstream_unitstd", "active-assertions.json");
const adaptationRoot = join(root, "test", "upstream_unitstd", "adaptations");
const generatedRubyPath = join(root, "test", ".generated", "unitstd_ruby", "main.rb");
const expectedBaseline = Object.freeze({
  repository: "https://github.com/HaxeFoundation/haxe",
  version: "4.3.7",
  commit: "e0b355c6be312c1b17382603f018cf52522ec651",
  unitstdRoot: "tests/unit/src/unitstd",
  inventorySha256: "4173f1707f72013d660d5b02f251ae586e7a44f67fb88186f7d5110934b2e537",
  license: Object.freeze({
    path: "extra/LICENSE.txt",
    standardLibrarySpdx: "MIT",
    sha256: "f84691d619932ebfd4fa3568f8311f87ed4bf12e747e9aaa619a92cb1d2d359d",
  }),
  harness: Object.freeze({
    upstreamDependency: "utest",
    pinnedRevision: null,
    localUse: "not-used",
    note: "Haxe 4.3.7 requests utest without pinning a revision; this Ruby lane parses the expression fixtures with its checked-in macro instead.",
  }),
});

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function writeJson(path, value) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`);
}

function slash(path) {
  return path.split(sep).join("/");
}

function walkUnitSpecs(directory, base = directory) {
  const paths = [];
  for (const entry of readdirSync(directory).sort()) {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) paths.push(...walkUnitSpecs(path, base));
    else if (entry.endsWith(".unit.hx")) paths.push(slash(relative(base, path)));
  }
  return paths;
}

function defaultHaxeRoot() {
  if (process.env.HAXE_RUBY_HAXE_REFERENCE) return resolve(process.env.HAXE_RUBY_HAXE_REFERENCE);
  // Normal tests are hermetic over the committed inventory. Only an explicit
  // review/update command may depend on a mutable neighboring Haxe checkout.
  return null;
}

function referenceRootFromArgs() {
  const index = process.argv.indexOf("--reference");
  return index === -1 ? defaultHaxeRoot() : resolve(process.argv[index + 1]);
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function command(commandName, args, cwd) {
  const result = spawnSync(commandName, args, { cwd, encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(`${commandName} ${args.join(" ")} failed: ${result.stderr.trim() || result.stdout.trim()}`);
  }
  return result.stdout.trim();
}

function verifyReferenceRoot(haxeRoot) {
  assert(haxeRoot && existsSync(haxeRoot), "an exact Haxe source checkout is required for this operation");
  const commit = command("git", ["rev-parse", "HEAD"], haxeRoot);
  assert(commit === expectedBaseline.commit, `Haxe reference must be ${expectedBaseline.commit}, got ${commit}`);
  const tag = command("git", ["describe", "--tags", "--exact-match", "HEAD"], haxeRoot);
  assert(tag === expectedBaseline.version, `Haxe reference tag must be ${expectedBaseline.version}, got ${tag}`);
  const licenseBytes = readFileSync(join(haxeRoot, expectedBaseline.license.path));
  assert(sha256(licenseBytes) === expectedBaseline.license.sha256, "pinned Haxe license bytes changed");
  return join(haxeRoot, expectedBaseline.unitstdRoot);
}

function normalizedDiff(source, local, sourcePath) {
  const result = spawnSync("git", ["diff", "--no-index", "--no-renames", "--unified=3", "--", source, local], {
    cwd: root,
    encoding: "utf8",
  });
  assert(result.status === 0 || result.status === 1, `unable to generate adaptation diff for ${sourcePath}`);
  if (result.status === 0) return "";
  const lines = result.stdout.split("\n");
  const hunk = lines.findIndex((line) => line.startsWith("@@ "));
  assert(hunk !== -1, `adaptation diff for ${sourcePath} has no hunk`);
  return `--- a/${sourcePath}\n+++ b/${sourcePath}\n${lines.slice(hunk).join("\n")}`;
}

function withFormatterNormalizedSources(unitstdRoot, sources, useNormalizedRoot) {
  const temporaryRoot = mkdtempSync(join(tmpdir(), "rubyhx-unitstd-normalized."));
  try {
    for (const source of sources) {
      const target = join(temporaryRoot, source);
      mkdirSync(dirname(target), { recursive: true });
      copyFileSync(join(unitstdRoot, source), target);
    }
    const result = spawnSync("haxelib", ["run", "formatter", "-s", temporaryRoot], {
      cwd: root,
      encoding: "utf8",
    });
    assert(result.status === 0,
      `Haxe formatter is required to reproduce formatter-normalized provenance: ${result.stderr.trim() || result.stdout.trim()}`);
    return useNormalizedRoot(temporaryRoot);
  } finally {
    rmSync(temporaryRoot, { force: true, recursive: true });
  }
}

function inactiveReason(source) {
  if (source.includes("/atomic/")) return "Inactive: Ruby atomic/thread semantics are not registered in this bounded lane.";
  if (/haxe\/io\/(ArrayBufferView|Float32Array|Float64Array|Int32Array|UInt16Array|UInt32Array|UInt8Array)/.test(source)) {
    return "Inactive: typed-array representation is not registered in this bounded lane.";
  }
  if (/Unicode|Utf8|StringIteratorUnicode/.test(source)) {
    return "Inactive: this lane compiles with no-utf16 and has not registered the separate Unicode capability contract.";
  }
  if (source === "haxe/CallStack.unit.hx") return "Inactive: portable Ruby backtrace mapping is not registered in this bounded lane.";
  if (source === "haxe/ds/WeakMap.unit.hx") return "Inactive: weak-reference and garbage-collection semantics are not registered in this bounded lane.";
  if (source === "Ssl.unit.hx" || source === "sys/net/Socket.unit.hx") {
    return "Inactive: network/TLS behavior requires a separately isolated capability lane and is not registered here.";
  }
  return "Inactive: this official fixture is not registered in the current bounded Ruby lane; applicability remains unclaimed pending focused review.";
}

function extractActiveAssertions(mainRuby) {
  const bySource = new Map();
  const pattern = /upstream unitstd ([^ ]+) at [^"\\]+:(\d+)/g;
  for (const match of mainRuby.matchAll(pattern)) {
    const source = match[1];
    const identity = `${source}@${match[2]}`;
    if (!bySource.has(source)) bySource.set(source, new Set());
    bySource.get(source).add(identity);
  }
  return [...bySource.entries()]
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([source, identities]) => {
      const sorted = [...identities].sort((left, right) => Number(left.split("@").at(-1)) - Number(right.split("@").at(-1)));
      return { source, count: sorted.length, sha256: sha256(`${sorted.join("\n")}\n`), identities: sorted };
    });
}

function assertionSummary(inventory) {
  return new Map(inventory.fixtures.map((entry) => [entry.source, { count: entry.count, sha256: entry.sha256 }]));
}

function createActiveInventory(mainRuby) {
  const fixtures = extractActiveAssertions(mainRuby);
  return {
    schemaVersion: 1,
    origin: "Unique assertion messages emitted by UpstreamUnitStdMacro into generated Ruby; identities prove registration and post-macro survival, not semantic correctness by themselves.",
    total: fixtures.reduce((sum, entry) => sum + entry.count, 0),
    fixtures,
  };
}

function verifyActiveAssertions(mainRuby) {
  const expected = readJson(assertionInventoryPath);
  const actual = createActiveInventory(mainRuby);
  assert(JSON.stringify(actual.fixtures) === JSON.stringify(expected.fixtures),
    "active upstream assertion identities changed; review fixture registration/adaptation and refresh provenance explicitly");
  assert(actual.total === expected.total, "active upstream assertion total changed unexpectedly");
}

function verifyManifest(options = {}) {
  const manifest = readJson(manifestPath);
  assert(manifest.schemaVersion === 2, `unitstd provenance schema must be 2, got ${manifest.schemaVersion}`);
  assert(JSON.stringify(manifest.baseline) === JSON.stringify(expectedBaseline), "unitstd baseline identity does not match the reviewed Haxe 4.3.7 contract");
  assert(existsSync(assertionInventoryPath), "active upstream assertion inventory is missing");
  const activeInventory = readJson(assertionInventoryPath);
  const activeBySource = assertionSummary(activeInventory);
  const trackedSources = new Set();

  for (const entry of manifest.modules) {
    if (entry.status !== "enabled" && entry.status !== "adapted") continue;
    trackedSources.add(entry.source);
    const fixturePath = join(root, entry.fixture);
    assert(existsSync(fixturePath), `checked-in fixture is missing: ${entry.fixture}`);
    assert(sha256(readFileSync(fixturePath)) === entry.provenance.localSha256, `checked-in fixture hash drifted: ${entry.source}`);
    assert(["unmodified", "adapted"].includes(entry.provenance.classification), `invalid provenance classification: ${entry.source}`);
    assert(entry.provenance.upstreamSha256?.length === 64, `upstream hash missing: ${entry.source}`);
    const active = activeBySource.get(entry.source);
    assert(active, `active assertion inventory is missing ${entry.source}`);
    assert(JSON.stringify(active) === JSON.stringify(entry.activeAssertions), `active assertion summary drifted: ${entry.source}`);
    if (entry.provenance.classification === "adapted") {
      assert(entry.provenance.reason?.trim(), `adaptation reason missing: ${entry.source}`);
      assert(entry.provenance.owner?.trim(), `adaptation owner missing: ${entry.source}`);
      if (entry.provenance.transformation === "ruby-lane-adaptation") {
        assert(entry.provenance.diff?.path, `Ruby-lane adaptation diff missing: ${entry.source}`);
        const diffPath = join(root, entry.provenance.diff.path);
        assert(existsSync(diffPath), `adaptation diff file missing: ${entry.provenance.diff.path}`);
        assert(sha256(readFileSync(diffPath)) === entry.provenance.diff.sha256, `adaptation diff hash drifted: ${entry.source}`);
      } else {
        assert(entry.provenance.transformation === "formatter-normalized", `unknown adaptation transformation: ${entry.source}`);
        assert(!entry.provenance.diff, `formatter-only adaptation should be represented by exact hashes, not a hand-maintained patch: ${entry.source}`);
      }
    }
  }

  const inventorySources = manifest.upstreamInventory.map((entry) => entry.source);
  const inventoryIdentity = `${manifest.upstreamInventory.map((entry) => `${entry.source}\t${entry.upstreamSha256}`).join("\n")}\n`;
  assert(sha256(inventoryIdentity) === manifest.baseline.inventorySha256, "pinned upstream inventory identity drifted");
  assert(new Set(inventorySources).size === inventorySources.length, "upstream inventory contains duplicate sources");
  for (const entry of manifest.upstreamInventory) {
    assert(entry.upstreamSha256?.length === 64, `inventory hash missing: ${entry.source}`);
    if (trackedSources.has(entry.source)) assert(entry.evidenceStatus === "active", `tracked fixture is not active in inventory: ${entry.source}`);
    else assert(entry.evidenceStatus === "inactive" || entry.evidenceStatus === "unsupported", `untracked official fixture needs an explicit nonpassing status: ${entry.source}`);
    if (entry.evidenceStatus !== "active") assert(entry.reason?.trim(), `non-active official fixture needs a reason: ${entry.source}`);
  }

  const haxeRoot = options.haxeRoot ?? defaultHaxeRoot();
  if (haxeRoot) {
    const unitstdRoot = verifyReferenceRoot(haxeRoot);
    const referenceSources = walkUnitSpecs(unitstdRoot);
    assert(JSON.stringify(referenceSources) === JSON.stringify(inventorySources), "pinned upstream inventory changed; new/missing files require explicit classification");
    for (const entry of manifest.upstreamInventory) {
      const sourcePath = join(unitstdRoot, entry.source);
      assert(sha256(readFileSync(sourcePath)) === entry.upstreamSha256, `pinned upstream source hash drifted: ${entry.source}`);
    }
    withFormatterNormalizedSources(unitstdRoot, [...trackedSources], (normalizedRoot) => {
      for (const entry of manifest.modules) {
        if (entry.status !== "enabled" && entry.status !== "adapted") continue;
        const upstreamPath = join(unitstdRoot, entry.source);
        const normalizedPath = join(normalizedRoot, entry.source);
        const fixturePath = join(root, entry.fixture);
        if (entry.provenance.classification === "unmodified") {
          assert(readFileSync(upstreamPath).equals(readFileSync(fixturePath)), `unmodified fixture diverged: ${entry.source}`);
        } else if (entry.provenance.diff) {
          assert(sha256(readFileSync(normalizedPath)) === entry.provenance.normalizedUpstreamSha256,
            `formatter-normalized upstream hash drifted: ${entry.source}`);
          const expectedDiff = normalizedDiff(normalizedPath, fixturePath, entry.source);
          assert(expectedDiff === readFileSync(join(root, entry.provenance.diff.path), "utf8"), `adaptation diff is stale: ${entry.source}`);
        } else {
          assert(readFileSync(normalizedPath).equals(readFileSync(fixturePath)),
            `formatter-normalized fixture is not reproducible: ${entry.source}`);
        }
      }
    });
  }
  return manifest;
}

function writeProvenance(haxeRoot) {
  const unitstdRoot = verifyReferenceRoot(haxeRoot);
  const manifest = readJson(manifestPath);
  assert(existsSync(generatedRubyPath), `run npm run test:unitstd-ruby before refreshing active assertions: ${generatedRubyPath}`);
  const activeInventory = createActiveInventory(readFileSync(generatedRubyPath, "utf8"));
  const activeBySource = assertionSummary(activeInventory);
  const tracked = new Map(manifest.modules
    .filter((entry) => entry.status === "enabled" || entry.status === "adapted")
    .map((entry) => [entry.source, entry]));

  mkdirSync(adaptationRoot, { recursive: true });
  withFormatterNormalizedSources(unitstdRoot, [...tracked.keys()], (normalizedRoot) => {
    for (const entry of tracked.values()) {
      const upstreamPath = join(unitstdRoot, entry.source);
      const normalizedPath = join(normalizedRoot, entry.source);
      const fixturePath = join(root, entry.fixture);
      const upstreamBytes = readFileSync(upstreamPath);
      const normalizedBytes = readFileSync(normalizedPath);
      const localBytes = readFileSync(fixturePath);
      const isUnmodified = upstreamBytes.equals(localBytes);
      const provenance = {
        classification: isUnmodified ? "unmodified" : "adapted",
        upstreamSha256: sha256(upstreamBytes),
        localSha256: sha256(localBytes),
      };
      if (!isUnmodified) {
        const formattingOnly = entry.status === "enabled";
        provenance.transformation = formattingOnly ? "formatter-normalized" : "ruby-lane-adaptation";
        provenance.reason = formattingOnly
          ? "The checked-in fixture is formatter-normalized for this repository; reviewable expressions and assertions derive from the pinned upstream bytes."
          : entry.reason;
        provenance.owner = formattingOnly ? "scripts/ci/unitstd-provenance-check.js --write" : "haxe_ruby-xm15";
        if (formattingOnly) {
          assert(normalizedBytes.equals(localBytes), `enabled fixture contains more than formatter normalization: ${entry.source}`);
        } else {
          const diffRelative = `test/upstream_unitstd/adaptations/${entry.source.replaceAll("/", "__")}.patch`;
          const diff = normalizedDiff(normalizedPath, fixturePath, entry.source);
          writeFileSync(join(root, diffRelative), diff);
          provenance.normalizedUpstreamSha256 = sha256(normalizedBytes);
          provenance.diff = { path: diffRelative, sha256: sha256(diff) };
        }
      }
      entry.provenance = provenance;
      entry.activeAssertions = activeBySource.get(entry.source);
      assert(entry.activeAssertions, `generated Ruby did not retain assertions for ${entry.source}`);
    }
  });

  manifest.schemaVersion = 2;
  manifest.baseline = expectedBaseline;
  manifest.upstreamInventory = walkUnitSpecs(unitstdRoot).map((source) => {
    const entry = tracked.get(source);
    return {
      source,
      upstreamSha256: sha256(readFileSync(join(unitstdRoot, source))),
      evidenceStatus: entry ? "active" : "inactive",
      ...(entry ? {} : { reason: inactiveReason(source) }),
    };
  });
  writeJson(assertionInventoryPath, activeInventory);
  writeJson(manifestPath, manifest);
}

function writeReviewReport(haxeRoot) {
  const reportPath = join(root, "test", ".generated", "upstream-unitstd-review.json");
  const startedAt = new Date().toISOString();
  try {
    const manifest = verifyManifest({ haxeRoot });
    writeJson(reportPath, {
      schemaVersion: 1,
      outcome: "pass",
      startedAt,
      baseline: manifest.baseline,
      activeFixtures: manifest.upstreamInventory.filter((entry) => entry.evidenceStatus === "active").length,
      inactiveFixtures: manifest.upstreamInventory.filter((entry) => entry.evidenceStatus !== "active").length,
      note: "Review-only: no checked-in fixture or provenance file was modified.",
    });
    console.log(`[unitstd-provenance] review report: ${reportPath}`);
  } catch (error) {
    writeJson(reportPath, { schemaVersion: 1, outcome: "fail", startedAt, error: error.message });
    console.error(`[unitstd-provenance] review report: ${reportPath}`);
    throw error;
  }
}

function main() {
  const haxeRoot = referenceRootFromArgs();
  if (process.argv.includes("--write")) writeProvenance(haxeRoot);
  else if (process.argv.includes("--review")) writeReviewReport(haxeRoot);
  else verifyManifest({ haxeRoot });
  console.log("[unitstd-provenance] OK");
}

if (require.main === module) main();

module.exports = {
  createActiveInventory,
  verifyActiveAssertions,
  verifyManifest,
};
