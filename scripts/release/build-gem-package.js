#!/usr/bin/env node

const { mkdirSync, readFileSync, rmSync } = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const haxelibJson = JSON.parse(readFileSync(join(root, "haxelib.json"), "utf8"));
const version = haxelibJson.version;
const outPath = join(root, "dist", `hxruby-${version}.gem`);

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

if (packageJson.version !== haxelibJson.version) {
  console.error(`package.json version ${packageJson.version} != haxelib.json version ${haxelibJson.version}`);
  process.exit(1);
}

mkdirSync(dirname(outPath), { recursive: true });
rmSync(outPath, { force: true });
run("gem", ["build", "hxruby.gemspec", "--output", outPath]);

console.log(outPath);
