#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const sourceDir = join(root, "test", ".generated", "devisehx_core_src");
const outputDir = join(root, "test", ".generated", "devisehx_core_out");
const invalidResourceDir = join(root, "test", ".generated", "devisehx_core_invalid_resource_src");
const invalidResourceOut = join(root, "test", ".generated", "devisehx_core_invalid_resource_out");
const invalidScopeDir = join(root, "test", ".generated", "devisehx_core_invalid_scope_src");
const invalidScopeOut = join(root, "test", ".generated", "devisehx_core_invalid_scope_out");
const reflaxeSrc = join(root, "vendor", "reflaxe", "src");

for (const dir of [sourceDir, outputDir, invalidResourceDir, invalidResourceOut, invalidScopeDir, invalidScopeOut]) {
  rmSync(dir, { force: true, recursive: true });
}

if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
  console.error("Unable to find vendored Reflaxe source for DeviseHx core smoke.");
  process.exit(1);
}

writePositiveSources(sourceDir);
compile(sourceDir, outputDir);
assertGeneratedShape(outputDir);
assertNoAppFacingDynamic();

writePositiveSources(invalidResourceDir, {
  extraMainLines: [
    "\t\tvar admin = new Admin();",
    "\t\tAuth.signIn(controller, UserAuth.scope, admin);",
  ],
});
expectCompileFailure(invalidResourceDir, invalidResourceOut, "models.Admin should be models.User");

writePositiveSources(invalidScopeDir, {
  extraMainLines: [
    "\t\tvar wrong:DeviseScope<Admin> = UserAuth.scope;",
  ],
});
expectCompileFailure(invalidScopeDir, invalidScopeOut, "models.User should be models.Admin");

