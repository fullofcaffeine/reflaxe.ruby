#!/usr/bin/env node

const {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
} = require("node:fs");
const { dirname, join, relative, resolve } = require("node:path");
const { execFileSync, spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");
const {
  developmentIdentity,
  identityFromArgs,
  stageHaxelibMetadata,
  stageProvenance,
  stageRubyVersion,
} = require("./release-identity");

const root = resolve(__dirname, "..", "..");
const identityArgs = process.argv.slice(2);
const identity = identityArgs.length === 0
  ? developmentIdentity(execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim())
  : identityFromArgs(identityArgs);
const outPath = join(root, "dist", "reflaxe.ruby-release.zip");
const reflaxeRoot = join(root, "vendor", "reflaxe");
const reflaxeRun = join(reflaxeRoot, "Run.hx");

const workPrefixes = ["src/", "std/"];
const workFiles = new Set(["haxelib.json", "extraParams.hxml", "README.md", "LICENSE"]);
const extraPrefixes = [
  "runtime/",
  "lib/",
  "vendor/reflaxe/",
  "vendor/genes/src/",
  "docs/",
  "examples/",
];
const extraFiles = new Set([
  "hxruby.gemspec",
  "CHANGELOG.md",
  "vendor/genes/haxelib.json",
  "vendor/genes/readme.md",
]);

function fail(message) {
  console.error(`[haxelib-package] ERROR: ${message}`);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
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

function currentFiles() {
  const files = new Set();
  for (const args of [["ls-files"], ["ls-files", "--others", "--exclude-standard"]]) {
    for (const file of run("git", args).stdout.trim().split("\n").filter(Boolean)) {
      if (existsSync(join(root, file))) {
        files.add(file);
      }
    }
  }
  return [...files].sort();
}

function matches(file, prefixes, files) {
  return files.has(file) || prefixes.some((prefix) => file.startsWith(prefix));
}

function copyFileToRoot(file, destRoot) {
  const from = join(root, file);
  const to = join(destRoot, file);
  mkdirSync(dirname(to), { recursive: true });
  copyFileSync(from, to);
}

function copySelected(files, destRoot, prefixes, exactFiles) {
  for (const file of files) {
    if (matches(file, prefixes, exactFiles)) {
      copyFileToRoot(file, destRoot);
    }
  }
}

function listFiles(dir) {
  const out = [];
  walk(dir, out);
  return out.map((path) => relative(dir, path).split("\\").join("/")).sort();
}

function walk(dir, out) {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    const stat = statSync(path);
    if (stat.isDirectory()) {
      walk(path, out);
    } else {
      out.push(path);
    }
  }
}

if (!existsSync(reflaxeRun)) {
  fail("vendored Reflaxe build runner missing: vendor/reflaxe/Run.hx");
}

const files = currentFiles();
for (const required of [
  "haxelib.json",
  "extraParams.hxml",
  "README.md",
  "LICENSE",
  "src/reflaxe/ruby/RubyCompiler.hx",
  "std/ruby/_std/Std.hx",
  "std/ruby/StandardError.hx",
  "runtime/hxruby/core.rb",
  "vendor/reflaxe/Run.hx",
  "vendor/reflaxe/src/reflaxe/ReflectCompiler.hx",
  "vendor/genes/src/genes/Generator.hx",
]) {
  if (!files.includes(required)) {
    fail(`required package source missing: ${required}`);
  }
}

mkdirSync(dirname(outPath), { recursive: true });
rmSync(outPath, { force: true });

const tempRoot = mkdtempSync(join(tmpdir(), "reflaxe-ruby-haxelib."));
try {
  const workDir = join(tempRoot, "work", "reflaxe.ruby");
  const buildDir = join(workDir, "_Build");
  mkdirSync(workDir, { recursive: true });

  copySelected(files, workDir, workPrefixes, workFiles);
  stageHaxelibMetadata(workDir, identity);
  run("haxe", ["-cp", reflaxeRoot, "--run", "Run", "build", "_Build", "--deleteOldFolder", workDir], {
    cwd: workDir,
  });

  copySelected(files, buildDir, extraPrefixes, extraFiles);
  stageHaxelibMetadata(buildDir, identity);
  stageRubyVersion(buildDir, identity);
  stageProvenance(buildDir, identity);

  const entries = listFiles(buildDir);
  if (entries.length === 0) {
    fail("Reflaxe build produced an empty package directory");
  }
  run("zip", ["-X", "-q", "-@", outPath], {
    cwd: buildDir,
    input: `${entries.join("\n")}\n`,
  });
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log(outPath);
