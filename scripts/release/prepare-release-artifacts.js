#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const { resolve } = require("node:path");
const { identityFromArgs } = require("./release-identity");

const root = resolve(__dirname, "..", "..");
const identity = identityFromArgs(process.argv.slice(2));

function run(command, args) {
  const result = spawnSync(command, args, { cwd: root, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result.stdout;
}

function trackedDiff() {
  return `${run("git", ["diff", "--binary"])}${run("git", ["diff", "--cached", "--binary"])}`;
}

const before = trackedDiff();
if (before.length > 0) {
  throw new Error("Release preparation requires a checkout with no tracked diff");
}

const args = [identity.version, identity.gitTag, identity.sourceSha];
run("node", ["scripts/release/build-haxelib-package.js", ...args]);
run("node", ["scripts/release/build-gem-package.js", ...args]);

if (trackedDiff() !== before) {
  throw new Error("Release preparation changed tracked checkout files");
}

console.log(`[release-prepare] OK: ${identity.gitTag} from ${identity.sourceSha}`);
