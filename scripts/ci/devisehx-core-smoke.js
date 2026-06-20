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
const invalidAuthLinksLocalDir = join(root, "test", ".generated", "devisehx_core_invalid_auth_links_local_src");
const invalidAuthLinksLocalOut = join(root, "test", ".generated", "devisehx_core_invalid_auth_links_local_out");
const invalidTestHelpersLocalDir = join(root, "test", ".generated", "devisehx_core_invalid_test_helpers_local_src");
const invalidTestHelpersLocalOut = join(root, "test", ".generated", "devisehx_core_invalid_test_helpers_local_out");
const invalidSanitizerStringDir = join(root, "test", ".generated", "devisehx_core_invalid_sanitizer_string_src");
const invalidSanitizerStringOut = join(root, "test", ".generated", "devisehx_core_invalid_sanitizer_string_out");
const invalidSanitizerDynamicDir = join(root, "test", ".generated", "devisehx_core_invalid_sanitizer_dynamic_src");
const invalidSanitizerDynamicOut = join(root, "test", ".generated", "devisehx_core_invalid_sanitizer_dynamic_out");
const invalidSanitizerModelDir = join(root, "test", ".generated", "devisehx_core_invalid_sanitizer_model_src");
const invalidSanitizerModelOut = join(root, "test", ".generated", "devisehx_core_invalid_sanitizer_model_out");
const invalidSchemaDir = join(root, "test", ".generated", "devisehx_core_invalid_schema_src");
const invalidSchemaOut = join(root, "test", ".generated", "devisehx_core_invalid_schema_out");
const invalidCustomModuleDir = join(root, "test", ".generated", "devisehx_core_invalid_custom_module_src");
const invalidCustomModuleOut = join(root, "test", ".generated", "devisehx_core_invalid_custom_module_out");
const invalidUnknownModuleDir = join(root, "test", ".generated", "devisehx_core_invalid_unknown_module_src");
const invalidUnknownModuleOut = join(root, "test", ".generated", "devisehx_core_invalid_unknown_module_out");
const reflaxeSrc = join(root, "vendor", "reflaxe", "src");

for (const dir of [
  sourceDir,
  outputDir,
  invalidResourceDir,
  invalidResourceOut,
  invalidScopeDir,
  invalidScopeOut,
  invalidAuthLinksLocalDir,
  invalidAuthLinksLocalOut,
  invalidTestHelpersLocalDir,
  invalidTestHelpersLocalOut,
  invalidSanitizerStringDir,
  invalidSanitizerStringOut,
  invalidSanitizerDynamicDir,
  invalidSanitizerDynamicOut,
  invalidSanitizerModelDir,
  invalidSanitizerModelOut,
  invalidSchemaDir,
  invalidSchemaOut,
  invalidCustomModuleDir,
  invalidCustomModuleOut,
  invalidUnknownModuleDir,
  invalidUnknownModuleOut,
]) {
  rmSync(dir, { force: true, recursive: true });
}

if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
  console.error("Unable to find vendored Reflaxe source for DeviseHx core smoke.");
  process.exit(1);
}

writePositiveSources(sourceDir);
compile(sourceDir, outputDir);
assertGeneratedShape(outputDir);
assertDeviseModelGeneratedShape(outputDir);
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

writePositiveSources(invalidAuthLinksLocalDir, {
  authLinksUseLocalScope: true,
});
expectCompileFailure(invalidAuthLinksLocalDir, invalidAuthLinksLocalOut, "DeviseHx auth helpers expect a direct generated Devise scope field");

writePositiveSources(invalidTestHelpersLocalDir, {
  extraMainLines: [
    "\t\tvar localUserScope = UserAuth.scope;",
    "\t\tIntegrationHelpers.signIn(localUserScope, user);",
  ],
});
expectCompileFailure(invalidTestHelpersLocalDir, invalidTestHelpersLocalOut, "DeviseHx auth helpers expect a direct generated Devise scope field");

