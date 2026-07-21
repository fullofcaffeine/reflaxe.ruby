#!/usr/bin/env node

// Keeps the real database proof independently runnable: ordinary compiler
// matrices can compile the fixture without Rails, while REQUIRE_RAILS=1 makes
// the verified ActiveRecord/SQLite execution mandatory in Rails runtime CI.
const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const sourceDir = join(root, "test", "fixtures", "active_record_result_runtime");
const outputDir = join(root, "test", ".generated", "active_record_result_runtime");
const requireRails = process.env.REQUIRE_RAILS === "1" || process.env.CI_REQUIRE_RAILS === "1";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile the ActiveRecord result runtime fixture through Reflaxe.");
  process.exit(1);
}

const runtimeArgs = [join(sourceDir, "runtime.rb"), outputDir];
const dependencyProbe = run("ruby", ["-e", 'require "active_record"; require "sqlite3"'], { allowFailure: true });
let result;
if (dependencyProbe.status === 0) {
  result = run("ruby", runtimeArgs);
} else if (!requireRails) {
  console.log("[active-record-results] ActiveRecord/SQLite is unavailable; skipped runtime execution after compiling the fixture.");
  console.log("[active-record-results] Set REQUIRE_RAILS=1 to install the verified dependencies and make execution mandatory.");
  process.exit(0);
} else {
  const supportMatrix = JSON.parse(readFileSync(join(root, "lib", "hxruby", "support_matrix.json"), "utf8"));
  const railsVersion = supportMatrix.railsHx.verifiedRuntime.railsVersion;
  const gemfile = join(outputDir, "Gemfile");
  mkdirSync(outputDir, { recursive: true });
  writeFileSync(gemfile, [
    'source "https://rubygems.org"',
    "",
    `gem "activerecord", "${railsVersion}"`,
    'gem "sqlite3", "~> 2.9", ">= 2.9.5"',
    "",
  ].join("\n"));
  const env = { ...process.env, BUNDLE_GEMFILE: gemfile };
  const bundleCheck = run("bundle", ["check"], { allowFailure: true, env });
  if (bundleCheck.status !== 0) {
    console.log("[active-record-results] Installing the verified ActiveRecord/SQLite bundle because REQUIRE_RAILS=1.");
    run("bundle", ["install"], { env });
  }
  result = run("bundle", ["exec", "ruby", ...runtimeArgs], { env });
}

const expected = "true\ntrue\ntrue\ntrue\ntrue\ntrue\ntrue\n";
if (result.stdout !== expected) {
  console.error("ActiveRecord result adapter runtime output mismatch.");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(result.stdout)}`);
  process.exit(1);
}
console.log("[active-record-results] OK: seven populated-database adapter and map contracts passed.");

function compileWithFirstAvailableReflaxe() {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${outputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      join(root, "examples", "active_record_model"),
      "-cp",
      sourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "ActiveRecordResultRuntimeMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      return result;
    }
  }
  return null;
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    env: options.env ?? process.env,
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}
