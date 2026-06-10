#!/usr/bin/env node

const { existsSync, readFileSync } = require("node:fs");

function fail(message) {
  console.error(`[release-contracts] ERROR: ${message}`);
  process.exitCode = 1;
}

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function expectIncludes(haystack, needle, label) {
  if (!haystack.includes(needle)) {
    fail(`${label} missing ${needle}`);
  }
}

const packageJson = readJson("package.json");
const haxelibJson = readJson("haxelib.json");
const haxerc = readJson(".haxerc");
const ciWorkflow = readFileSync(".github/workflows/ci.yml", "utf8");
const releaseWorkflow = readFileSync(".github/workflows/release.yml", "utf8");
const rubyHxml = readFileSync("haxe_libraries/reflaxe.ruby.hxml", "utf8");

if (packageJson.name !== "reflaxe-ruby") {
  fail(`package.json name must be reflaxe-ruby, got ${packageJson.name}`);
}
if (haxelibJson.name !== "reflaxe.ruby") {
  fail(`haxelib.json name must be reflaxe.ruby, got ${haxelibJson.name}`);
}
if (haxelibJson.classPath !== "src") {
  fail(`haxelib.json classPath must be src, got ${haxelibJson.classPath}`);
}
if (!rubyHxml.includes("-cp ${SCOPE_DIR}/std/")) {
  fail("haxe_libraries/reflaxe.ruby.hxml must include std/ classpath");
}

const releaseConfig = packageJson.release;
if (!releaseConfig || !Array.isArray(releaseConfig.plugins)) {
  fail("package.json release.plugins must be configured");
} else {
  for (const plugin of [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/exec",
    "@semantic-release/git",
    "@semantic-release/github",
  ]) {
    if (!releaseConfig.plugins.some((entry) => Array.isArray(entry) ? entry[0] === plugin : entry === plugin)) {
      fail(`semantic-release plugin missing: ${plugin}`);
    }
  }

  const gitPlugin = releaseConfig.plugins.find((entry) => Array.isArray(entry) && entry[0] === "@semantic-release/git");
  const assets = gitPlugin?.[1]?.assets ?? [];
  const releaseMessage = gitPlugin?.[1]?.message ?? "";
  if (releaseMessage.includes("\\n")) {
    fail("@semantic-release/git message must use newline escapes, not literal backslash-n text");
  }
  if (!releaseMessage.includes("\n\n")) {
    fail("@semantic-release/git message must separate subject and notes with a blank line");
  }
  for (const asset of assets) {
    if (!existsSync(asset)) {
      fail(`release asset does not exist: ${asset}`);
    }
  }
  for (const requiredAsset of ["package.json", "haxelib.json", "haxe_libraries/reflaxe.ruby.hxml", "README.md", "CHANGELOG.md"]) {
    if (!assets.includes(requiredAsset)) {
      fail(`release git assets missing required file: ${requiredAsset}`);
    }
  }
}

expectIncludes(ciWorkflow, `HAXE_VERSION: "${haxerc.version}"`, "CI workflow");
expectIncludes(ciWorkflow, "ruby-version:", "CI workflow");
for (const rubyVersion of ['"3.2"', '"3.3"', '"4.0"']) {
  expectIncludes(ciWorkflow, rubyVersion, "CI Ruby matrix");
}
expectIncludes(ciWorkflow, "npx lix download haxe", "CI Haxe setup");
expectIncludes(ciWorkflow, "npm test", "CI test step");
expectIncludes(ciWorkflow, 'FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"', "CI workflow");
expectIncludes(releaseWorkflow, "npx semantic-release", "Release workflow");
expectIncludes(releaseWorkflow, "fetch-depth: 0", "Release workflow");
expectIncludes(releaseWorkflow, 'FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"', "Release workflow");

if (process.exitCode) {
  process.exit(process.exitCode);
}

console.log("[release-contracts] OK");
