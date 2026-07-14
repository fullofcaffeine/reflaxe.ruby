#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const { resolve } = require("node:path");

const root = resolve(__dirname, "../..");
const expectedVersion = "bundler-audit 0.9.3";

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    ...options,
  });
  if (result.error) {
    throw result.error;
  }
  return result;
}

function requireSuccess(result, label) {
  if (result.status === 0) return;

  process.stderr.write(result.stdout ?? "");
  process.stderr.write(result.stderr ?? "");
  throw new Error(`${label} failed with status ${result.status}`);
}

const version = run("bundle-audit", ["--version"]);
requireSuccess(version, "bundler-audit version check");
if (version.stdout.trim() !== expectedVersion) {
  throw new Error(`expected ${expectedVersion}, got ${version.stdout.trim()}`);
}

const update = run("bundle-audit", ["update"], { stdio: "inherit" });
requireSuccess(update, "ruby-advisory-db update");

const tracked = run("git", ["ls-files", "-z", "*Gemfile.lock"]);
requireSuccess(tracked, "tracked Gemfile.lock inventory");
const lockfiles = tracked.stdout.split("\0").filter(Boolean);
if (lockfiles.length === 0) {
  throw new Error("no tracked Gemfile.lock files found to audit");
}

for (const lockfile of lockfiles) {
  const audit = run("bundle-audit", ["check", "--no-update", "--gemfile-lock", lockfile], { stdio: "inherit" });
  requireSuccess(audit, `Ruby advisory audit for ${lockfile}`);
}

const vulnerableFixture = "test/fixtures/security/vulnerable.lock";
const fixtureAudit = run("bundle-audit", ["check", "--no-update", "--gemfile-lock", vulnerableFixture]);
const fixtureOutput = `${fixtureAudit.stdout ?? ""}${fixtureAudit.stderr ?? ""}`;
if (fixtureAudit.status === 0 || !fixtureOutput.includes("Vulnerabilities found!")) {
  throw new Error("known-vulnerable Ruby lock fixture was not detected");
}

console.log(`[ruby-advisories] OK: ${lockfiles.length} tracked lockfile(s) clean; vulnerable fixture detected`);
