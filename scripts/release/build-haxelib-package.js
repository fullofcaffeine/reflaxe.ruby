#!/usr/bin/env node

const { mkdirSync, readFileSync, rmSync } = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const haxelibJson = JSON.parse(readFileSync(join(root, "haxelib.json"), "utf8"));
const version = haxelibJson.version;
const outPath = join(root, "dist", `reflaxe.ruby-${version}.zip`);

const includePrefixes = [
  "src/",
  "std/",
  "runtime/",
  "vendor/reflaxe/",
  "docs/",
  "examples/",
  "haxe_libraries/",
];
const includeFiles = new Set([
  "haxelib.json",
  "extraParams.hxml",
  "README.md",
  "CHANGELOG.md",
  "LICENSE",
]);

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    input: options.input,
    stdio: options.input == null ? ["ignore", "pipe", "pipe"] : ["pipe", "pipe", "pipe"],
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

const files = run("git", ["ls-files"]).stdout
  .trim()
  .split("\n")
  .filter(Boolean)
  .filter((path) => includeFiles.has(path) || includePrefixes.some((prefix) => path.startsWith(prefix)))
  .sort();

mkdirSync(dirname(outPath), { recursive: true });
rmSync(outPath, { force: true });
run("zip", ["-q", "-@", outPath], { input: `${files.join("\n")}\n` });

console.log(outPath);
