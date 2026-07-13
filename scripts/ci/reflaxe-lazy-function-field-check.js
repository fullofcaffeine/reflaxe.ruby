#!/usr/bin/env node

const { readFileSync, rmSync } = require("node:fs");
const { resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const helperPath = "vendor/reflaxe/src/reflaxe/helpers/ClassFieldHelper.hx";
const outputPath = resolve(root, "test/.generated/reflaxe_lazy_function_field");

function fail(message) {
  console.error(`[reflaxe-lazy-function-field] ERROR: ${message}`);
  process.exit(1);
}

const helper = readFileSync(resolve(root, helperPath), "utf8");
const lazySwitch = "switch(resolveLazyType(field.type))";
const lazySwitchCount = helper.split(lazySwitch).length - 1;

if (!helper.includes("static function resolveLazyType(type: Type): Type")) {
  fail(`${helperPath} must keep the narrow lazy-type resolver from upstream Reflaxe PR #52`);
}
if (!helper.includes("case TLazy(resolve): resolveLazyType(resolve());")) {
  fail("the resolver must recursively unwrap nested TLazy values");
}
if (lazySwitchCount !== 2) {
  fail(`expected lazy resolution at function extraction and overload cache identity; found ${lazySwitchCount}`);
}

rmSync(outputPath, { recursive: true, force: true });
const result = spawnSync("haxe", ["test/reflaxe_lazy_function_field/compile.hxml"], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
rmSync(outputPath, { recursive: true, force: true });

if (result.status !== 0) {
  process.stdout.write(result.stdout);
  process.stderr.write(result.stderr);
  fail("the real vendored Reflaxe compiler lifecycle rejected a lazily typed function field");
}

console.log("[reflaxe-lazy-function-field] OK: vendored Reflaxe resolves TLazy(TFun) metadata");
