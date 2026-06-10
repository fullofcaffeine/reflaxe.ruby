#!/usr/bin/env node

const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");

const result = spawnSync("haxe", [
  "-cp",
  join(root, "src"),
  "-cp",
  join(root, "test"),
  "-main",
  "CompilerShellCompileMain",
  "--interp",
], {
  cwd: root,
  stdio: "inherit",
});

process.exit(result.status ?? 1);
