#!/usr/bin/env node

"use strict";

const { mkdirSync, writeFileSync } = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const defaultReportPath = join(root, "test", ".generated", "test-loop", "agent-smoke.json");
const stageTimeoutMs = 120_000;
const npmCommand = process.platform === "win32" ? "npm.cmd" : "npm";

/**
 * This is a fixed repository-checkout canary for short human and agent loops.
 * It deliberately reuses existing semantic owners; it does not replace the
 * affected focused test, the full suite, or clean public-package qualification.
 */
const smokeStages = Object.freeze([
  Object.freeze({
    id: "profile-contract",
    script: "test:profile-resolver",
    evidence: "Ruby profile selection and conflicting-profile diagnostics",
  }),
  Object.freeze({
    id: "ruby-ast-contract",
    script: "test:ruby-ast",
    evidence: "structural AST printing, exhaustive children, and scope traversal",
  }),
  Object.freeze({
    id: "compile-runtime-canary",
    script: "test:hello-world",
    evidence: "Haxe compilation, generated Ruby syntax, and Ruby execution",
  }),
  Object.freeze({
    id: "exception-runtime-canary",
    script: "test:exception-flow",
    evidence: "portable throw, catch, finally, and native Ruby exception behavior",
  }),
  Object.freeze({
    id: "upstream-issue-canary",
    script: "test:json-parity",
    evidence: "broader official Haxe JSON cases and issue regressions on Ruby",
  }),
  Object.freeze({
    id: "filesystem-capability-canary",
    script: "test:filesystem-parity",
    evidence: "filesystem, binary I/O, EOF, and native error runtime behavior",
  }),
  Object.freeze({
    id: "upstream-unitstd-canary",
    script: "test:unitstd-ruby",
    evidence: "all currently enabled or adapted upstream unitstd fixtures on Ruby",
  }),
]);

function commandOutput(command, args) {
  const result = spawnSync(command, args, { cwd: root, encoding: "utf8" });
  return result.status === 0 ? result.stdout.trim() : "unknown";
}

function toolchainIdentity() {
  return {
    node: process.version,
    npm: commandOutput(npmCommand, ["--version"]),
    haxe: commandOutput("haxe", ["-version"]),
    ruby: commandOutput("ruby", ["--disable-gems", "-e", "print RUBY_VERSION"]),
  };
}

function writeReport(path, report) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${JSON.stringify(report, null, 2)}\n`);
}

function runStage(stage) {
  console.log(`[agent-smoke] START ${stage.id}: ${stage.evidence}`);
  const started = process.hrtime.bigint();
  const result = stage.command
    ? spawnSync(stage.command[0], stage.command.slice(1), {
        cwd: root,
        encoding: "utf8",
        stdio: "inherit",
        timeout: stageTimeoutMs,
      })
    : spawnSync(npmCommand, ["run", stage.script], {
        cwd: root,
        encoding: "utf8",
        stdio: "inherit",
        timeout: stageTimeoutMs,
      });
  const durationMs = Number((process.hrtime.bigint() - started) / 1_000_000n);
  const outcome = result.error?.code === "ETIMEDOUT" ? "timeout" : result.status === 0 ? "pass" : "fail";
  console.log(`[agent-smoke] ${outcome.toUpperCase()} ${stage.id} (${durationMs} ms)`);
  return {
    id: stage.id,
    script: stage.script ?? null,
    evidence: stage.evidence,
    outcome,
    durationMs,
    exitCode: result.status,
    signal: result.signal,
  };
}

function fixtureStages() {
  return [
    {
      id: "fixture-pass",
      command: [process.execPath, "-e", "process.exit(0)"],
      evidence: "synthetic passing stage",
    },
    {
      id: "fixture-fail",
      command: [process.execPath, "-e", "process.exit(23)"],
      evidence: "synthetic failing stage",
    },
    {
      id: "fixture-must-not-run",
      command: [process.execPath, "-e", "process.exit(0)"],
      evidence: "proves first-failure stopping",
    },
  ];
}

function main() {
  const fixtureFailure = process.argv.includes("--fixture-fail");
  const reportPath = process.env.HAXE_RUBY_AGENT_SMOKE_REPORT
    ? resolve(process.env.HAXE_RUBY_AGENT_SMOKE_REPORT)
    : defaultReportPath;
  const stages = fixtureFailure ? fixtureStages() : smokeStages;
  const startedAt = new Date().toISOString();
  const started = process.hrtime.bigint();
  const results = [];

  for (const stage of stages) {
    const result = runStage(stage);
    results.push(result);
    if (result.outcome !== "pass") break;
  }

  const outcome = results.length === stages.length && results.every((result) => result.outcome === "pass")
    ? "pass"
    : "fail";
  const report = {
    schemaVersion: 1,
    ring: fixtureFailure ? "self-test" : "R1",
    scope: fixtureFailure
      ? "agent smoke harness failure-propagation fixture"
      : "fast repository-checkout canary; not full or public-package qualification",
    cacheMode: "warm-allowed",
    sourceSha: commandOutput("git", ["rev-parse", "HEAD"]),
    dirty: commandOutput("git", ["status", "--porcelain"]) !== "",
    toolchain: toolchainIdentity(),
    startedAt,
    durationMs: Number((process.hrtime.bigint() - started) / 1_000_000n),
    outcome,
    selected: stages.map((stage) => stage.id),
    omitted: [
      "changed semantic-owner tests",
      "complete snapshots",
      "Rails runtime",
      "browser and production dogfood",
      "package installation",
      "security and release evidence",
      "complete official Haxe baseline qualification",
    ],
    stages: results,
  };
  writeReport(reportPath, report);
  console.log(`[agent-smoke] report: ${reportPath}`);
  process.exitCode = outcome === "pass" ? 0 : results.at(-1)?.exitCode || 1;
}

if (require.main === module) main();

module.exports = {
  smokeStages,
};
