#!/usr/bin/env node

"use strict";

const { existsSync, readFileSync } = require("node:fs");
const { join, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const evidenceRoot = join(root, "test", ".generated", "public_install_official");
const reportPath = join(evidenceRoot, "report.json");
const humanReportPath = join(evidenceRoot, "report.txt");
const manifest = JSON.parse(readFileSync(join(root, "test", "public_install_official", "manifest.json"), "utf8"));

function fail(message) {
  throw new Error(`[public-install-official-contract] ${message}`);
}

if (!existsSync(reportPath)) fail(`machine report is missing: ${reportPath}`);
if (!existsSync(humanReportPath)) fail(`human report is missing: ${humanReportPath}`);

const report = JSON.parse(readFileSync(reportPath, "utf8"));
if (report.schemaVersion !== 1 || report.outcome !== "pass") {
  fail("machine report must record a schema-1 passing outcome");
}
if (report.baseline.commit !== manifest.baseline.commit
  || JSON.stringify(report.families) !== JSON.stringify(manifest.families)) {
  fail("machine report must retain the reviewed baseline and exact family provenance");
}
if (JSON.stringify(report.families.map((family) => family.id))
  !== JSON.stringify(["shared-top-level", "unitstd", "general-issue"])) {
  fail("machine report must keep the three product families independent and ordered");
}
if (report.consumer.rootAuthority !== "isolated-haxelib-repository"
  || report.consumer.resolvedInstallSource !== "isolated-haxelib-repository"
  || report.consumer.checkoutClasspathsRejected !== true) {
  fail("machine report must prove isolated Haxelib authority and reject checkout classpaths");
}
for (const forbidden of [root, "vendor/reflaxe", "std/ruby/_std"]) {
  if (report.consumer.compileArguments.join(" ").includes(forbidden)) {
    fail(`consumer compile arguments contain forbidden checkout shortcut: ${forbidden}`);
  }
}
for (const requiredStage of [
  "verify-provenance",
  "build-release-shaped-package",
  "install-public-package",
  "resolve-install-authority",
  "compile-official-representatives",
  "check-generated-ruby",
  "execute-official-representatives",
  "prove-assertion-failure",
  "prove-runtime-failure",
]) {
  const stage = report.stages.find((entry) => entry.id === requiredStage);
  if (!stage || stage.status !== "pass") fail(`required stage is not passing: ${requiredStage}`);
}
if (report.runtime.exitCode !== 0
  || !/^public-install-official ok families=3 topLevelAssertions=\d+\n$/.test(report.runtime.stdout)
  || report.runtime.topLevelAssertions < 50) {
  fail("runtime report does not prove all three families and meaningful assertion execution");
}
for (const required of ["main.rb", "run.rb", "unit/test_ops.rb", "unit/issues/issue10098.rb", "string_buf.rb"]) {
  if (!report.runtime.generatedRubyFiles.includes(required)) fail(`generated Ruby inventory is missing ${required}`);
}
for (const [id, marker] of [
  ["assertion", "official assertion failed"],
  ["runtime", "intentional-public-install-runtime-failure"],
]) {
  const probe = report.failureProbes[id];
  if (!probe || probe.exitCode === 0 || probe.marker !== marker) {
    fail(`${id} failure probe did not preserve a recognizable nonzero result`);
  }
}

const humanReport = readFileSync(humanReportPath, "utf8");
for (const expected of [
  "PUBLIC INSTALL OFFICIAL: PASS",
  "install authority: isolated-haxelib-repository",
  "assertion failure propagation: nonzero",
  "runtime failure propagation: nonzero",
]) {
  if (!humanReport.includes(expected)) fail(`human report is missing ${JSON.stringify(expected)}`);
}

console.log("[public-install-official-contract] OK");
