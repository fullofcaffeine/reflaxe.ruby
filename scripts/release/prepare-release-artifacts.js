#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const { mkdirSync, readFileSync, readdirSync, rmSync, statSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { identityFromArgs } = require("./release-identity");
const { sha256File } = require("./artifact-utils");

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
const head = run("git", ["rev-parse", "HEAD"]).trim();
if (identity.sourceSha !== head) throw new Error(`Release source SHA ${identity.sourceSha} must equal checked-out HEAD ${head}`);

const dist = join(root, "dist");
rmSync(dist, { force: true, recursive: true });
mkdirSync(dist, { recursive: true });

const args = [identity.version, identity.gitTag, identity.sourceSha];
run("node", ["scripts/release/build-haxelib-package.js", ...args]);
run("node", ["scripts/release/build-gem-package.js", ...args]);

const expectedOutputs = [
  "hxruby-release.gem",
  "hxruby-release.gem.sha256.json",
  "reflaxe.ruby-release.zip",
  "reflaxe.ruby-release.zip.sha256.json",
];
const actualOutputs = readdirSync(dist).sort();
if (JSON.stringify(actualOutputs) !== JSON.stringify(expectedOutputs)) {
  throw new Error(`Release preparation output mismatch: ${JSON.stringify(actualOutputs)}`);
}
for (const sidecarName of expectedOutputs.filter((name) => name.endsWith(".sha256.json"))) {
  const sidecar = JSON.parse(readFileSync(join(dist, sidecarName), "utf8"));
  const artifactName = sidecarName.slice(0, -".sha256.json".length);
  const artifactPath = join(dist, artifactName);
  const expectedHostedName = artifactName === "reflaxe.ruby-release.zip"
    ? `reflaxe.ruby-${identity.version}.zip`
    : `hxruby-${identity.version}.gem`;
  if (sidecar.version !== identity.version || sidecar.gitTag !== identity.gitTag || sidecar.sourceSha !== identity.sourceSha) {
    throw new Error(`Release sidecar identity mismatch: ${sidecarName}`);
  }
  if (
    sidecar.localFilename !== artifactName ||
    sidecar.hostedFilename !== expectedHostedName ||
    sidecar.bytes !== statSync(artifactPath).size ||
    sidecar.sha256 !== sha256File(artifactPath)
  ) {
    throw new Error(`Release sidecar artifact mismatch: ${sidecarName}`);
  }
}

// This is the last pre-tag gate: inspect both embedded package identities and the exact four
// upload candidates while the release can still fail without creating or pushing a version tag.
run("node", ["scripts/release/release-hosting.mjs", "local", identity.version, identity.gitTag, identity.sourceSha]);

if (trackedDiff() !== before) {
  throw new Error("Release preparation changed tracked checkout files");
}

console.log(`[release-prepare] OK: ${identity.gitTag} from ${identity.sourceSha}`);
