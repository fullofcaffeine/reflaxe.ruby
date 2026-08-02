#!/usr/bin/env node

"use strict";

const { mkdirSync, writeFileSync } = require("node:fs");
const { dirname, resolve } = require("node:path");
const { gitChangedPaths, loadManifest, normalizeChangedPath, selectForPaths } = require("./change-impact-selector.js");

const root = resolve(__dirname, "..", "..");
const defaultReportPath = resolve(root, "test", ".generated", "change-impact", "observation.json");

// GitHub exposes one result for each declared `needs` job. Keep this mapping
// explicit: a renamed or omitted hosted gate must fail the observer instead of
// silently disappearing from the selector's evidence history.
const jobShardMap = Object.freeze({
  security: "security",
  "haxe-format": "format",
  "node-compatibility": "node-compatibility",
  test: "full-suite",
  "rails-browser": "rails-browser",
  "rails-runtime": "rails-runtime",
  "rails-production": "rails-production",
  "release-contracts": "release-contracts",
});
const validResults = new Set(["success", "failure", "cancelled", "skipped"]);

/**
 * Convert scheduler-level job conclusions into selector shard observations.
 * Only an actual `failure` is a selector miss candidate. Cancellation and
 * skipping mean the backstop was incomplete, so they remain visible without
 * being misreported as a behavioral failure.
 */
function correlateOutcomes(needs) {
  if (!needs || typeof needs !== "object" || Array.isArray(needs)) throw new Error("CI needs input must be an object");

  const jobOutcomes = Object.entries(jobShardMap).map(([jobId, shardId]) => {
    const result = needs[jobId]?.result;
    if (!validResults.has(result)) throw new Error(`CI needs input lacks a valid result for ${jobId}`);
    return { jobId, shardId, result };
  });
  return {
    jobOutcomes,
    observedFailures: jobOutcomes.filter((outcome) => outcome.result === "failure").map((outcome) => outcome.shardId),
    incompleteBackstops: jobOutcomes.filter((outcome) => outcome.result === "cancelled" || outcome.result === "skipped"),
    allBackstopsSucceeded: jobOutcomes.every((outcome) => outcome.result === "success"),
  };
}

function parseArgs(argv) {
  const options = { paths: [] };
  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    const next = () => {
      index += 1;
      if (index >= argv.length) throw new Error(`${value} requires a value`);
      return argv[index];
    };
    if (value === "--path") options.paths.push(normalizeChangedPath(next()));
    else if (value === "--base") options.base = next();
    else if (value === "--head") options.head = next();
    else if (value === "--report") options.report = resolve(next());
    else throw new Error(`unknown argument ${value}`);
  }
  return options;
}

function main() {
  const started = process.hrtime.bigint();
  const options = parseArgs(process.argv.slice(2));
  let needs;
  try {
    needs = JSON.parse(process.env.CI_NEEDS_JSON ?? "");
  } catch {
    throw new Error("CI_NEEDS_JSON must contain the GitHub needs context as JSON");
  }

  const manifest = loadManifest();
  const changedPaths = [...new Set(options.paths.length > 0 ? options.paths : gitChangedPaths(options.base, options.head))];
  const outcomes = correlateOutcomes(needs);
  const selection = selectForPaths(manifest, changedPaths, outcomes.observedFailures);
  const report = {
    schemaVersion: 1,
    mode: manifest.mode,
    authority: "observation only; this report neither schedules nor suppresses CI jobs",
    run: {
      id: process.env.GITHUB_RUN_ID ?? null,
      attempt: process.env.GITHUB_RUN_ATTEMPT ?? null,
      event: process.env.GITHUB_EVENT_NAME ?? null,
      repository: process.env.GITHUB_REPOSITORY ?? null,
      ref: process.env.GITHUB_REF ?? null,
    },
    base: options.base ?? null,
    head: options.head ?? null,
    changedPaths,
    fallbackReason: selection.fullFallback ? manifest.fullFallbackReason : null,
    ...selection,
    ...outcomes,
    durationMs: Number((process.hrtime.bigint() - started) / 1_000_000n),
  };

  const reportPath = options.report ?? defaultReportPath;
  mkdirSync(dirname(reportPath), { recursive: true });
  writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(`[change-impact-observation] allBackstopsSucceeded=${report.allBackstopsSucceeded} failures=${report.observedFailures.length} misses=${report.selectorMisses.length} incomplete=${report.incompleteBackstops.length} durationMs=${report.durationMs}`);
  for (const miss of report.selectorMisses) console.log(`[change-impact-observation] MISS ${miss.id}: ${miss.reason}`);
  for (const incomplete of report.incompleteBackstops) console.log(`[change-impact-observation] INCOMPLETE ${incomplete.shardId}: ${incomplete.result}`);
  console.log(`[change-impact-observation] report=${reportPath}`);
}

if (require.main === module) main();

module.exports = { correlateOutcomes, jobShardMap };