writePositiveSources(invalidSanitizerStringDir, {
  extraMainLines: [
    "\t\tDeviseParams.permit(UserAuth.scope, SanitizerAction.signUp, [\"email\"]);",
  ],
});
expectCompileFailure(invalidSanitizerStringDir, invalidSanitizerStringOut, "String should be rails.active_record.Field<models.User, Dynamic>");

writePositiveSources(invalidSanitizerDynamicDir, {
  extraMainLines: [
    "\t\tvar customKey = \"time_zone\";",
    "\t\tDeviseParams.unsafePermit(UserAuth.scope, SanitizerAction.accountUpdate, [customKey]);",
  ],
});
expectCompileFailure(invalidSanitizerDynamicDir, invalidSanitizerDynamicOut, "DeviseParams.unsafePermit keys must be literal strings");

writePositiveSources(invalidSanitizerModelDir, {
  extraMainLines: [
    "\t\tDeviseParams.permit(UserAuth.scope, SanitizerAction.signUp, [Admin.f.email]);",
  ],
});
expectCompileFailure(invalidSanitizerModelDir, invalidSanitizerModelOut, "models.Admin should be models.User");

writePositiveSources(invalidSchemaDir, {
  omitEncryptedPassword: true,
  extraMainLines: [
    "\t\tvar modelClass:Class<User> = User;",
    "\t\tSys.println(modelClass != null);",
  ],
});
expectCompileFailure(invalidSchemaDir, invalidSchemaOut, "requires typed @:railsColumn field(s) for Devise module schema: encrypted_password");

writePositiveSources(invalidCustomModuleDir, {
  customModuleName: "MagicAuth",
  extraMainLines: [
    "\t\tvar modelClass:Class<User> = User;",
    "\t\tSys.println(modelClass != null);",
  ],
});
expectCompileFailure(invalidCustomModuleDir, invalidCustomModuleOut, "unsafeCustom(...) requires a safe snake_case custom module name literal");

writePositiveSources(invalidUnknownModuleDir, {
  moduleExpression: "magicAuth",
  extraMainLines: [
    "\t\tvar modelClass:Class<User> = User;",
    "\t\tSys.println(modelClass != null);",
  ],
});
expectCompileFailure(invalidUnknownModuleDir, invalidUnknownModuleOut, "Unsupported @:devise module token \"magicAuth\"");

