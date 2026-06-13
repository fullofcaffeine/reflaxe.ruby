#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "action_controller_params");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
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

rmSync(outputDir, { force: true, recursive: true });

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile action_controller_params through Reflaxe.");
  process.exit(1);
}

for (const file of [
  "app/haxe_gen/controllers/todos_controller.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected ActionController output file missing: ${fullPath}`);
    process.exit(1);
  }
}

const controllerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "controllers", "todos_controller.rb"), "utf8");
for (const expected of [
  /require "action_controller\/railtie"/,
  /module Controllers/,
  /class TodosController < ActionController::Base/,
  /before_action :authenticate_user, only: \[:create\]/,
  /after_action :audit_response, only: \[:create\]/,
  /before_action :load_tenant, except: \[:index\]/,
  /def authenticate_user\(\)/,
  /def audit_response\(\)/,
  /def load_tenant\(\)/,
  /attrs__hx\d+ = self\.params\(\)\.require\("todo"\)\.permit\(\[:title, :is_completed, \{metadata: \[:source, :priority\]\}, \{tags: \[\]\}\]\)/,
  /request_method__hx\d+ = self\.request\(\)\.request_method\(\)/,
  /request_path__hx\d+ = self\.request\(\)\.path\(\)/,
  /current_status__hx\d+ = self\.response\(\)\.status\(\)/,
  /self\.flash\(\)\[:notice\] = "Todo queued"/,
  /self\.session\(\)\[:last_todo_title\] = attrs__hx\d+/,
  /remembered__hx\d+ = self\.session\(\)\[:last_todo_title\]/,
  /self\.cookies\(\)\[:todo_filter\] = "open"/,
  /self\.cookies\(\)\.delete\(:stale_filter\)/,
  /self\.render\(json: attrs__hx\d+, status: :created\)/,
  /self\.redirect_to\(action: "index"\)/,
  /self\.head\(:no_content\)/,
]) {
  if (!expected.test(controllerRuby)) {
    console.error(`ActionController output missing expected line: ${expected}`);
    process.exit(1);
  }
}

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
      join(root, "examples", "action_controller_params"),
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "Main",
    ], { allowFailure: true });
    if (result.status === 0) {
      return result;
    }
  }
  return null;
}
