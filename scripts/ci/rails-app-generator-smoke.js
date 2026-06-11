#!/usr/bin/env node

const { existsSync, mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { tmpdir } = require("node:os");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const tempRoot = mkdtempSync(join(tmpdir(), "railshx-app."));

try {
  run("node", [
    join(root, "scripts", "rails", "app.js"),
    "--output",
    tempRoot,
    "--name",
    "TypedTasks",
    "--source",
    "app_haxe",
    "--main",
    "Boot",
  ]);

  expectFile("build.hxml", [
    "-lib reflaxe.ruby",
    "-D ruby_output=.",
    "-D reflaxe_ruby_rails",
    "-cp app_haxe",
    "-main Boot",
  ]);
  expectFile("app_haxe/Boot.hx", [
    "class Boot",
    "TypedTasks RailsHx compile",
  ]);
  expectFile("build-client.hxml", [
    "path/to/reflaxe.ruby/std",
    "-main client.Boot",
    "-js app/javascript/railshx/app.js",
  ]);
  expectFile("app_haxe/client/Boot.hx", [
    "package client;",
    "TypedTasks RailsHx client boot",
  ]);
  expectFile("app/javascript/application.js", [
    'import "@hotwired/turbo-rails"',
    'import "railshx/app"',
  ]);
  expectFile("app/assets/stylesheets/application.css", [
    "RailsHx app stylesheet",
  ]);
  expectFile("config/importmap.rb", [
    'pin "@hotwired/turbo-rails", to: "turbo.min.js"',
    'pin "railshx/app", to: "railshx/app.js"',
  ]);
  expectFile("app_haxe/routes/Routes.hx", [
    "package routes;",
    "extern class Routes",
  ]);
  expectFile("lib/tasks/hxruby.rake", [
    'require "hxruby/tasks"',
  ]);
  expectFile("Procfile.railshx.dev", [
    "rails: bundle exec rails server",
    "haxe: bundle exec rake hxruby:watch",
    "haxe_client: bundle exec rake hxruby:watch:client",
  ]);
  expectFile("bin/railshx-dev", [
    "foreman start -f Procfile.railshx.dev",
    "bundle exec rake hxruby:watch",
    "bundle exec rake hxruby:watch:client",
  ]);

  const overwrite = spawnSync("node", [
    join(root, "scripts", "rails", "app.js"),
    "--output",
    tempRoot,
  ], {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (overwrite.status === 0 || !overwrite.stderr.includes("Refusing to overwrite")) {
    process.stdout.write(overwrite.stdout);
    process.stderr.write(overwrite.stderr);
    fail("rails app generator did not protect existing files");
  }
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log("[rails-app-generator] OK");

function expectFile(relativePath, expectedParts) {
  const path = join(tempRoot, relativePath);
  if (!existsSync(path)) {
    fail(`missing generated file: ${relativePath}`);
  }
  const content = readFileSync(path, "utf8");
  for (const expected of expectedParts) {
    if (!content.includes(expected)) {
      fail(`${relativePath} missing expected content: ${expected}`);
    }
  }
}

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
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

function fail(message) {
  console.error(`[rails-app-generator] ERROR: ${message}`);
  process.exit(1);
}
