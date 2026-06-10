#!/usr/bin/env node

const { existsSync, mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");

const root = resolve(__dirname, "..", "..");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const gemName = `hxruby-${packageJson.version}.gem`;
const gemPath = join(root, "dist", gemName);

function fail(message) {
  console.error(`[gem-package] ERROR: ${message}`);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
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

run("node", ["scripts/release/build-gem-package.js"]);

const tempRoot = mkdtempSync(join(tmpdir(), "hxruby-gem."));
try {
  run("gem", ["unpack", gemPath, "--target", tempRoot]);
  const unpackedRoot = join(tempRoot, `hxruby-${packageJson.version}`);

  for (const required of [
    "haxelib.json",
    "hxruby.gemspec",
    "lib/hxruby.rb",
    "lib/hxruby/tasks.rb",
    "runtime/hxruby/core.rb",
    "runtime/hxruby/data_define.rb",
    "runtime/hxruby/hx_exception.rb",
    "scripts/rails/generate-routes.js",
    "scripts/rails/scaffold.js",
  ]) {
    if (!existsSync(join(unpackedRoot, required))) {
      fail(`gem missing required entry: ${required}`);
    }
  }

  const runtimeCheck = [
    "require 'hxruby'",
    `abort 'version mismatch' unless HXRuby::VERSION == ${JSON.stringify(packageJson.version)}`,
    "abort 'stringify mismatch' unless HXRuby.stringify([1, 2]) == '[1, 2]'",
    "raise HxException.new({ 'message' => 'boom' }) rescue (ex = $!)",
    "abort 'exception mismatch' unless ex.message == '{\"message\"=>\"boom\"}'",
  ].join("; ");
  run("ruby", ["-I", join(unpackedRoot, "lib"), "-e", runtimeCheck]);

  const tasksCheck = [
    "require 'rake'",
    "require 'hxruby/tasks'",
    "expected = %w[hxruby:compile hxruby:watch hxruby:gen:model hxruby:gen:routes]",
    "names = Rake::Task.tasks.map(&:name)",
    "missing = expected - names",
    "abort \"missing tasks: #{missing.join(', ')}\" unless missing.empty?",
  ].join("; ");
  run("ruby", ["-I", join(unpackedRoot, "lib"), "-e", tasksCheck]);
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log(`[gem-package] OK: ${gemName}`);
