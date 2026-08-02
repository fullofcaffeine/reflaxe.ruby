#!/usr/bin/env node

"use strict";

const { mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { correlateOutcomes, jobShardMap } = require("./change-impact-observation.js");
const { loadManifest } = require("./change-impact-selector.js");

const root = resolve(__dirname, "..", "..");
const successfulNeeds = Object.fromEntries(Object.keys(jobShardMap).map((jobId) => [jobId, { result: "success" }]));

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function assertThrows(callback, message) {
  let threw = false;
  try { callback(); } catch { threw = true; }
  assert(threw, message);
}

const manifest = loadManifest();
assert(
  JSON.stringify([...new Set(Object.values(jobShardMap))].sort()) === JSON.stringify([...manifest.fullBackstop].sort()),
  "hosted observation map must cover every canonical backstop exactly once",
);

const allGreen = correlateOutcomes(successfulNeeds);
assert(allGreen.allBackstopsSucceeded, "all-success needs did not produce a green observation");
assert(allGreen.observedFailures.length === 0 && allGreen.incompleteBackstops.length === 0, "green needs invented failures or incompleteness");

const failedBrowser = correlateOutcomes({ ...successfulNeeds, "rails-browser": { result: "failure" } });
assert(!failedBrowser.allBackstopsSucceeded, "failed backstop was reported green");
assert(JSON.stringify(failedBrowser.observedFailures) === JSON.stringify(["rails-browser"]), "failed job did not map to its selector shard");

const cancelledRuntime = correlateOutcomes({ ...successfulNeeds, "rails-runtime": { result: "cancelled" } });
assert(cancelledRuntime.observedFailures.length === 0, "cancelled backstop was misreported as a behavioral failure");
assert(cancelledRuntime.incompleteBackstops[0]?.shardId === "rails-runtime", "cancelled backstop was not retained as incomplete evidence");

assertThrows(() => correlateOutcomes({ ...successfulNeeds, security: undefined }), "missing hosted result did not fail closed");
assertThrows(() => correlateOutcomes({ ...successfulNeeds, security: { result: "unknown" } }), "unknown hosted result did not fail closed");
assertThrows(() => correlateOutcomes([]), "non-object hosted results did not fail closed");

const temporaryRoot = mkdtempSync(join(tmpdir(), "rubyhx-change-impact-observation."));
try {
  const reportPath = join(temporaryRoot, "observation.json");
  const cli = spawnSync(process.execPath, [
    resolve(root, "scripts", "ci", "change-impact-observation.js"),
    "--path",
    "docs/development.md",
    "--base",
    "a".repeat(40),
    "--head",
    "b".repeat(40),
    "--report",
    reportPath,
  ], {
    cwd: root,
    encoding: "utf8",
    env: {
      ...process.env,
      CI_NEEDS_JSON: JSON.stringify({ ...successfulNeeds, "rails-browser": { result: "failure" } }),
      GITHUB_RUN_ID: "12345",
      GITHUB_RUN_ATTEMPT: "2",
      GITHUB_EVENT_NAME: "pull_request",
      GITHUB_REPOSITORY: "fullofcaffeine/reflaxe.ruby",
      GITHUB_REF: "refs/pull/1/merge",
    },
  });
  assert(cli.status === 0, `observation CLI failed: ${cli.stderr}`);
  const report = JSON.parse(readFileSync(reportPath, "utf8"));
  assert(report.mode === "observe-only" && report.run.id === "12345", "observation report lost mode or run identity");
  assert(report.observedFailures[0] === "rails-browser", "observation report lost the hosted failure");
  assert(report.selectorMisses[0]?.id === "rails-browser", "omitted hosted failure was not correlated as a miss");
  assert(report.authority.includes("neither schedules nor suppresses"), "observation report overstated its authority");

  const selectedCli = spawnSync(process.execPath, [
    resolve(root, "scripts", "ci", "change-impact-observation.js"),
    "--path",
    "examples/todoapp_rails/src/client/Main.hx",
    "--report",
    join(temporaryRoot, "selected.json"),
  ], {
    cwd: root,
    encoding: "utf8",
    env: { ...process.env, CI_NEEDS_JSON: JSON.stringify({ ...successfulNeeds, "rails-browser": { result: "failure" } }) },
  });
  assert(selectedCli.status === 0, `selected observation CLI failed: ${selectedCli.stderr}`);
  const selectedReport = JSON.parse(readFileSync(join(temporaryRoot, "selected.json"), "utf8"));
  assert(selectedReport.selectorMisses.length === 0, "selected hosted failure was incorrectly counted as a miss");

  const malformed = spawnSync(process.execPath, [resolve(root, "scripts", "ci", "change-impact-observation.js"), "--path", "docs/development.md"], {
    cwd: root,
    encoding: "utf8",
    env: { ...process.env, CI_NEEDS_JSON: "not-json" },
  });
  assert(malformed.status !== 0 && malformed.stderr.includes("CI_NEEDS_JSON"), "malformed hosted context did not fail closed");
} finally {
  rmSync(temporaryRoot, { recursive: true, force: true });
}

console.log("[change-impact-observation-check] OK: hosted outcomes, misses, incompleteness, and authority are intact");
