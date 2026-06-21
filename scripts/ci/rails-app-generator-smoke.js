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
    "import controllers.HomeController;",
    "import routes.AppRoutes;",
    "import views.ApplicationLayoutView;",
    "import views.HomeIndexView;",
  ]);
  expectFile("app_haxe/controllers/HomeController.hx", [
    "package controllers;",
    "@:railsController",
    "class HomeController extends rails.action_controller.Base",
    "ViewMacro.renderTemplateWithLayout",
    "Template.layout(ApplicationLayoutView)",
  ]);
  expectFile("app_haxe/views/ApplicationLayoutView.hx", [
    "package views;",
    '@:railsTemplate("layouts/application")',
    '@:railsTemplateAst("render")',
    "<csrf_meta_tags />",
    "<rails_yield />",
  ]);
  expectFile("app_haxe/views/HomeIndexView.hx", [
    "package views;",
    '@:railsTemplate("controllers/home/index")',
    '@:railsTemplateAst("render")',
    "${locals.appName}",
    "bundle exec rake hxruby:start:watch",
  ]);
  expectFile("app_haxe/routes/AppRoutes.hx", [
    "package routes;",
    "@:railsRoutes",
    "root(to(HomeController, index));",
  ]);
  expectFile("build-client.hxml", [
    "-cp ${HXRUBY_GEM_ROOT}/std",
    "-lib genes",
    "--macro genes.Generator.use()",
    "-main client.Boot",
    "-js app/javascript/railshx/app.js",
    "-D js-unflatten",
  ]);
  expectFile(".haxerc", [
    '"version": "4.3.7"',
    '"resolveLibs": "scoped"',
  ]);
  expectFile("haxe_libraries/genes.hxml", [
    "${HXRUBY_GEM_ROOT}/vendor/genes/src",
    "-lib helder.set",
    "-D genes=0.4.14",
  ]);
  expectFile("haxe_libraries/helder.set.hxml", [
    "haxelib:/helder.set#0.3.1",
    "-D helder.set=0.3.1",
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
    'pin_all_from "app/javascript/railshx", under: "railshx"',
  ]);
  expectFile("app_haxe/routes/Routes.hx", [
    "package routes;",
    "extern class Routes",
  ]);
  expectFile("docs/railshx/gem_layers.md", [
    "RailsHx Gem Layers",
    "Run a deterministic inventory before asking an LLM for help.",
    "bundle add devise",
    "bundle exec rake hxruby:test",
    "bin/rails generate hxruby:adopt --gem devise --discover",
    "bin/rails generate hxruby:adopt --gem devise --write contracts",
    "railshx-devisehx-gpt55-prompt.md",
    "Uncertain APIs should stay review-marked",
    "login/logout/login-as-guest",
  ]);
  expectFile("lib/tasks/hxruby.rake", [
    'require "hxruby/tasks"',
  ]);
  expectFile("AGENTS.md", [
    "hxruby:db:migrate",
    "hxruby:db:prepare",
    "hxruby:test",
    "hxruby:rails TASK=zeitwerk:check",
    "request.format().json()",
    "response.status()",
    "Target-shaped Haxe is valid when intentional",
  ]);
  expectFile("Procfile.railshx.dev", [
    "rails: bundle exec rails server",
    "haxe: bundle exec rake hxruby:watch",
    "haxe_client: bundle exec rake hxruby:watch:client",
  ]);
  expectFile("bin/railshx-dev", [
    "foreman start -f Procfile.railshx.dev",
    "bundle exec rake hxruby:start:watch",
  ]);
  expectFile("bin/railshx-prod", [
    'export RAILS_ENV="${RAILS_ENV:-production}"',
    'export SECRET_KEY_BASE_DUMMY="${SECRET_KEY_BASE_DUMMY:-1}"',
    "bundle exec rake hxruby:production",
  ]);
  expectManifest([
    ["app_haxe/Boot.hx", "haxe_source", "hxruby:install"],
    ["app_haxe/controllers/HomeController.hx", "haxe_source", "hxruby:install"],
    ["app_haxe/routes/AppRoutes.hx", "haxe_source", "hxruby:install"],
    ["app_haxe/routes/Routes.hx", "haxe_source", "hxruby:install"],
    ["app_haxe/views/ApplicationLayoutView.hx", "haxe_source", "hxruby:install"],
    ["app_haxe/views/HomeIndexView.hx", "haxe_source", "hxruby:install"],
    [".haxerc", "haxe_config", "hxruby:install"],
    ["haxe_libraries/genes.hxml", "haxe_dependency", "hxruby:install"],
    ["haxe_libraries/helder.set.hxml", "haxe_dependency", "hxruby:install"],
    ["docs/railshx/gem_layers.md", "docs", "hxruby:install"],
    ["config/importmap.rb", "rails_config", "hxruby:install"],
    ["bin/railshx-dev", "bin_script", "hxruby:install"],
  ]);
  compileGeneratedStarter();

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

  expectRouteMode("snippet", {
    appRoutes: false,
    routesExtern: true,
    snippetDoc: true,
  });
  expectRouteMode("rails", {
    appRoutes: false,
    routesExtern: true,
    snippetDoc: false,
  });
  expectRouteMode("none", {
    appRoutes: false,
    routesExtern: false,
    snippetDoc: false,
  });

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

