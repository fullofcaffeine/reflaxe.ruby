#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const sourceDir = join(root, "test", ".generated", "rails_concern_src");
const outputDir = join(root, "test", ".generated", "rails_concern");
const requireRails = process.env.REQUIRE_RAILS === "1" || process.env.CI_REQUIRE_RAILS === "1";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(sourceDir, { force: true, recursive: true });
rmSync(outputDir, { force: true, recursive: true });
mkdirSync(sourceDir, { recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for rails_concern.");
  process.exit(1);
}

writeFileSync(join(sourceDir, "Trackable.hx"), [
  "@:rubyConcern(\"Trackable\")",
  "class Trackable {",
  "\tpublic function trackingLabel():String {",
  "\t\treturn \"tracked\";",
  "\t}",
  "",
  "\tpublic static function lookupLabel(value:String):String {",
  "\t\treturn \"lookup:\" + value;",
  "\t}",
  "}",
  "",
].join("\n"));

writeFileSync(join(sourceDir, "Main.hx"), [
  "class Main {",
  "\tstatic function main() {",
  "\t\tvar concern:Class<Trackable> = Trackable;",
  "\t\tSys.println(concern != null);",
  "\t}",
  "}",
  "",
].join("\n"));

compile();
assertConcernShape();
writeRuntimeProbe();
runRailsBackedRuntimeIfAvailable();

function compile() {
  run("haxe", [
    "-D",
    `ruby_output=${outputDir}`,
    "-D",
    "reflaxe_runtime",
    "-cp",
    join(root, "src"),
    "-cp",
    sourceDir,
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  ]);
}

function assertConcernShape() {
  for (const file of ["hxruby/core.rb", "main.rb", "run.rb", "trackable.rb"]) {
    const fullPath = join(outputDir, file);
    if (!existsSync(fullPath)) {
      console.error(`Expected Rails concern output file missing: ${file}`);
      process.exit(1);
    }
  }

  const concernRuby = readFileSync(join(outputDir, "trackable.rb"), "utf8");
  for (const expected of [
    'require "active_support/concern"',
    "module Trackable",
    "extend ActiveSupport::Concern",
    "def tracking_label()",
    "class_methods do",
    "def lookup_label(value",
  ]) {
    if (!concernRuby.includes(expected)) {
      console.error(`Expected Haxe-authored concern output missing: ${expected}`);
      console.error(concernRuby);
      process.exit(1);
    }
  }
  if (concernRuby.includes("class Trackable")) {
    console.error("Haxe-authored concern emitted as a Ruby class.");
    process.exit(1);
  }
}

function writeRuntimeProbe() {
  writeFileSync(join(outputDir, "rails_concern_runtime.rb"), [
    "$LOAD_PATH.unshift(__dir__)",
    'require "rails"',
    'require "active_model"',
    'require "action_controller/railtie"',
    'require_relative "trackable"',
    "",
    "class RailsConcernRuntimeApp < Rails::Application",
    "  config.eager_load = false",
    "  config.secret_key_base = \"rails-concern-runtime\"",
    "end",
    "",
    "class RuntimeModel",
    "  include ActiveModel::Model",
    "  include Trackable",
    "end",
    "",
    "class RuntimeController < ActionController::Base",
    "  include Trackable",
    "end",
    "",
    "puts RuntimeModel.new.tracking_label",
    'puts RuntimeModel.lookup_label("model")',
    "puts RuntimeController.new.tracking_label",
    'puts RuntimeController.lookup_label("controller")',
    "",
  ].join("\n"));
}

function runRailsBackedRuntimeIfAvailable() {
  const railsProbe = run("ruby", [
    "-e",
    'require "rails"; require "active_model"; require "action_controller/railtie"; require "active_support/concern"',
  ], { allowFailure: true });

  if (railsProbe.status !== 0) {
    const message = "Rails/ActiveSupport gems are not available; skipped Rails-backed concern runtime pass.";
    if (requireRails) {
      process.stdout.write(railsProbe.stdout);
      process.stderr.write(railsProbe.stderr);
      console.error(`[rails-concern] ${message}`);
      process.exit(railsProbe.status ?? 1);
    }
    console.log(`[rails-concern] ${message}`);
    console.log("[rails-concern] Static concern shape checks passed.");
    console.log("[rails-concern] Set REQUIRE_RAILS=1 after installing Rails gems to make this lane mandatory.");
    return;
  }

  const actual = run("ruby", [join(outputDir, "rails_concern_runtime.rb")]).stdout;
  const expected = [
    "tracked",
    "lookup:model",
    "tracked",
    "lookup:controller",
    "",
  ].join("\n");

  if (actual !== expected) {
    console.error("rails_concern runtime stdout mismatch");
    console.error(`expected: ${JSON.stringify(expected)}`);
    console.error(`actual:   ${JSON.stringify(actual)}`);
    process.exit(1);
  }
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}
