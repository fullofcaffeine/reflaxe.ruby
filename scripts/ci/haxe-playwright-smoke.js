#!/usr/bin/env node

const { existsSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const generatedDir = join(root, "examples", "todoapp_rails", "e2e", "generated");
const wrapper = join(generatedDir, "haxe_todoapp.spec.js");
const entry = join(generatedDir, "haxe_todoapp", "spec.js");
const implementation = join(generatedDir, "haxe_todoapp", "e2e_haxe", "TodoappBrowserSpec.js");
const packageMarker = join(generatedDir, "package.json");

rmSync(generatedDir, { recursive: true, force: true });
run("haxe", ["examples/todoapp_rails/build-e2e.hxml"]);
writeFileSync(packageMarker, JSON.stringify({ type: "module" }, null, 2) + "\n");
writeFileSync(wrapper, 'import "./haxe_todoapp/spec.js";\n');

if (!existsSync(wrapper)) {
  fail(`missing generated Playwright wrapper ${relative(wrapper)}`);
}
if (!existsSync(entry)) {
  fail(`missing generated Playwright entry ${relative(entry)}`);
}
if (!existsSync(implementation)) {
  fail(`missing generated Playwright implementation ${relative(implementation)}`);
}

const wrapperJs = readFileSync(wrapper, "utf8");
const entryJs = readFileSync(entry, "utf8");
const implementationJs = readFileSync(implementation, "utf8");

assertIncludes(wrapperJs, 'import "./haxe_todoapp/spec.js"', wrapper);

for (const expected of [
  "TodoappBrowserSpec.main()",
  "import {TodoappBrowserSpec}",
]) {
  assertIncludes(entryJs, expected, entry);
}

for (const expected of [
  'import * as PlaywrightApi from "@playwright/test"',
  "PW.testPage(\"haxe-authored browser spec reuses typed RailsHx hooks\"",
  "async function (page)",
  "page.locator(\".\" + \"todo-shell\")",
  "page.locator(\"#\" + \"railshx-chat-panel\")",
  "page.locator(\"[\" + \"data-railshx-flash\" + \"]\")",
]) {
  assertIncludes(implementationJs, expected, implementation);
}

console.log("[haxe-playwright] OK");

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    process.stdout.write(result.stdout ?? "");
    process.stderr.write(result.stderr ?? "");
    process.exit(result.status ?? 1);
  }
}

function assertIncludes(source, needle, file) {
  if (!source.includes(needle)) {
    fail(`${relative(file)} is missing ${needle}`);
  }
}

function relative(path) {
  return path.slice(root.length + 1);
}

function fail(message) {
  console.error(`[haxe-playwright] ERROR: ${message}`);
  process.exit(1);
}
