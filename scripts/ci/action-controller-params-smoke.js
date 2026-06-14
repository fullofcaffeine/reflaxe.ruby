#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "action_controller_params");
const invalidSourceDir = join(root, "test", ".generated", "action_controller_params_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "action_controller_params_invalid_out");
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
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });

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
  /self\.respond_to\(\) do \|format__hx\d+\|/,
  /format__hx\d+\.html\(\) \{ gthis__hx\d+\.redirect_to\(action: "index"\) \}/,
  /format__hx\d+\.json\(\) \{ gthis__hx\d+\.render\(json: attrs__hx\d+, status: :created\) \}/,
  /self\.head\(:no_content\)/,
]) {
  if (!expected.test(controllerRuby)) {
    console.error(`ActionController output missing expected line: ${expected}`);
    process.exit(1);
  }
}

writeInvalidFixtures();
const invalidRender = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidRenderMain",
  allowFailure: true,
});
if (invalidRender == null || invalidRender.status === 0) {
  console.error("Expected invalid ActionController render options compile to fail.");
  process.exit(1);
}
if (!/Status|RenderOptions|Cannot unify|String should be rails\.action_controller\.Status/.test(invalidRender.stderr + invalidRender.stdout)) {
  process.stdout.write(invalidRender.stdout);
  process.stderr.write(invalidRender.stderr);
  console.error("Invalid ActionController render options failed for an unexpected reason.");
  process.exit(1);
}

const invalidRedirect = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidRedirectMain",
  allowFailure: true,
});
if (invalidRedirect == null || invalidRedirect.status === 0) {
  console.error("Expected invalid ActionController redirect options compile to fail.");
  process.exit(1);
}
if (!/Status|RedirectOptions|Cannot unify|String should be rails\.action_controller\.Status/.test(invalidRedirect.stderr + invalidRedirect.stdout)) {
  process.stdout.write(invalidRedirect.stdout);
  process.stderr.write(invalidRedirect.stderr);
  console.error("Invalid ActionController redirect options failed for an unexpected reason.");
  process.exit(1);
}

const invalidResponder = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidResponderMain",
  allowFailure: true,
});
if (invalidResponder == null || invalidResponder.status === 0) {
  console.error("Expected invalid ActionController responder block compile to fail.");
  process.exit(1);
}
if (!/Void -> Void|Responder|String should be/.test(invalidResponder.stderr + invalidResponder.stdout)) {
  process.stdout.write(invalidResponder.stdout);
  process.stderr.write(invalidResponder.stderr);
  console.error("Invalid ActionController responder block failed for an unexpected reason.");
  process.exit(1);
}

function compileWithFirstAvailableReflaxe(options = {}) {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${options.outputDir ?? outputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      options.classPath ?? join(root, "examples", "action_controller_params"),
      "-cp",
      join(root, "examples", "action_controller_params"),
      "-cp",
      join(root, "std"),
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      options.main ?? "Main",
    ], { allowFailure: true });
    if (result.status === 0 || options.allowFailure) {
      return result;
    }
  }
  return null;
}

function writeInvalidFixtures() {
  mkdirSync(invalidSourceDir, { recursive: true });
  writeFileSync(join(invalidSourceDir, "InvalidRenderMain.hx"), [
    "class InvalidRenderMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller = new controllers.TodosController();",
    "\t\tcontroller.render({plain: \"bad\", status: \"created\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidRedirectMain.hx"), [
    "class InvalidRedirectMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller = new controllers.TodosController();",
    "\t\tcontroller.redirectToOptions({action: \"index\", status: \"see_other\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidResponderMain.hx"), [
    "class InvalidResponderMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller = new controllers.TodosController();",
    "\t\tcontroller.respondTo(function(format) {",
    "\t\t\tformat.json(\"bad\");",
    "\t\t});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}