function writePositiveSources(dir, options = {}) {
  mkdirSync(join(dir, "models"), { recursive: true });
  mkdirSync(join(dir, "app", "auth"), { recursive: true });

  writeFileSync(join(dir, "models", "User.hx"), [
    "package models;",
    "",
    "class User extends rails.active_record.Base<User> implements devisehx.model.DeviseResource<User> {",
    "\tpublic function new() {",
    "\t\tsuper();",
    "\t}",
    "",
    "\tpublic var email:String;",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(dir, "models", "Admin.hx"), [
    "package models;",
    "",
    "class Admin extends rails.active_record.Base<Admin> implements devisehx.model.DeviseResource<Admin> {",
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
    "",
    "// Generated app-local contract shape: scope/model/resource are coupled once,",
    "// then reused by controllers, HHX, tests, and future generators.",
    "final class UserAuth {",
    "\tpublic static final scope:DeviseScope<User> = DeviseScope.of(ScopeName.named(\"user\"), RouteResource.named(\"users\"), User);",
    "\tpublic static final authenticate:AuthFilter<User> = Auth.require(scope);",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(dir, "app", "auth", "AdminAuth.hx"), [
    "package app.auth;",
    "",
    "import devisehx.DeviseScope;",
    "import devisehx.RouteResource;",
    "import devisehx.ScopeName;",
    "import models.Admin;",
    "",
    "final class AdminAuth {",
    "\tpublic static final scope:DeviseScope<Admin> = DeviseScope.of(ScopeName.named(\"admin\"), RouteResource.named(\"admins\"), Admin);",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(dir, "Main.hx"), [
    "import app.auth.AdminAuth;",
    "import app.auth.UserAuth;",
    "import devisehx.Auth;",
    "import devisehx.AuthFilter;",
    "import devisehx.DeviseScope;",
    "import devisehx.mapping.DeviseMapping;",
    "import devisehx.model.DeviseModule.*;",
    "import devisehx.model.DeviseModuleSpec;",
    "import devisehx.test.IntegrationHelpers;",
    "import devisehx.warden.WardenAccess;",
    "import models.Admin;",
    "import models.User;",
    "import rails.action_controller.Base;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar controller = new Base();",
    "\t\tvar user = new User();",
    "\t\tvar filter:AuthFilter<User> = UserAuth.authenticate;",
    "\t\tvar maybeUser:Null<User> = Auth.current(controller, UserAuth.scope);",
    "\t\tvar requiredUser:User = Auth.currentRequired(controller, UserAuth.scope);",
    "\t\tvar signedIn:Bool = Auth.signedIn(controller, UserAuth.scope);",
    "\t\tAuth.signIn(controller, UserAuth.scope, user);",
    "\t\tAuth.bypassSignIn(controller, UserAuth.scope, user);",
    "\t\tAuth.signOut(controller, UserAuth.scope);",
    "\t\tAuth.signOutAll(controller);",
    "\t\tvar specs:Array<DeviseModuleSpec> = [databaseAuthenticatable, registerable, recoverable, rememberable, validatable, confirmable, lockable, trackable, timeoutable, omniauthable([\"github\"]), unsafeCustom(\"magic_auth\")];",
    "\t\tvar proxy = WardenAccess.unsafeWarden(controller);",
    "\t\tvar wardenUser:Null<User> = proxy.user(UserAuth.scope);",
    "\t\tvar authenticated:Bool = proxy.authenticated(UserAuth.scope);",
    "\t\tIntegrationHelpers.signIn(UserAuth.scope, user);",
    "\t\tIntegrationHelpers.signOut(UserAuth.scope);",
    "\t\tvar adminScope:DeviseScope<Admin> = AdminAuth.scope;",
    "\t\tvar mapping:DeviseMapping<User> = null;",
    "\t\tSys.println(filter != null || maybeUser != null || requiredUser != null || signedIn || specs.length > 0 || wardenUser != null || authenticated || adminScope != null || mapping != null);",
    ...(options.extraMainLines ?? []),
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function compile(src, out) {
  run("haxe", haxeArgs(src, out));
}

function expectCompileFailure(src, out, expectedMessage) {
  const result = run("haxe", haxeArgs(src, out), { allowFailure: true });
  if (result.status === 0) {
    console.error(`Expected DeviseHx invalid fixture to fail: ${src}`);
    process.exit(1);
  }
  const combined = `${result.stdout}\n${result.stderr}`;
  if (!combined.includes(expectedMessage)) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    console.error(`DeviseHx invalid fixture failed without expected diagnostic: ${expectedMessage}`);
    process.exit(1);
  }
}

function haxeArgs(src, out) {
  return [
    "-D",
    `ruby_output=${out}`,
    "-D",
    "reflaxe_runtime",
    "-cp",
    join(root, "src"),
    "-cp",
    src,
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  ];
}

function assertGeneratedShape(out) {
  for (const file of ["hxruby/core.rb", "main.rb", "app/auth/user_auth.rb", "app/auth/admin_auth.rb"]) {
    if (!existsSync(join(out, file))) {
      console.error(`Expected DeviseHx generated Ruby file missing: ${file}`);
      process.exit(1);
    }
  }
}

function assertNoAppFacingDynamic() {
  const allowed = new Set([]);
  const files = [
    "std/devisehx/Auth.hx",
    "std/devisehx/AuthFilter.hx",
    "std/devisehx/DeviseScope.hx",
    "std/devisehx/RouteResource.hx",
    "std/devisehx/ScopeName.hx",
    "std/devisehx/SignInOptions.hx",
    "std/devisehx/mapping/DeviseMapping.hx",
    "std/devisehx/model/DeviseModule.hx",
    "std/devisehx/model/DeviseModuleSpec.hx",
    "std/devisehx/model/DeviseResource.hx",
    "std/devisehx/test/IntegrationHelpers.hx",
    "std/devisehx/warden/WardenAccess.hx",
    "std/devisehx/warden/WardenProxy.hx",
  ];
  for (const relative of files) {
    if (allowed.has(relative)) continue;
    const source = readFileSync(join(root, relative), "utf8");
    if (source.includes("Dynamic")) {
      console.error(`DeviseHx core exposes Dynamic in ${relative}`);
      process.exit(1);
    }
  }
}

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
