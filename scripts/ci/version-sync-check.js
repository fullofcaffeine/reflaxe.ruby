#!/usr/bin/env node

const fs = require("node:fs");
const { DEVELOPMENT_VERSION, HAXELIB_RELEASE_NOTE } = require("../release/release-identity");

function fail(message) {
  console.error(`[version-sync] ERROR: ${message}`);
  process.exitCode = 1;
}

function readJson(path) {
  return JSON.parse(fs.readFileSync(path, "utf8"));
}

const packageJson = readJson("package.json");
const packageLock = readJson("package-lock.json");
const haxelibJson = readJson("haxelib.json");
const rubyHxml = fs.readFileSync("haxe_libraries/reflaxe.ruby.hxml", "utf8");
const clientHxml = fs.readFileSync("haxe_libraries/railshx.client.hxml", "utf8");
const hxrubyVersion = fs.readFileSync("lib/hxruby/version.rb", "utf8");
const readme = fs.readFileSync("README.md", "utf8");

for (const [surface, actual] of [
  ["package.json", packageJson.version],
  ["package-lock.json", packageLock.version],
  ["package-lock.json root package", packageLock.packages?.[""]?.version],
  ["haxelib.json", haxelibJson.version],
]) {
  if (actual !== DEVELOPMENT_VERSION) fail(`${surface} must use development sentinel ${DEVELOPMENT_VERSION}, got ${actual}`);
}
if (haxelibJson.releasenote !== HAXELIB_RELEASE_NOTE) fail("haxelib.json development release note drifted");

for (const [surface, text, define] of [
  ["haxe_libraries/reflaxe.ruby.hxml", rubyHxml, "reflaxe.ruby"],
  ["haxe_libraries/railshx.client.hxml", clientHxml, "railshx.client"],
]) {
  if (!text.includes(`-D ${define}=${DEVELOPMENT_VERSION}`)) fail(`${surface} must use development sentinel`);
}
if (!hxrubyVersion.includes(`VERSION = "${DEVELOPMENT_VERSION}"`)) fail("lib/hxruby/version.rb must use development sentinel");
if (!readme.includes("Tracked version files intentionally use the `0.0.0` development sentinel")) fail("README must document the development sentinel");
if (!readme.includes("`v0.1.0-beta.2`")) fail("README must preserve the latest public baseline tag");

if (process.exitCode) process.exit(process.exitCode);
console.log(`[version-sync] OK: tracked development sentinel ${DEVELOPMENT_VERSION}`);
