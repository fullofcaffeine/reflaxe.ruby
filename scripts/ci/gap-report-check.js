#!/usr/bin/env node

const { existsSync, readFileSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const inventoryPath = join(root, "docs", "stdlib-inventory.json");
const reportPath = join(root, "test", "ruby_gap_report.json");
const update = process.env.UPDATE_GAP_REPORT === "1";
const inventory = JSON.parse(readFileSync(inventoryPath, "utf8"));

const report = buildReport(inventory);
const serialized = `${JSON.stringify(report, null, 2)}\n`;

if (update) {
  writeFileSync(reportPath, serialized);
  process.exit(0);
}

if (!existsSync(reportPath)) {
  console.error("Missing test/ruby_gap_report.json. Run UPDATE_GAP_REPORT=1 npm run test:gap-report.");
  process.exit(1);
}

const expected = readFileSync(reportPath, "utf8");
if (expected !== serialized) {
  console.error("test/ruby_gap_report.json is out of date. Run UPDATE_GAP_REPORT=1 npm run test:gap-report.");
  process.exit(1);
}

function buildReport(source) {
  const entries = source.entries.slice().sort((a, b) => a.id.localeCompare(b.id));
  const summary = {
    total: entries.length,
    implemented: countStatus(entries, "implemented"),
    missing: countStatus(entries, "missing"),
    planned: countStatus(entries, "planned"),
    deferred: countStatus(entries, "deferred"),
    byOwner: {},
  };

  for (const entry of entries) {
    summary.byOwner[entry.owner] ??= { total: 0, implemented: 0, missing: 0, planned: 0, deferred: 0 };
    summary.byOwner[entry.owner].total++;
    summary.byOwner[entry.owner][entry.status]++;
  }

  return {
    schemaVersion: 1,
    generatedFrom: "docs/stdlib-inventory.json",
    summary,
    gaps: entries
      .filter((entry) => entry.status !== "implemented")
      .map(({ id, owner, status, path, surface, reason }) => ({ id, owner, status, path, surface, reason })),
  };
}

function countStatus(entries, status) {
  return entries.filter((entry) => entry.status === status).length;
}
