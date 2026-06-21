#!/usr/bin/env node

const {
  copyFileSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "action_controller_params");
const runtimeAppDir = join(root, "test", ".generated", "action_controller_params_rails");
const invalidSourceDir = join(root, "test", ".generated", "action_controller_params_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "action_controller_params_invalid_out");
const requireRails = process.env.REQUIRE_RAILS === "1" || process.env.CI_REQUIRE_RAILS === "1";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
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
  /protect_from_forgery with: :exception, prepend: true, except: \[:index\]/,
  /before_action :authenticate_user, only: \[:create\]/,
  /after_action :audit_response, only: \[:create\]/,
  /before_action :load_tenant, except: \[:index\]/,
  /rescue_from ActiveRecord::RecordNotFound, with: :not_found/,
  /rescue_from ActionController::InvalidAuthenticityToken, with: :csrf_failure/,
  /def authenticate_user\(\)/,
  /def audit_response\(\)/,
  /def load_tenant\(\)/,
  /def not_found\(e__hx\d+\)/,
  /def csrf_failure\(e__hx\d+\)/,
  /self\.render\(plain: "Invalid CSRF token", status: :forbidden\)/,
  /attrs__hx\d+ = self\.params\(\)\.require\("todo"\)\.permit\(\[:title, :is_completed, \{metadata: \[:source, :priority\]\}, \{tags: \[\]\}\]\)/,
  /request_method__hx\d+ = self\.request\(\)\.request_method\(\)/,
  /request_path__hx\d+ = self\.request\(\)\.path\(\)/,
  /request_format__hx\d+ = self\.request\(\)\.format\(\)/,
  /wants_json__hx\d+ = request_format__hx\d+\.json\?\(\)/,
  /request_format_name__hx\d+ = request_format__hx\d+\.to_s\(\)/,
  /request_formats__hx\d+ = self\.request\(\)\.formats\(\)/,
  /content_mime_type__hx\d+ = self\.request\(\)\.content_mime_type\(\)/,
  /request_media_type__hx\d+ = self\.request\(\)\.media_type\(\)/,
  /request_variant__hx\d+ = self\.request\(\)\.variant\(\)/,
  /wants_phone_variant__hx\d+ = request_variant__hx\d+\.phone\?\(\)/,
  /request_variant_name__hx\d+ = request_variant__hx\d+\.to_s\(\)/,
  /current_status__hx\d+ = self\.response\(\)\.status\(\)/,
  /self\.fresh_when\(etag: "todos-create"\)/,
  /cache_is_stale__hx\d+ = self\.stale\?\(weak_etag: "todos-create", template: "controllers\/todos\/create"\)/,
  /self\.flash\(\)\[:notice\] = "Todo queued"/,
  /self\.session\(\)\[:last_todo_title\] = attrs__hx\d+/,
  /remembered__hx\d+ = self\.session\(\)\[:last_todo_title\]/,
  /self\.cookies\(\)\[:todo_filter\] = "open"/,
  /self\.cookies\(\)\.delete\(:stale_filter\)/,
  /self\.respond_to\(\) do \|format__hx\d+\|/,
  /format__hx\d+\.html\(\) \{ gthis__hx\d+\.redirect_to\(action: "index"\) \}/,
  /format__hx\d+\.json\(\) \{ gthis__hx\d+\.render\(json: attrs__hx\d+, status: :created\) \}/,
  /self\.send_file\("\/tmp\/todos\.csv", filename: "todos\.csv", type: "text\/csv", disposition: "attachment", status: :ok\)/,
  /self\.send_data\("title,is_completed\\nShip,true\\n", filename: "todos\.csv", type: "text\/csv", disposition: "inline", status: :ok\)/,
  /self\.head\(:no_content\)/,
  /def runtime_ok\(\)/,
  /self\.render\(plain: "runtime ok", status: :ok\)/,
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

const invalidSend = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidSendMain",
  allowFailure: true,
});
if (invalidSend == null || invalidSend.status === 0) {
  console.error("Expected invalid ActionController send options compile to fail.");
  process.exit(1);
}
if (!/Status|SendOptions|Cannot unify|String should be rails\.action_controller\.Status/.test(invalidSend.stderr + invalidSend.stdout)) {
  process.stdout.write(invalidSend.stdout);
  process.stderr.write(invalidSend.stderr);
  console.error("Invalid ActionController send options failed for an unexpected reason.");
  process.exit(1);
}

