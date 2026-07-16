#!/usr/bin/env node

const {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  rmSync,
} = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { execFileSync, spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");
const {
  developmentIdentity,
  identityFromArgs,
  stageHaxelibMetadata,
  stageProvenance,
  stageRubyVersion,
} = require("./release-identity");
const {
  extractGitSource,
  verifyArtifactManifest,
  walkFiles,
  writeArtifactManifest,
  writeArtifactSidecar,
} = require("./artifact-utils");
const { createDeterministicZip } = require("./deterministic-zip");

const root = resolve(__dirname, "..", "..");
const identityArgs = process.argv.slice(2);
const identity = identityArgs.length === 0
  ? developmentIdentity(execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim())
  : identityFromArgs(identityArgs);
const outPath = join(root, "dist", "reflaxe.ruby-release.zip");

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

function matches(file, prefixes, files) {
  return files.has(file) || prefixes.some((prefix) => file.startsWith(prefix));
}

function copyFileToRoot(file, sourceRoot, destRoot) {
  const from = join(sourceRoot, file);
  const to = join(destRoot, file);
  mkdirSync(dirname(to), { recursive: true });
  copyFileSync(from, to);
}

function copySelected(files, sourceRoot, destRoot, prefixes, exactFiles) {
  for (const file of files) {
    if (matches(file, prefixes, exactFiles)) {
      copyFileToRoot(file, sourceRoot, destRoot);
    }
  }
}

const requiredFiles = [
  "haxelib.json",
  "extraParams.hxml",
  "README.md",
  "LICENSE",
  "src/reflaxe/ruby/RubyCompiler.hx",
  "std/ruby/_std/Std.hx",
  "std/ruby/CSV.hx",
  "std/ruby/CSVGenerateOptions.hx",
  "std/ruby/CSVParseOptions.hx",
  "std/ruby/CSVRow.hx",
  "std/ruby/Open3.hx",
  "std/ruby/Open3Capture.hx",
  "std/ruby/Open3Executable.hx",
  "std/ruby/Open3Status.hx",
  "std/ruby/Set.hx",
  "std/ruby/StandardError.hx",
  "std/ruby/URI.hx",
  "std/ruby/URIValue.hx",
  "lib/hxruby/stdlib_coverage.json",
  "lib/hxruby/rbs.rb",
  "lib/hxruby/rbs/source_parser.rb",
  "lib/hxruby/rbs/haxe_extern_renderer.rb",
  "lib/hxruby/rbs/extern_generator.rb",
  "lib/hxruby/rbs/cli.rb",
  "runtime/hxruby/core.rb",
  "vendor/reflaxe/Run.hx",
  "vendor/reflaxe/src/reflaxe/ReflectCompiler.hx",
  "vendor/genes/src/genes/Generator.hx",
];

mkdirSync(dirname(outPath), { recursive: true });
rmSync(outPath, { force: true });

const tempRoot = mkdtempSync(join(tmpdir(), "reflaxe-ruby-haxelib."));
try {
  const sourceRoot = join(tempRoot, "source");
  extractGitSource(root, identity.sourceSha, sourceRoot);
  const files = walkFiles(sourceRoot);
  for (const required of requiredFiles) {
    if (!files.includes(required)) fail(`required package source missing from ${identity.sourceSha}: ${required}`);
  }
  const reflaxeRoot = join(sourceRoot, "vendor", "reflaxe");
  if (!existsSync(join(reflaxeRoot, "Run.hx"))) fail("vendored Reflaxe build runner missing");
  const workDir = join(tempRoot, "work", "reflaxe.ruby");
  const buildDir = join(workDir, "_Build");
  mkdirSync(workDir, { recursive: true });

  copySelected(files, sourceRoot, workDir, workPrefixes, workFiles);
  stageHaxelibMetadata(workDir, identity);
  run("haxe", ["-cp", reflaxeRoot, "--run", "Run", "build", "_Build", "--deleteOldFolder", workDir], {
    cwd: workDir,
  });

  copySelected(files, sourceRoot, buildDir, extraPrefixes, extraFiles);
  stageHaxelibMetadata(buildDir, identity);
  stageRubyVersion(buildDir, identity);
  stageProvenance(buildDir, identity);

  writeArtifactManifest(buildDir, "reflaxe.ruby-haxelib");
  verifyArtifactManifest(buildDir, "reflaxe.ruby-haxelib");
  const entries = walkFiles(buildDir);
  if (entries.length === 0) {
    fail("Reflaxe build produced an empty package directory");
  }
  createDeterministicZip(buildDir, outPath);
  writeArtifactSidecar(outPath, `reflaxe.ruby-${identity.version}.zip`, identity);
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log(outPath);
