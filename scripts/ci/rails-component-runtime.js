#!/usr/bin/env node

const { mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const runtimeDir = join(root, "test", ".generated", "rails_component_runtime");
const gemfile = join(runtimeDir, "Gemfile");
const supportMatrix = JSON.parse(readFileSync(join(root, "lib", "hxruby", "support_matrix.json"), "utf8"));
const railsVersion = supportMatrix.railsHx.verifiedRuntime.railsVersion;

rmSync(runtimeDir, { force: true, recursive: true });
mkdirSync(runtimeDir, { recursive: true });
writeFileSync(gemfile, [
  'source "https://rubygems.org"',
  "",
  `gem "rails", "${railsVersion}"`,
  "",
].join("\n"));

const env = {
  ...process.env,
  BUNDLE_GEMFILE: gemfile,
  REQUIRE_RAILS: "1",
};

const bundleCheck = run("bundle", ["check"], { allowFailure: true, env });
if (bundleCheck.status !== 0) {
  run("bundle", ["install"], { env });
}

for (const script of [
  "scripts/ci/active-support-facades-smoke.js",
  "scripts/ci/instrumentation-smoke.js",
  "scripts/ci/rails-concern-smoke.js",
  "scripts/ci/rails-generators-smoke.js",
]) {
  run("bundle", ["exec", "node", script], { env });
}

console.log(`[rails-component-runtime] Rails ${railsVersion} ActiveSupport/concern/generator paths OK`);

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    env: options.env ?? process.env,
    stdio: options.allowFailure ? ["ignore", "pipe", "pipe"] : "inherit",
  });
  if (result.status !== 0 && !options.allowFailure) {
    if (result.stdout) process.stdout.write(result.stdout);
    if (result.stderr) process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}
