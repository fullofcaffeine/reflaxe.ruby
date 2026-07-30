#!/usr/bin/env node

"use strict";

const { mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const temporaryRoot = mkdtempSync(join(tmpdir(), "rubyhx-agent-smoke."));
const reportPath = join(temporaryRoot, "report.json");

try {
  const result = spawnSync(process.execPath, [join(root, "scripts", "ci", "agent-smoke.js"), "--fixture-fail"], {
    cwd: root,
    encoding: "utf8",
    env: { ...process.env, HAXE_RUBY_AGENT_SMOKE_REPORT: reportPath },
  });
  if (result.status === 0) throw new Error("synthetic failing stage incorrectly produced a zero exit");

  const report = JSON.parse(readFileSync(reportPath, "utf8"));
  const ids = report.stages.map((stage) => stage.id);
  if (
    report.schemaVersion !== 1
    || report.outcome !== "fail"
    || report.stages.at(-1)?.exitCode !== 23
    || JSON.stringify(ids) !== JSON.stringify(["fixture-pass", "fixture-fail"])
  ) {
    throw new Error(`unexpected failure-propagation report: ${JSON.stringify(report)}`);
  }
  console.log("[agent-smoke-check] OK: nonzero failure preserved and later stages skipped");
} finally {
  rmSync(temporaryRoot, { force: true, recursive: true });
}
