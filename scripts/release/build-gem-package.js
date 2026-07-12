#!/usr/bin/env node

const { copyFileSync, mkdirSync, mkdtempSync, rmSync } = require("node:fs");
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
  run: runChecked,
  verifyArtifactManifest,
  walkFiles,
  writeArtifactManifest,
  writeArtifactSidecar,
} = require("./artifact-utils");

const root = resolve(__dirname, "..", "..");
const identityArgs = process.argv.slice(2);
const identity = identityArgs.length === 0
  ? developmentIdentity(execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim())
  : identityFromArgs(identityArgs);
const outPath = join(root, "dist", "hxruby-release.gem");

function run(command, args, cwd = root, env = process.env) {
  const result = spawnSync(command, args, {
    cwd,
    env,
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

mkdirSync(dirname(outPath), { recursive: true });
rmSync(outPath, { force: true });

const tempRoot = mkdtempSync(join(tmpdir(), "hxruby-gem-stage."));
try {
  const sourceRoot = join(tempRoot, "source");
  const stageRoot = join(tempRoot, "stage");
  extractGitSource(root, identity.sourceSha, sourceRoot);
  mkdirSync(stageRoot, { recursive: true });
  // Walking the complete archived tree rejects symlinks and special files before the gemspec can
  // select or dereference them. The resulting set also constrains every gem entry to the tested
  // commit instead of trusting arbitrary filesystem paths returned by executable gemspec code.
  const sourceFiles = new Set(walkFiles(sourceRoot));
  const fileList = run("ruby", ["-e", 'require "rubygems"; Gem::Specification.load("hxruby.gemspec").files.each { |file| puts file }'], sourceRoot)
    .stdout.trim().split("\n").filter(Boolean);
  if (new Set(fileList).size !== fileList.length) throw new Error("gemspec contains duplicate package paths");
  for (const file of fileList) {
    if (!sourceFiles.has(file)) throw new Error(`gemspec path is absent or unsafe in ${identity.sourceSha}: ${file}`);
    const destination = join(stageRoot, file);
    mkdirSync(dirname(destination), { recursive: true });
    copyFileSync(join(sourceRoot, file), destination);
  }
  stageHaxelibMetadata(stageRoot, identity);
  stageRubyVersion(stageRoot, identity);
  stageProvenance(stageRoot, identity);
  writeArtifactManifest(stageRoot, "hxruby-gem");
  verifyArtifactManifest(stageRoot, "hxruby-gem");

  const sourceDateEpoch = runChecked("git", ["show", "-s", "--format=%ct", identity.sourceSha], { cwd: root }).stdout.trim();
  const releaseEnv = { ...process.env, SOURCE_DATE_EPOCH: sourceDateEpoch, TZ: "UTC", LC_ALL: "C", LANG: "C" };
  const previousUmask = process.umask(0o022);
  try {
    run("gem", ["build", "hxruby.gemspec", "--output", outPath], stageRoot, releaseEnv);
  } finally {
    process.umask(previousUmask);
  }
  writeArtifactSidecar(outPath, `hxruby-${identity.version}.gem`, identity);
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log(outPath);
