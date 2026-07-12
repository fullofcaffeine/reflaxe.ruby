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

const root = resolve(__dirname, "..", "..");
const identityArgs = process.argv.slice(2);
const identity = identityArgs.length === 0
  ? developmentIdentity(execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim())
  : identityFromArgs(identityArgs);
const outPath = join(root, "dist", "hxruby-release.gem");

function run(command, args, cwd = root) {
  const result = spawnSync(command, args, {
    cwd,
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
  const fileList = run("ruby", ["-e", 'require "rubygems"; Gem::Specification.load("hxruby.gemspec").files.each { |file| puts file }'])
    .stdout.trim().split("\n").filter(Boolean);
  for (const file of fileList) {
    const destination = join(tempRoot, file);
    mkdirSync(dirname(destination), { recursive: true });
    copyFileSync(join(root, file), destination);
  }
  stageHaxelibMetadata(tempRoot, identity);
  stageRubyVersion(tempRoot, identity);
  stageProvenance(tempRoot, identity);
  run("gem", ["build", "hxruby.gemspec", "--output", outPath], tempRoot);
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log(outPath);
