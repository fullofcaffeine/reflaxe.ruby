#!/usr/bin/env node

const { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { tmpdir } = require("node:os");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const tempRoot = mkdtempSync(join(tmpdir(), "railshx-app."));

try {
  run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "app.rb"),
    "--output",
    tempRoot,
    "--name",
    "TypedTasks",
    "--source",
    "app_haxe",
    "--main",
    "Boot",
    "--rails-output-root",
    "engines/blog/app/haxe_gen",
  ]);

  expectFile("build.hxml", [
    "-lib reflaxe.ruby",
    "-D ruby_output=.",
    "-D reflaxe_ruby_rails",
    "-D reflaxe_ruby_rails_output_root=engines/blog/app/haxe_gen",
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
  expectFile("bin/railshx-prod", [
    'export RAILS_ENV="${RAILS_ENV:-production}"',
    'export SECRET_KEY_BASE_DUMMY="${SECRET_KEY_BASE_DUMMY:-1}"',
    "bundle exec rake hxruby:production",
  ]);
  expectManifest([
    ["app_haxe/Boot.hx", "haxe_source", "hxruby:install"],
    ["app_haxe/routes/Routes.hx", "haxe_source", "hxruby:install"],
    ["config/importmap.rb", "rails_config", "hxruby:install"],
    ["bin/railshx-dev", "bin_script", "hxruby:install"],
  ]);

  run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "app.rb"),
    "--output",
    tempRoot,
    "--name",
    "TypedTasks",
    "--source",
    "app_haxe",
    "--main",
    "Boot",
    "--rails-output-root",
    "engines/blog/app/haxe_gen",
  ]);

  const collisionRoot = mkdtempSync(join(tmpdir(), "railshx-app-collision."));
  try {
    writeFileSync(join(collisionRoot, "build.hxml"), "# hand-written build file\n");
    const overwrite = spawnSync("ruby", [
      "-I",
      join(root, "lib"),
      join(root, "scripts", "rails", "app.rb"),
      "--output",
      collisionRoot,
    ], {
      cwd: root,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    if (overwrite.status === 0 || !overwrite.stderr.includes("Refusing to overwrite non-RailsHx-owned file")) {
      process.stdout.write(overwrite.stdout);
      process.stderr.write(overwrite.stderr);
      fail("rails app generator did not protect non-owned existing files");
    }
  } finally {
    rmSync(collisionRoot, { force: true, recursive: true });
  }

  writeFileSync(join(tempRoot, "hand_written.rb"), "# app-owned file\n");
  run("ruby", [
    "-I",
    join(root, "lib"),
    "-e",
    "require 'hxruby/generators/common'; HXRuby::Generators::Common.clean_owned_outputs(ARGV.fetch(0))",
    tempRoot,
  ]);
  if (existsSync(join(tempRoot, "build.hxml")) || existsSync(join(tempRoot, "app_haxe", "Boot.hx"))) {
    fail("manifest cleanup did not remove generated outputs");
  }
  if (!existsSync(join(tempRoot, "hand_written.rb"))) {
    fail("manifest cleanup removed a non-owned file");
  }
  const cleanedManifest = JSON.parse(readFileSync(join(tempRoot, ".railshx", "manifest.json"), "utf8"));
  if (cleanedManifest.outputs.length !== 0) {
    fail("manifest cleanup did not clear output entries");
  }
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log("[rails-app-generator] OK");

function expectManifest(entries) {
  const manifestPath = join(tempRoot, ".railshx", "manifest.json");
  if (!existsSync(manifestPath)) {
    fail("missing RailsHx manifest");
  }
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  if (manifest.version !== 1) {
    fail(`unexpected manifest version: ${manifest.version}`);
  }
  for (const [output, kind, source] of entries) {
    const entry = manifest.outputs.find((candidate) => candidate.output === output);
    if (!entry) {
      fail(`manifest missing output: ${output}`);
    }
    if (entry.kind !== kind || entry.source !== source || !entry.sha256) {
      fail(`manifest entry for ${output} has wrong metadata`);
    }
  }
}

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