function writePositiveSources(dir, options = {}) {
  mkdirSync(join(dir, "models"), { recursive: true });
  mkdirSync(join(dir, "app", "auth"), { recursive: true });
  mkdirSync(join(dir, "views"), { recursive: true });

  writeFileSync(join(dir, "models", "User.hx"), [
    "package models;",
    "",
    "import app.auth.UserAuth;",
    "import devisehx.model.DeviseModule.*;",
    "",
    "// Haxe-owned model fixture: @:devise emits a normal Ruby `devise` macro,",
    "// while compile-time schema validation proves required Devise columns exist.",
    "@:railsModel(\"users\")",
    `@:devise(UserAuth.scope, [databaseAuthenticatable, validatable, ${options.moduleExpression ?? `unsafeCustom("${options.customModuleName ?? "magic_auth"}")`}])`,
    "class User extends rails.active_record.Base<User> implements devisehx.model.DeviseResource<User> {",
    "\tpublic function new() {",
    "\t\tsuper();",
    "\t}",
    "",
    "\t@:railsColumn",
    "\tpublic var id:Int;",
    "",
    "\t@:railsColumn",
    "\tpublic var email:String;",
    "",
    ...(options.omitEncryptedPassword ? [] : [
      "\t@:railsColumn({dbType: \"string\", nullable: false, defaultValue: \"\"})",
      "\tpublic var encryptedPassword:String;",
      "",
    ]),
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(dir, "models", "Admin.hx"), [
    "package models;",
    "",
    "@:railsModel(\"admins\")",
    "class Admin extends rails.active_record.Base<Admin> implements devisehx.model.DeviseResource<Admin> {",
    "\tpublic function new() {",
    "\t\tsuper();",
    "\t}",
    "",
    "\t@:railsColumn",
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
    "\t@:deviseHxRoute({schema: 1, routeAuthorable: true, resource: \"users\", mappingScope: \"user\", rubyClass: \"User\", haxeModel: \"models.User\"})",
    "\tpublic static final scope:DeviseScope<User> = DeviseScope.of(ScopeName.named(\"user\"), RouteResource.named(\"users\"), User);",
    "\t@:deviseHxAuthFilter({schema: 1, mappingScope: \"user\"})",
    "\tpublic static final authenticate:AuthFilter<User> = Auth.require(scope);",
    "\t@:deviseHxHelper({schema: 1, kind: \"current\", mappingScope: \"user\"})",
    "\tpublic static inline function current(controller:rails.action_controller.Base):Null<User> {",
    "\t\treturn Auth.current(controller, scope);",
    "\t}",
    "\t@:deviseHxHelper({schema: 1, kind: \"currentRequired\", mappingScope: \"user\"})",
    "\tpublic static inline function currentRequired(controller:rails.action_controller.Base):User {",
    "\t\treturn Auth.currentRequired(controller, scope);",
    "\t}",
    "\t@:deviseHxHelper({schema: 1, kind: \"signedIn\", mappingScope: \"user\"})",
    "\tpublic static inline function signedIn(controller:rails.action_controller.Base):Bool {",
    "\t\treturn Auth.signedIn(controller, scope);",
    "\t}",
    "\t@:deviseHxHelper({schema: 1, kind: \"signIn\", mappingScope: \"user\"})",
    "\tpublic static inline function signIn(controller:rails.action_controller.Base, resource:User):Void {",
    "\t\tAuth.signIn(controller, scope, resource);",
    "\t}",
    "\t@:deviseHxHelper({schema: 1, kind: \"signOut\", mappingScope: \"user\"})",
    "\tpublic static inline function signOut(controller:rails.action_controller.Base):Void {",
    "\t\tAuth.signOut(controller, scope);",
    "\t}",
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
    "\t@:deviseHxRoute({schema: 1, routeAuthorable: true, resource: \"admins\", mappingScope: \"admin\", rubyClass: \"Admin\", haxeModel: \"models.Admin\"})",
    "\tpublic static final scope:DeviseScope<Admin> = DeviseScope.of(ScopeName.named(\"admin\"), RouteResource.named(\"admins\"), Admin);",
    "}",
    "",
  ].join("\n"));

  const authLinksViewBody = options.authLinksUseLocalScope ? [
    "\tpublic static function render():HtmlNode {",
    "\t\tvar scope = UserAuth.scope;",
    "\t\treturn <nav>",
    "\t\t\t<link_to url=${AuthLinks.signInPath(scope)} class=\"login-link\">Sign in</link_to>",
    "\t\t</nav>;",
    "\t}",
  ] : [
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <nav>",
    "\t\t\t<devise_sign_in_link scope=${UserAuth.scope} class=\"login-link\">Sign in</devise_sign_in_link>",
    "\t\t\t<devise_sign_up_link scope=${UserAuth.scope} class=\"signup-link\">Sign up</devise_sign_up_link>",
    "\t\t\t<devise_edit_registration_link scope=${UserAuth.scope} class=\"settings-link\">Settings</devise_edit_registration_link>",
    "\t\t\t<devise_sign_out_button scope=${UserAuth.scope} class=\"logout-button\">Sign out</devise_sign_out_button>",
    "\t\t\t<form_with url=${AuthLinks.sessionPath(UserAuth.scope)} scope=\"user\" local class=\"login-form\">",
    "\t\t\t\t<field_label name=${DeviseFormFields.email}>Email</field_label>",
    "\t\t\t\t<text_field name=${DeviseFormFields.email} type=\"email\" />",
    "\t\t\t\t<password_field name=${DeviseFormFields.password} />",
    "\t\t\t\t<submit type=\"submit\">Log in</submit>",
    "\t\t\t</form_with>",
    "\t\t\t<link_to url=${AuthLinks.passwordPath(UserAuth.scope)} class=\"password-link\">Password</link_to>",
    "\t\t\t<link_to url=${AuthLinks.confirmationPath(UserAuth.scope)} class=\"confirmation-link\">Confirmation</link_to>",
    "\t\t\t<link_to url=${AuthLinks.unlockPath(UserAuth.scope)} class=\"unlock-link\">Unlock</link_to>",
    "\t\t\t<if ${DeviseErrors.hasAny(locals.resource)}>",
    "\t\t\t\t<section class=\"devise-errors\" aria-label=\"Auth errors\">",
    "\t\t\t\t\t<strong>${DeviseErrors.count(locals.resource)}</strong>",
    "\t\t\t\t\t<ul>",
    "\t\t\t\t\t\t<for ${message in DeviseErrors.fullMessages(locals.resource)}>",
    "\t\t\t\t\t\t\t<li>${message}</li>",
    "\t\t\t\t\t\t</for>",
    "\t\t\t\t\t</ul>",
    "\t\t\t\t</section>",
    "\t\t\t</if>",
    "\t\t</nav>;",
    "\t}",
  ];

  writeFileSync(join(dir, "views", "AuthLinksView.hx"), [
    "package views;",
    "",
    "import app.auth.UserAuth;",
    "import devisehx.hhx.AuthLinks;",
    "import devisehx.hhx.DeviseErrors;",
    "import devisehx.hhx.DeviseFormFields;",
    "import rails.action_view.HtmlNode;",
    "import models.User;",
    "",
    "typedef AuthLinksLocals = {",
    "\tvar resource:User;",
    "}",
    "",
    "// DeviseHx HHX fixture: typed auth path helpers validate the generated",
    "// `UserAuth.scope` field, then the compiler emits normal Rails route",
    "// helpers inside ordinary `link_to`, `button_to`, and `form_with` output.",
    "// DeviseErrors demonstrates typed ActiveModel error reads without raw ERB.",
    "// DeviseFormFields carries @:railsField metadata so HHX emits checked Rails",
    "// form keys without app code repeating Devise strings.",
    "@:railsTemplate(\"auth_links/show\")",
    "@:railsTemplateAst(\"render\")",
    "class AuthLinksView {",
    ...authLinksViewBody.map((line) => line.replace("render():HtmlNode", "render(locals:AuthLinksLocals):HtmlNode")),
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
    "import devisehx.params.DeviseParams;",
    "import devisehx.params.SanitizerAction;",
    "import devisehx.test.IntegrationHelpers;",
    "import devisehx.warden.WardenAccess;",
    "import models.Admin;",
    "import models.User;",
    "import rails.action_controller.Base;",
    "import rails.action_view.HtmlNode;",
    "import views.AuthLinksView;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar controller = new Base();",
    "\t\tvar user = new User();",
    "\t\tvar filter:AuthFilter<User> = UserAuth.authenticate;",
    "\t\tvar maybeUser:Null<User> = Auth.current(controller, UserAuth.scope);",
    "\t\tvar requiredUser:User = Auth.currentRequired(controller, UserAuth.scope);",
    "\t\tvar signedIn:Bool = Auth.signedIn(controller, UserAuth.scope);",
    "\t\tvar authLinks:HtmlNode = AuthLinksView.render({resource: user});",
    "\t\tAuth.signIn(controller, UserAuth.scope, user);",
    "\t\tAuth.bypassSignIn(controller, UserAuth.scope, user);",
    "\t\tAuth.signOut(controller, UserAuth.scope);",
    "\t\tAuth.signOutAll(controller);",
    "\t\tvar specs:Array<DeviseModuleSpec> = [databaseAuthenticatable, registerable, recoverable, rememberable, validatable, confirmable, lockable, trackable, timeoutable, omniauthable([\"github\"]), unsafeCustom(\"magic_auth\")];",
    "\t\tvar proxy = WardenAccess.unsafeWarden(controller);",
    "\t\tvar wardenUser:Null<User> = proxy.user(UserAuth.scope);",
    "\t\tvar authenticated:Bool = proxy.authenticated(UserAuth.scope);",
    "\t\tDeviseParams.permit(UserAuth.scope, SanitizerAction.signUp, [User.f.email]);",
    "\t\tDeviseParams.unsafePermit(UserAuth.scope, SanitizerAction.accountUpdate, [\"time_zone\"]);",
    "\t\tIntegrationHelpers.signIn(UserAuth.scope, user);",
    "\t\tIntegrationHelpers.signOut(UserAuth.scope);",
    "\t\tvar adminScope:DeviseScope<Admin> = AdminAuth.scope;",
    "\t\tvar mapping:DeviseMapping<User> = null;",
    "\t\tSys.println(filter != null || maybeUser != null || requiredUser != null || signedIn || authLinks != null || specs.length > 0 || wardenUser != null || authenticated || adminScope != null || mapping != null);",
    "\t\tvar modelClass:Class<User> = User;",
    "\t\tSys.println(modelClass != null);",
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
    "reflaxe_ruby_rails",
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
  for (const file of [
    "app/haxe_gen/hxruby/core.rb",
    "app/haxe_gen/main.rb",
    "app/haxe_gen/app/auth/user_auth.rb",
    "app/haxe_gen/app/auth/admin_auth.rb",
    "app/haxe_gen/models/user.rb",
    "app/views/auth_links/show.html.erb",
  ]) {
    if (!existsSync(join(out, file))) {
      console.error(`Expected DeviseHx generated Ruby file missing: ${file}`);
      process.exit(1);
    }
  }
  const authLinks = readFileSync(join(out, "app/views/auth_links/show.html.erb"), "utf8");
  const main = readFileSync(join(out, "app/haxe_gen/main.rb"), "utf8");
  for (const expected of [
    "new_user_session_path()",
    "new_user_registration_path()",
    "edit_user_registration_path()",
    "destroy_user_session_path()",
    "user_session_path()",
    "user_password_path()",
    "user_confirmation_path()",
    "user_unlock_path()",
    "form.label :email",
    "form.text_field :email",
    "form.password_field :password",
    "method: \"delete\"",
    "resource.errors.any?",
    "resource.errors.count",
    "resource.errors.full_messages",
  ]) {
    if (!authLinks.includes(expected)) {
      console.error(`DeviseHx HHX output missing expected Rails helper shape: ${expected}`);
      process.exit(1);
    }
  }
  if (!/sign_in\(:user,\s*user__hx\d+\)/.test(main)) {
    console.error("DeviseHx test helper output missing expected Rails helper shape: sign_in(:user, user)");
    process.exit(1);
  }
  if (!main.includes("sign_out(:user)")) {
    console.error("DeviseHx test helper output missing expected Rails helper shape: sign_out(:user)");
    process.exit(1);
  }
  for (const expected of [
    "devise_parameter_sanitizer.permit(:sign_up, keys: [:email])",
    "devise_parameter_sanitizer.permit(:account_update, keys: [:time_zone])",
  ]) {
    if (!main.includes(expected)) {
      console.error(`DeviseHx sanitizer output missing expected Rails helper shape: ${expected}`);
      process.exit(1);
    }
  }
}

function assertDeviseModelGeneratedShape(out) {
  const userModel = readFileSync(join(out, "app/haxe_gen/models/user.rb"), "utf8");
  for (const expected of [
    "devise :database_authenticatable, :validatable, :magic_auth",
    "# haxe column email: String",
    "# haxe column encrypted_password: String",
  ]) {
    if (!userModel.includes(expected)) {
      console.error(`DeviseHx model output missing expected shape: ${expected}`);
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
    "std/devisehx/hhx/AuthLinks.hx",
    "std/devisehx/hhx/DeviseErrors.hx",
    "std/devisehx/hhx/DeviseFormFields.hx",
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
