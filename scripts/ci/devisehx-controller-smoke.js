#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const sourceDir = join(root, "test", ".generated", "devisehx_controller_src");
const outputDir = join(root, "test", ".generated", "devisehx_controller_out");
const invalidSourceDir = join(root, "test", ".generated", "devisehx_controller_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "devisehx_controller_invalid_out");
const strictInvalidSourceDir = join(root, "test", ".generated", "devisehx_controller_strict_invalid_src");
const strictInvalidOutputDir = join(root, "test", ".generated", "devisehx_controller_strict_invalid_out");
const strictWrongScopeSourceDir = join(root, "test", ".generated", "devisehx_controller_strict_wrong_scope_src");
const strictWrongScopeOutputDir = join(root, "test", ".generated", "devisehx_controller_strict_wrong_scope_out");
const strictSkippedSourceDir = join(root, "test", ".generated", "devisehx_controller_strict_skipped_src");
const strictSkippedOutputDir = join(root, "test", ".generated", "devisehx_controller_strict_skipped_out");
const strictDirectSourceDir = join(root, "test", ".generated", "devisehx_controller_strict_direct_src");
const strictDirectOutputDir = join(root, "test", ".generated", "devisehx_controller_strict_direct_out");
const reflaxeSrc = join(root, "vendor", "reflaxe", "src");

for (const dir of [
  sourceDir,
  outputDir,
  invalidSourceDir,
  invalidOutputDir,
  strictInvalidSourceDir,
  strictInvalidOutputDir,
  strictWrongScopeSourceDir,
  strictWrongScopeOutputDir,
  strictSkippedSourceDir,
  strictSkippedOutputDir,
  strictDirectSourceDir,
  strictDirectOutputDir,
]) {
  rmSync(dir, { force: true, recursive: true });
}

writePositiveSources(sourceDir);
compile(sourceDir, outputDir);
assertControllerOutput();
compile(sourceDir, outputDir, { strictCurrentRequired: true });

writeInvalidSources(invalidSourceDir);
expectCompileFailure(invalidSourceDir, invalidOutputDir, "direct generated Devise scope field");
writeStrictUnguardedSources(strictInvalidSourceDir);
expectCompileFailure(strictInvalidSourceDir, strictInvalidOutputDir, "requires a matching beforeAction", { strictCurrentRequired: true });
writeStrictWrongScopeSources(strictWrongScopeSourceDir);
expectCompileFailure(strictWrongScopeSourceDir, strictWrongScopeOutputDir, "requires a matching beforeAction", { strictCurrentRequired: true });
writeStrictSkippedSources(strictSkippedSourceDir);
expectCompileFailure(strictSkippedSourceDir, strictSkippedOutputDir, "requires a matching beforeAction", { strictCurrentRequired: true });
writeStrictDirectSources(strictDirectSourceDir);
expectCompileFailure(strictDirectSourceDir, strictDirectOutputDir, "requires a matching beforeAction", { strictCurrentRequired: true });

function writePositiveSources(dir) {
  mkdirSync(join(dir, "app", "auth"), { recursive: true });
  mkdirSync(join(dir, "controllers"), { recursive: true });
  mkdirSync(join(dir, "models"), { recursive: true });

  writeFileSync(join(dir, "models", "User.hx"), [
    "package models;",
    "",
    "// DeviseHx controller smoke model.",
    "// Demonstrates: model type carried through DeviseScope<User> so auth helpers",
    "// return User/Null<User> instead of Dynamic.",
    "class User extends rails.active_record.Base<User> implements devisehx.model.DeviseResource<User> {",
    "\tpublic function new() {",
    "\t\tsuper();",
    "\t}",
    "",
    "\tpublic var email:String;",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(dir, "app", "auth", "UserAuth.hx"), [
    "package app.auth;",
    "",
    "import devisehx.Auth;",
    "import devisehx.AuthFilter;",
    "import devisehx.DeviseScope;",
    "import devisehx.RouteResource;",
    "import devisehx.ScopeName;",
    "import models.User;",
    "import rails.action_controller.Base;",
    "",
    "// Generated DeviseHx app-local auth contract.",
    "// Demonstrates: a concrete generated scope exposes short UserAuth.* helpers,",
    "// while metadata gives the compiler literal Devise facts for native Ruby output.",
    "final class UserAuth {",
    "\t@:deviseHxRoute({schema: 1, routeAuthorable: true, resource: \"users\", mappingScope: \"user\", rubyClass: \"User\", haxeModel: \"models.User\"})",
    "\tpublic static final scope:DeviseScope<User> = DeviseScope.of(ScopeName.named(\"user\"), RouteResource.named(\"users\"), User);",
    "",
    "\t@:deviseHxAuthFilter({schema: 1, mappingScope: \"user\"})",
    "\tpublic static final authenticate:AuthFilter<User> = Auth.require(scope);",
    "",
    "\t@:deviseHxHelper({schema: 1, kind: \"current\", mappingScope: \"user\"})",
    "\tpublic static inline function current(controller:Base):Null<User> {",
    "\t\treturn Auth.current(controller, scope);",
    "\t}",
    "",
    "\t@:deviseHxHelper({schema: 1, kind: \"currentRequired\", mappingScope: \"user\"})",
    "\tpublic static inline function currentRequired(controller:Base):User {",
    "\t\treturn Auth.currentRequired(controller, scope);",
    "\t}",
    "",
    "\t@:deviseHxHelper({schema: 1, kind: \"signedIn\", mappingScope: \"user\"})",
    "\tpublic static inline function signedIn(controller:Base):Bool {",
    "\t\treturn Auth.signedIn(controller, scope);",
    "\t}",
    "",
    "\t@:deviseHxHelper({schema: 1, kind: \"signIn\", mappingScope: \"user\"})",
    "\tpublic static inline function signIn(controller:Base, resource:User):Void {",
    "\t\tAuth.signIn(controller, scope, resource);",
    "\t}",
    "",
    "\t@:deviseHxHelper({schema: 1, kind: \"signOut\", mappingScope: \"user\"})",
    "\tpublic static inline function signOut(controller:Base):Void {",
    "\t\tAuth.signOut(controller, scope);",
    "\t}",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(dir, "models", "Admin.hx"), [
    "package models;",
    "",
    "// Secondary Devise model used by strict-flow negative tests.",
    "class Admin extends rails.active_record.Base<Admin> implements devisehx.model.DeviseResource<Admin> {",
    "\tpublic function new() {",
    "\t\tsuper();",
    "\t}",
    "",
    "\tpublic var email:String;",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(dir, "app", "auth", "AdminAuth.hx"), [
    "package app.auth;",
    "",
    "import devisehx.Auth;",
    "import devisehx.AuthFilter;",
    "import devisehx.DeviseScope;",
    "import devisehx.RouteResource;",
    "import devisehx.ScopeName;",
    "import models.Admin;",
    "import rails.action_controller.Base;",
    "",
    "// Generated DeviseHx contract for a second scope.",
    "// Demonstrates: strict currentRequired flow checks are scope-specific, so an",
    "// admin guard cannot prove a user currentRequired call is safe.",
    "final class AdminAuth {",
    "\t@:deviseHxRoute({schema: 1, routeAuthorable: true, resource: \"admins\", mappingScope: \"admin\", rubyClass: \"Admin\", haxeModel: \"models.Admin\"})",
    "\tpublic static final scope:DeviseScope<Admin> = DeviseScope.of(ScopeName.named(\"admin\"), RouteResource.named(\"admins\"), Admin);",
    "",
    "\t@:deviseHxAuthFilter({schema: 1, mappingScope: \"admin\"})",
    "\tpublic static final authenticate:AuthFilter<Admin> = Auth.require(scope);",
    "",
    "\t@:deviseHxHelper({schema: 1, kind: \"currentRequired\", mappingScope: \"admin\"})",
    "\tpublic static inline function currentRequired(controller:Base):Admin {",
    "\t\treturn Auth.currentRequired(controller, scope);",
    "\t}",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(dir, "controllers", "DashboardController.hx"), [
    "package controllers;",
    "",
    "import app.auth.UserAuth;",
    "import devisehx.Auth;",
    "import rails.macros.ControllerDsl.*;",
    "",
    "// DeviseHx controller smoke.",
    "// Demonstrates: RailsHx-authored controllers use typed Devise auth contracts",
    "// instead of string filters or Dynamic helpers.",
    "// Type safety: beforeAction accepts the generated AuthFilter<User>; current()",
    "// returns Null<User>, currentRequired() returns User, and signIn/signOut only",
    "// accept resources matching UserAuth.scope.",
    "// IntelliSense: editors should complete UserAuth.authenticate/current/currentRequired/",
    "// signedIn/signIn/signOut from the app-local generated contract.",
    "// Ruby output: ordinary Devise/Rails helpers: before_action :authenticate_user!,",
    "// current_user, user_signed_in?, sign_in(:user, user), and sign_out(:user).",
    "@:railsController",
    "class DashboardController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = {",
    "\t\tbeforeAction(UserAuth.authenticate, {only: [index]});",
    "\t}",
    "",
    "\tpublic function index():Void {",
    "\t\tvar user = UserAuth.currentRequired(this);",
    "\t\tvar maybeUser = UserAuth.current(this);",
    "\t\tvar signedIn = UserAuth.signedIn(this);",
    "\t\tUserAuth.signIn(this, user);",
    "\t\tAuth.bypassSignIn(this, UserAuth.scope, user);",
    "\t\tUserAuth.signOut(this);",
    "\t\tAuth.signOutAll(this);",
    "\t\trender({plain: signedIn ? user.email : \"guest\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(dir, "Main.hx"), [
    "import controllers.DashboardController;",
    "",
    "class Main {",
    "\tstatic function main():Void {",
    "\t\tvar controller:DashboardController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function writeInvalidSources(dir) {
  writePositiveSources(dir);
  writeFileSync(join(dir, "controllers", "DashboardController.hx"), [
    "package controllers;",
    "",
    "import app.auth.UserAuth;",
    "import devisehx.Auth;",
    "import rails.macros.ControllerDsl.*;",
    "",
    "@:railsController",
    "class DashboardController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function index():Void {",
    "\t\tvar scope = UserAuth.scope;",
    "\t\tvar user = Auth.currentRequired(this, scope);",
    "\t\trender({plain: user.email});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function writeStrictUnguardedSources(dir) {
  writePositiveSources(dir);
  writeFileSync(join(dir, "controllers", "DashboardController.hx"), [
    "package controllers;",
    "",
    "import app.auth.UserAuth;",
    "import rails.macros.ControllerDsl.*;",
    "",
    "@:railsController",
    "class DashboardController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function index():Void {",
    "\t\tvar user = UserAuth.currentRequired(this);",
    "\t\trender({plain: user.email});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function writeStrictWrongScopeSources(dir) {
  writePositiveSources(dir);
  writeFileSync(join(dir, "controllers", "DashboardController.hx"), [
    "package controllers;",
    "",
    "import app.auth.AdminAuth;",
    "import app.auth.UserAuth;",
    "import rails.macros.ControllerDsl.*;",
    "",
    "@:railsController",
    "class DashboardController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = {",
    "\t\tbeforeAction(AdminAuth.authenticate, {only: [index]});",
    "\t}",
    "",
    "\tpublic function index():Void {",
    "\t\tvar user = UserAuth.currentRequired(this);",
    "\t\trender({plain: user.email});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function writeStrictSkippedSources(dir) {
  writePositiveSources(dir);
  writeFileSync(join(dir, "controllers", "DashboardController.hx"), [
    "package controllers;",
    "",
    "import app.auth.UserAuth;",
    "import rails.macros.ControllerDsl.*;",
    "",
    "// Strict-flow negative fixture.",
    "// Demonstrates: RailsHx must honor Rails skip_before_action semantics when",
    "// proving Devise currentRequired safety. A skipped auth filter does not",
    "// protect this action even if a broader beforeAction was declared earlier.",
    "@:railsController",
    "class DashboardController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = {",
    "\t\tbeforeAction(UserAuth.authenticate, {});",
    "\t\tskipBeforeAction(UserAuth.authenticate, {only: [index]});",
    "\t}",
    "",
    "\tpublic function index():Void {",
    "\t\tvar user = UserAuth.currentRequired(this);",
    "\t\trender({plain: user.email});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function writeStrictDirectSources(dir) {
  writePositiveSources(dir);
  writeFileSync(join(dir, "controllers", "DashboardController.hx"), [
    "package controllers;",
    "",
    "import app.auth.UserAuth;",
    "import devisehx.Auth;",
    "import rails.macros.ControllerDsl.*;",
    "",
    "@:railsController",
    "class DashboardController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = {",
    "\t\tbeforeAction(UserAuth.authenticate, {except: [index]});",
    "\t}",
    "",
    "\tpublic function index():Void {",
    "\t\tvar user = Auth.currentRequired(this, UserAuth.scope);",
    "\t\trender({plain: user.email});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function assertControllerOutput() {
  const controllerPath = join(outputDir, "app", "controllers", "dashboard_controller.rb");
  const legacyControllerPath = join(outputDir, "app", "haxe_gen", "controllers", "dashboard_controller.rb");
  if (!existsSync(controllerPath)) {
    console.error(`Expected generated DeviseHx controller missing: ${controllerPath}`);
    process.exit(1);
  }
  if (existsSync(legacyControllerPath)) {
    console.error(`Generated DeviseHx controller should use the Rails-native path, not legacy haxe_gen: ${legacyControllerPath}`);
    process.exit(1);
  }
  const ruby = readFileSync(controllerPath, "utf8");
  for (const expected of [
    /before_action :authenticate_user!, only: \[:index\]/,
    /user(?:__hx\d+)? = current_user\(\)/,
    /maybe_user(?:__hx\d+)? = current_user\(\)/,
    /signed_in(?:__hx\d+)? = user_signed_in\?\(\)/,
    /sign_in\(:user, user(?:__hx\d+)?\)/,
    /bypass_sign_in\(user(?:__hx\d+)?, scope: :user\)/,
    /sign_out\(:user\)/,
    /sign_out_all_scopes\(\)/,
  ]) {
    if (!expected.test(ruby)) {
      console.error(`Generated DeviseHx controller missing expected Ruby: ${expected}`);
      process.stderr.write(ruby);
      process.exit(1);
    }
  }
}

function compile(src, out, options = {}) {
  const result = run("haxe", haxeArgs(src, out, options));
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
}

function expectCompileFailure(src, out, expectedMessage, options = {}) {
  const result = run("haxe", haxeArgs(src, out, options));
  if (result.status === 0) {
    console.error("Expected invalid DeviseHx controller fixture to fail.");
    process.exit(1);
  }
  const combined = `${result.stdout}\n${result.stderr}`;
  if (!combined.includes(expectedMessage)) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    console.error(`Invalid DeviseHx controller fixture failed without expected diagnostic: ${expectedMessage}`);
    process.exit(1);
  }
}

function haxeArgs(src, out, options = {}) {
  const args = [
    "-D",
    `ruby_output=${out}`,
    "-D",
    "reflaxe_runtime",
    "-D",
    "reflaxe_ruby_rails",
    "-cp",
    join(root, "src"),
    "-cp",
    src,
    "-cp",
    join(root, "std"),
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  ];
  if (options.strictCurrentRequired) {
    args.splice(6, 0, "-D", "railshx_devise_strict_current_required");
  }
  return args;
}

function run(command, args) {
  return spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
}
