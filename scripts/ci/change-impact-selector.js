#!/usr/bin/env node

"use strict";

const { mkdirSync, readFileSync, writeFileSync } = require("node:fs");
const { spawnSync } = require("node:child_process");
const { dirname, join, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const manifestPath = join(root, "test", "change-impact-ownership.json");
const defaultReportPath = join(root, "test", ".generated", "change-impact", "report.json");

/**
 * This selector recommends evidence; it never runs or suppresses tests. Keeping
 * selection separate from execution lets the unchanged full CI gate measure
 * misses before any future workflow is allowed to depend on the recommendation.
 */
function loadManifest() {
  return JSON.parse(readFileSync(manifestPath, "utf8"));
}

function normalizeChangedPath(path) {
  return path.trim().replaceAll("\\", "/").replace(/^\.\//, "");
}

function matches(rule, path) {
  if (rule.exact?.includes(path)) return true;
  return rule.prefixes?.some((prefix) => path.startsWith(prefix)) ?? false;
}

function selectForPaths(manifest, changedPaths, observedFailures = []) {
  const shardById = new Map(manifest.shards.map((shard) => [shard.id, shard]));
  const selectedReasons = new Map();
  const pathDecisions = [];
  let fullFallback = changedPaths.length === 0;

  function select(id, reason) {
    if (!shardById.has(id)) throw new Error(`ownership manifest references unknown shard ${id}`);
    if (!selectedReasons.has(id)) selectedReasons.set(id, []);
    selectedReasons.get(id).push(reason);
  }

  for (const id of manifest.alwaysRun) select(id, "central sentinel: selected for every change");

  for (const path of changedPaths) {
    const rule = manifest.rules.find((candidate) => matches(candidate, path));
    if (!rule) {
      fullFallback = true;
      pathDecisions.push({ path, rule: null, owners: [], surfaces: manifest.productSurfaces, outcome: "full", reason: "No ownership rule matched this path." });
      continue;
    }
    pathDecisions.push({
      path,
      rule: rule.id,
      owners: rule.owners,
      surfaces: rule.surfaces,
      outcome: rule.full ? "full" : "focused",
      reason: rule.reason,
    });
    if (rule.full) fullFallback = true;
    for (const id of rule.select ?? []) select(id, `${path}: ${rule.reason}`);
  }

  if (fullFallback) {
    for (const id of manifest.fullBackstop) select(id, manifest.fullFallbackReason);
  }

  const selected = manifest.shards
    .filter((shard) => selectedReasons.has(shard.id))
    .map((shard) => ({ ...shard, reasons: [...new Set(selectedReasons.get(shard.id))] }));
  const selectedIds = new Set(selected.map((shard) => shard.id));
  const omitted = manifest.shards
    .filter((shard) => !selectedIds.has(shard.id))
    .map((shard) => ({
      id: shard.id,
      localCommand: shard.localCommand,
      surfaces: shard.surfaces,
      axes: shard.axes,
      reason: `No changed semantic owner selected this shard (${shard.axes.join(", ")}).`,
    }));
  const selectorMisses = [...new Set(observedFailures)]
    .filter((id) => !selectedIds.has(id))
    .map((id) => ({ id, reason: "The unchanged backstop observed a failure in a shard the selector omitted." }));

  for (const id of observedFailures) {
    if (!shardById.has(id)) throw new Error(`observed failure references unknown shard ${id}`);
  }

  return { fullFallback, pathDecisions, selected, omitted, observedFailures: [...new Set(observedFailures)], selectorMisses };
}

function gitChangedPaths(base, head) {
  if (!base || /^0+$/.test(base)) return [];
  const result = spawnSync("git", ["diff", "--name-only", "--diff-filter=ACDMRTUXB", base, head], {
    cwd: root,
    encoding: "utf8",
  });
  if (result.status !== 0) return [];
  return result.stdout.split(/\r?\n/).map(normalizeChangedPath).filter(Boolean);
}

function parseArgs(argv) {
  const options = { paths: [], observedFailures: [] };
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
    else if (value === "--observed-failure") options.observedFailures.push(next());
    else throw new Error(`unknown argument ${value}`);
  }
  return options;
}

function main() {
  const started = process.hrtime.bigint();
  const options = parseArgs(process.argv.slice(2));
  const manifest = loadManifest();
  const changedPaths = [...new Set(options.paths.length > 0 ? options.paths : gitChangedPaths(options.base, options.head))];
  const selection = selectForPaths(manifest, changedPaths, options.observedFailures);
  const report = {
    schemaVersion: 1,
    mode: manifest.mode,
    authority: "advisory only; canonical CI remains unchanged",
    base: options.base ?? null,
    head: options.head ?? null,
    changedPaths,
    fallbackReason: selection.fullFallback ? manifest.fullFallbackReason : null,
    ...selection,
    durationMs: Number((process.hrtime.bigint() - started) / 1_000_000n),
  };
  const reportPath = options.report ?? defaultReportPath;
  mkdirSync(dirname(reportPath), { recursive: true });
  writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);

  console.log(`[change-impact] mode=${report.mode} fullFallback=${report.fullFallback} changed=${changedPaths.length} durationMs=${report.durationMs}`);
  for (const decision of report.pathDecisions) console.log(`[change-impact] PATH ${decision.path}: ${decision.outcome} (${decision.rule ?? "unowned"}; owners=${decision.owners.join(",") || "unknown"}; surfaces=${decision.surfaces.join(",") || "none"}) ${decision.reason}`);
  for (const shard of report.selected) console.log(`[change-impact] SELECT ${shard.id}: ${shard.reasons.join(" | ")}`);
  for (const shard of report.omitted) console.log(`[change-impact] OMIT ${shard.id}: ${shard.reason}`);
  for (const miss of report.selectorMisses) console.log(`[change-impact] MISS ${miss.id}: ${miss.reason}`);
  console.log(`[change-impact] report=${reportPath}`);
}

if (require.main === module) main();

module.exports = { loadManifest, matches, normalizeChangedPath, selectForPaths };