const invalidFreshness = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidFreshnessMain",
  allowFailure: true,
});
if (invalidFreshness == null || invalidFreshness.status === 0) {
  console.error("Expected invalid ActionController freshness options compile to fail.");
  process.exit(1);
}
if (!/FreshnessOptions|String|Int should be String|Cannot unify/.test(invalidFreshness.stderr + invalidFreshness.stdout)) {
  process.stdout.write(invalidFreshness.stdout);
  process.stderr.write(invalidFreshness.stderr);
  console.error("Invalid ActionController freshness options failed for an unexpected reason.");
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

const invalidRequestFormat = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidRequestFormatMain",
  allowFailure: true,
});
if (invalidRequestFormat == null || invalidRequestFormat.status === 0) {
  console.error("Expected invalid ActionController request format compile to fail.");
  process.exit(1);
}

const invalidRequestVariant = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidRequestVariantMain",
  allowFailure: true,
});
if (invalidRequestVariant == null || invalidRequestVariant.status === 0) {
  console.error("Expected invalid ActionController request variant compile to fail.");
  process.exit(1);
}

const invalidRequestFormats = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidRequestFormatsMain",
  allowFailure: true,
});
if (invalidRequestFormats == null || invalidRequestFormats.status === 0) {
  console.error("Expected invalid ActionController request formats compile to fail.");
  process.exit(1);
}