function expectRouteMode(mode, expected) {
  const routeModeRoot = mkdtempSync(join(tmpdir(), `railshx-app-${mode}.`));
  try {
    run("ruby", [
      "-I",
      join(root, "lib"),
      join(root, "scripts", "rails", "app.rb"),
      "--output",
      routeModeRoot,
      "--name",
      "RouteMode",
      "--routes",
      mode,
    ]);
    const appRoutes = existsSync(join(routeModeRoot, "src_haxe", "routes", "AppRoutes.hx"));
    const routesExtern = existsSync(join(routeModeRoot, "src_haxe", "routes", "Routes.hx"));
    const snippetDoc = existsSync(join(routeModeRoot, "docs", "railshx", "routes.md"));
    if (appRoutes !== expected.appRoutes) {
      fail(`--routes=${mode} AppRoutes presence mismatch`);
    }
    if (routesExtern !== expected.routesExtern) {
      fail(`--routes=${mode} Routes.hx presence mismatch`);
    }
    if (snippetDoc !== expected.snippetDoc) {
      fail(`--routes=${mode} route snippet doc presence mismatch`);
    }
  } finally {
    rmSync(routeModeRoot, { force: true, recursive: true });
  }
}

function compileGeneratedStarter() {
  const original = readFileSync(join(tempRoot, "build.hxml"), "utf8");
  const localBuild = original
    .split(/\r?\n/)
    .filter((line) => line !== "-lib reflaxe.ruby")
    .join("\n");
  writeFileSync(join(tempRoot, "build.local.hxml"), `${localBuild}\n`);
  run("haxe", [
    "build.local.hxml",
    "-cp",
    join(root, "std"),
    "-cp",
    join(root, "src"),
    "-cp",
    join(root, "vendor", "reflaxe", "src"),
  ], { cwd: tempRoot });

  run("haxe", ["build-client.hxml", "-cp", join(root, "std")], {
    cwd: tempRoot,
    env: { ...process.env, HXRUBY_GEM_ROOT: root },
  });
  run("ruby", [
    "-I",
    join(root, "lib"),
    "-e",
    "require 'hxruby/tasks'; HXRuby::Tasks.rewrite_importmap_module_imports('app/javascript/railshx', 'railshx')",
  ], { cwd: tempRoot });
  if (!existsSync(join(tempRoot, "app", "javascript", "railshx", "app.js"))) {
    fail("generated client build did not emit app/javascript/railshx/app.js");
  }
  if (!existsSync(join(tempRoot, "app", "javascript", "railshx", "client", "Boot.js"))) {
    fail("generated client build did not emit Genes module graph");
  }
  expectFile("app/javascript/railshx/app.js", [
    'from "railshx/genes/Register"',
    'from "railshx/client/Boot"',
  ]);
  expectFile("app/javascript/railshx/client/Boot.js", [
    "static async readySoon",
    "await Async.delay(50)",
    'data-railshx-client"',
  ]);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
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