const invalidLifecycleMissing = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidLifecycleMissingMain",
  allowFailure: true,
});
if (invalidLifecycleMissing == null || invalidLifecycleMissing.status === 0) {
  console.error("Expected missing ActionController lifecycle compile to fail.");
  process.exit(1);
}
if (!/must declare `static final lifecycle/.test(invalidLifecycleMissing.stderr + invalidLifecycleMissing.stdout)) {
  process.stdout.write(invalidLifecycleMissing.stdout);
  process.stderr.write(invalidLifecycleMissing.stderr);
  console.error("Missing ActionController lifecycle failed for an unexpected reason.");
  process.exit(1);
}

const invalidLifecycleHandler = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidLifecycleHandlerMain",
  allowFailure: true,
});
if (invalidLifecycleHandler == null || invalidLifecycleHandler.status === 0) {
  console.error("Expected invalid ActionController lifecycle handler compile to fail.");
  process.exit(1);
}
if (!/missing controller method|before_action references/.test(invalidLifecycleHandler.stderr + invalidLifecycleHandler.stdout)) {
  process.stdout.write(invalidLifecycleHandler.stdout);
  process.stderr.write(invalidLifecycleHandler.stderr);
  console.error("Invalid ActionController lifecycle handler failed for an unexpected reason.");
  process.exit(1);
}

const invalidLifecycleAction = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidLifecycleActionMain",
  allowFailure: true,
});
if (invalidLifecycleAction == null || invalidLifecycleAction.status === 0) {
  console.error("Expected invalid ActionController lifecycle action compile to fail.");
  process.exit(1);
}
if (!/missing controller action/.test(invalidLifecycleAction.stderr + invalidLifecycleAction.stdout)) {
  process.stdout.write(invalidLifecycleAction.stdout);
  process.stderr.write(invalidLifecycleAction.stderr);
  console.error("Invalid ActionController lifecycle action failed for an unexpected reason.");
  process.exit(1);
}

const invalidLifecycleContents = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidLifecycleContentsMain",
  allowFailure: true,
});
if (invalidLifecycleContents == null || invalidLifecycleContents.status === 0) {
  console.error("Expected malformed ActionController lifecycle contents compile to fail.");
  process.exit(1);
}
if (!/lifecycle entries must be produced|lifecycle must be a Haxe block/.test(invalidLifecycleContents.stderr + invalidLifecycleContents.stdout)) {
  process.stdout.write(invalidLifecycleContents.stdout);
  process.stderr.write(invalidLifecycleContents.stderr);
  console.error("Malformed ActionController lifecycle contents failed for an unexpected reason.");
  process.exit(1);
}
const invalidForgeryProtection = compileWithFirstAvailableReflaxe({
  outputDir: invalidOutputDir,
  classPath: invalidSourceDir,
  main: "InvalidForgeryProtectionMain",
  allowFailure: true,
});
if (invalidForgeryProtection == null || invalidForgeryProtection.status === 0) {
  console.error("Expected invalid ActionController CSRF lifecycle options compile to fail.");
  process.exit(1);
}
if (!/protectFromForgery unsupported option|with expects a ForgeryProtectionStrategy/.test(invalidForgeryProtection.stderr + invalidForgeryProtection.stdout)) {
  process.stdout.write(invalidForgeryProtection.stdout);
  process.stderr.write(invalidForgeryProtection.stderr);
  console.error("Invalid ActionController CSRF lifecycle options failed for an unexpected reason.");
  process.exit(1);
}
if (!/RequestFormat|String|Cannot unify/.test(invalidRequestFormat.stderr + invalidRequestFormat.stdout)) {
  process.stdout.write(invalidRequestFormat.stdout);
  process.stderr.write(invalidRequestFormat.stderr);
  console.error("Invalid ActionController request format failed for an unexpected reason.");
  process.exit(1);
}
if (!/RequestVariant|String|Cannot unify/.test(invalidRequestVariant.stderr + invalidRequestVariant.stdout)) {
  process.stdout.write(invalidRequestVariant.stdout);
  process.stderr.write(invalidRequestVariant.stderr);
  console.error("Invalid ActionController request variant failed for an unexpected reason.");
  process.exit(1);
}

materializeRuntimeRailsApp();
syntaxCheckRuntimeRailsApp();
const bundleProbe = run("bundle", ["check"], { cwd: runtimeAppDir, allowFailure: true });
if (bundleProbe.status !== 0) {
  if (requireRails) {
    process.stdout.write("[action-controller-params] Rails bundle missing; running bundle install because REQUIRE_RAILS=1.\n");
    run("bundle", ["install"], { cwd: runtimeAppDir });
  } else {
    process.stdout.write("[action-controller-params] Rails bundle missing; skipped runtime Rails request pass.\n");
    process.stdout.write("[action-controller-params] Set REQUIRE_RAILS=1 to install app gems and make this lane mandatory.\n");
    process.exit(0);
  }
}
run("bundle", ["exec", "rails", "test"], {
  cwd: runtimeAppDir,
  env: { ...process.env, RAILS_ENV: "test" },
});

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
  writeFileSync(join(invalidSourceDir, "InvalidSendMain.hx"), [
    "class InvalidSendMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller = new controllers.TodosController();",
    "\t\tcontroller.sendData(\"bad\", {filename: \"bad.txt\", status: \"ok\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidFreshnessMain.hx"), [
    "class InvalidFreshnessMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller = new controllers.TodosController();",
    "\t\tcontroller.freshWhen({etag: 1});",
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
  writeFileSync(join(invalidSourceDir, "InvalidRequestFormatMain.hx"), [
    "class InvalidRequestFormatMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller = new controllers.TodosController();",
    "\t\tvar format:String = controller.request.format();",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidRequestVariantMain.hx"), [
    "class InvalidRequestVariantMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller = new controllers.TodosController();",
    "\t\tvar variant:String = controller.request.variant();",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidRequestFormatsMain.hx"), [
    "class InvalidRequestFormatsMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller = new controllers.TodosController();",
    "\t\tvar formats:String = controller.request.formats();",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidLifecycleMissingMain.hx"), [
    "import invalid_controllers.MissingLifecycleController;",
    "class InvalidLifecycleMissingMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller:MissingLifecycleController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidLifecycleHandlerMain.hx"), [
    "import invalid_controllers.BadLifecycleHandlerController;",
    "class InvalidLifecycleHandlerMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller:BadLifecycleHandlerController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidLifecycleActionMain.hx"), [
    "import invalid_controllers.BadLifecycleActionController;",
    "class InvalidLifecycleActionMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller:BadLifecycleActionController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidLifecycleContentsMain.hx"), [
    "import invalid_controllers.BadLifecycleContentsController;",
    "class InvalidLifecycleContentsMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller:BadLifecycleContentsController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidForgeryProtectionMain.hx"), [
    "import invalid_controllers.BadForgeryProtectionController;",
    "class InvalidForgeryProtectionMain {",
    "\tstatic function main():Void {",
    "\t\tvar controller:BadForgeryProtectionController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  mkdirSync(join(invalidSourceDir, "invalid_controllers"), { recursive: true });
  writeFileSync(join(invalidSourceDir, "invalid_controllers", "MissingLifecycleController.hx"), [
    "package invalid_controllers;",
    "",
    "@:railsController",
    "class MissingLifecycleController extends rails.action_controller.Base {",
    "\tpublic function index() {}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "invalid_controllers", "BadLifecycleHandlerController.hx"), [
    "package invalid_controllers;",
    "",
    "import rails.macros.ControllerDsl.*;",
    "",
    "@:railsController",
    "class BadLifecycleHandlerController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = {",
    "\t\tbeforeAction(missingHandler);",
    "\t}",
    "",
    "\tpublic function index() {}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "invalid_controllers", "BadLifecycleActionController.hx"), [
    "package invalid_controllers;",
    "",
    "import rails.macros.ControllerDsl.*;",
    "",
    "@:railsController",
    "class BadLifecycleActionController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = {",
    "\t\tbeforeAction(authenticateUser, {only: [missingAction]});",
    "\t}",
    "",
    "\tfunction authenticateUser() {}",
    "\tpublic function index() {}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "invalid_controllers", "BadLifecycleContentsController.hx"), [
    "package invalid_controllers;",
    "",
    "@:railsController",
    "class BadLifecycleContentsController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = {",
    "\t\t\"not a lifecycle declaration\";",
    "\t}",
    "",
    "\tpublic function index() {}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "invalid_controllers", "BadForgeryProtectionController.hx"), [
    "package invalid_controllers;",
    "",
    "import rails.action_controller.ForgeryProtectionStrategy;",
    "import rails.macros.ControllerDsl.*;",
    "",
    "@:railsController",
    "class BadForgeryProtectionController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = {",
    "\t\tprotectFromForgery({with: ForgeryProtectionStrategy.exception, mode: \"bad\"});",
    "\t}",
    "",
    "\tpublic function index() {}",
    "}",
    "",
  ].join("\n"));
}

function materializeRuntimeRailsApp() {
  rmSync(runtimeAppDir, { force: true, recursive: true });
  copyTree(join(outputDir, "app"), join(runtimeAppDir, "app"));
  copyTree(join(outputDir, "config"), join(runtimeAppDir, "config"));

  writeFile("Gemfile", `source "https://rubygems.org"

gem "rails", ">= 7.0", "< 8.0"
`);

  writeFile("config/application.rb", `require "rails"
require "active_record"
require "action_controller/railtie"

module ActionControllerParamsRuntime
  class Application < Rails::Application
    config.load_defaults 7.0
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
  end
end
`);

  writeFile("config/environment.rb", `require_relative "application"

Rails.application.initialize!
`);

  writeFile("config/routes.rb", `Rails.application.routes.draw do
  get "/runtime", to: "controllers/todos#runtime_ok"
end
`);

  writeFile("test/test_helper.rb", `ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
`);

  writeFile("test/controllers/action_controller_params_runtime_test.rb", `require "test_helper"

class ActionControllerParamsRuntimeTest < ActionDispatch::IntegrationTest
  test "generated RailsHx controller handles a Rails request" do
    get "/runtime"

    assert_response :success
    assert_equal "runtime ok", response.body
  end
end
`);
}

function syntaxCheckRuntimeRailsApp() {
  for (const file of [
    "app/haxe_gen/controllers/todos_controller.rb",
    "config/application.rb",
    "config/environment.rb",
    "config/routes.rb",
    "config/initializers/hxruby_autoload.rb",
    "test/controllers/action_controller_params_runtime_test.rb",
  ]) {
    run("ruby", ["-c", join(runtimeAppDir, file)]);
  }
}

function copyTree(source, target) {
  mkdirSync(target, { recursive: true });
  for (const entry of readdirSync(source, { withFileTypes: true })) {
    const sourcePath = join(source, entry.name);
    const targetPath = join(target, entry.name);
    if (entry.isDirectory()) {
      copyTree(sourcePath, targetPath);
    } else if (entry.isFile()) {
      mkdirSync(dirname(targetPath), { recursive: true });
      copyFileSync(sourcePath, targetPath);
    }
  }
}

function writeFile(relativePath, content) {
  const path = join(runtimeAppDir, relativePath);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}
