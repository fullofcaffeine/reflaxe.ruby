#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "routes_generator");
const outputFile = join(outputDir, "src_haxe", "routes", "Routes.hx");
const fixture = join(root, "test", "fixtures", "rails_routes", "routes.txt");
const complexOutputFile = join(outputDir, "src_haxe", "routes", "ComplexRoutes.hx");
const complexFixture = join(root, "test", "fixtures", "rails_routes", "complex_routes.txt");
const deviseOutputFile = join(outputDir, "src_haxe", "routes", "DeviseRoutes.hx");
const deviseFixture = join(root, "test", "fixtures", "rails_routes", "devise_routes.txt");
const parityRoot = join(outputDir, "parity");
const taskRoot = join(outputDir, "task_sync");

rmSync(outputDir, { force: true, recursive: true });

runGenerator(fixture, outputFile);
runGenerator(fixture, outputFile);

if (!existsSync(outputFile)) {
  console.error(`Routes generator did not write ${outputFile}`);
  process.exit(1);
}

const manifest = JSON.parse(readFileSync(join(outputDir, ".railshx", "manifest.json"), "utf8"));
const routeEntry = manifest.outputs.find((entry) => entry.output === "src_haxe/routes/Routes.hx");
if (!routeEntry || routeEntry.kind !== "route_extern" || routeEntry.source !== "hxruby:routes" || !routeEntry.sha256) {
  console.error("Routes generator manifest did not record the generated route extern.");
  process.exit(1);
}

const generated = readFileSync(outputFile, "utf8");
const committed = readFileSync(join(root, "examples", "todoapp_rails", "src", "routes", "Routes.hx"), "utf8");
if (generated !== committed) {
  console.error("Generated Routes.hx does not match the committed todoapp route helper extern.");
  process.exit(1);
}

for (const expected of [
  "package routes;",
  "import rails.routing.RouteParam;",
  '@:native("self")',
  "extern class Routes",
  '@:native("root_path")',
  "public static function rootPath():String;",
  '@:native("todos_path")',
  "public static function todosPath():String;",
  '@:native("legacy_health_path")',
  "public static function legacyHealthPath():String;",
]) {
  if (!generated.includes(expected)) {
    console.error(`Routes generator output missing expected line: ${expected}`);
    process.exit(1);
  }
}

runGenerator(complexFixture, complexOutputFile, "ComplexRoutes");
const complexGenerated = readFileSync(complexOutputFile, "utf8");
for (const expected of [
  "extern class ComplexRoutes",
  "import rails.routing.RouteParam;",
  '@:native("root_path")',
  "public static function rootPath():String;",
  '@:native("admin_posts_path")',
  "public static function adminPostsPath():String;",
  '@:native("edit_admin_post_path")',
  "public static function editAdminPostPath(id:RouteParam):String;",
  '@:native("publish_admin_post_path")',
  "public static function publishAdminPostPath(id:RouteParam):String;",
  '@:native("search_admin_posts_path")',
  "public static function searchAdminPostsPath():String;",
  '@:native("post_comment_path")',
  "public static function postCommentPath(postId:RouteParam, id:RouteParam):String;",
  '@:native("preview_post_path")',
  "public static function previewPostPath(id:RouteParam):String;",
  '@:native("optional_report_path")',
  "public static function optionalReportPath():String;",
  '@:native("asset_path")',
  "public static function assetPath(path:RouteParam):String;",
  '@:native("sidekiq_path")',
  "public static function sidekiqPath():String;",
  '@:native("legacy_redirect_path")',
  "public static function legacyRedirectPath():String;",
  '@:native("duplicate_path")',
  "public static function duplicatePath(id:RouteParam):String;",
]) {
  if (!complexGenerated.includes(expected)) {
    console.error(`Complex route generator output missing expected line: ${expected}`);
    process.exit(1);
  }
}

for (const unexpected of [
  "railsMailersPath",
  "rails_mailers_path",
  "public static function duplicatePath():String;",
  "optionalReportPath(year",
]) {
  if (complexGenerated.includes(unexpected)) {
    console.error(`Complex route generator output included unexpected content: ${unexpected}`);
    process.exit(1);
  }
}

runGenerator(deviseFixture, deviseOutputFile, "DeviseRoutes");
const deviseGenerated = readFileSync(deviseOutputFile, "utf8");
for (const expected of [
  "extern class DeviseRoutes",
  '@:native("new_user_session_path")',
  "public static function newUserSessionPath():String;",
  '@:native("user_session_path")',
  "public static function userSessionPath():String;",
  '@:native("destroy_user_session_path")',
  "public static function destroyUserSessionPath():String;",
  '@:native("new_user_password_path")',
  "public static function newUserPasswordPath():String;",
  '@:native("edit_user_password_path")',
  "public static function editUserPasswordPath():String;",
  '@:native("user_password_path")',
  "public static function userPasswordPath():String;",
  '@:native("cancel_user_registration_path")',
  "public static function cancelUserRegistrationPath():String;",
  '@:native("new_user_registration_path")',
  "public static function newUserRegistrationPath():String;",
  '@:native("edit_user_registration_path")',
  "public static function editUserRegistrationPath():String;",
  '@:native("user_registration_path")',
  "public static function userRegistrationPath():String;",
  '@:native("new_user_confirmation_path")',
  "public static function newUserConfirmationPath():String;",
  '@:native("user_confirmation_path")',
  "public static function userConfirmationPath():String;",
  '@:native("new_user_unlock_path")',
  "public static function newUserUnlockPath():String;",
  '@:native("user_unlock_path")',
  "public static function userUnlockPath():String;",
  '@:native("user_github_omniauth_authorize_path")',
  "public static function userGithubOmniauthAuthorizePath():String;",
  '@:native("user_github_omniauth_callback_path")',
  "public static function userGithubOmniauthCallbackPath():String;",
]) {
  if (!deviseGenerated.includes(expected)) {
    console.error(`Devise route generator output missing expected line: ${expected}`);
    process.exit(1);
  }
}

for (const unexpected of [
  "userSessionPath(id",
  "userPasswordPath(id",
  "userRegistrationPath(id",
]) {
  if (deviseGenerated.includes(unexpected)) {
    console.error(`Devise route generator output included unexpected content: ${unexpected}`);
    process.exit(1);
  }
}

const collisionRoot = join(outputDir, "collision");
const collisionOutput = join(collisionRoot, "src_haxe", "routes", "Routes.hx");
mkdirSync(join(collisionRoot, "src_haxe", "routes"), { recursive: true });
writeFileSync(collisionOutput, "// hand-written route extern\n");
const collision = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "generate-routes.rb"),
  "--input",
  fixture,
  "--output",
  collisionOutput,
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (collision.status === 0 || !collision.stderr.includes("Refusing to overwrite non-RailsHx-owned file")) {
  process.stdout.write(collision.stdout);
  process.stderr.write(collision.stderr);
  console.error("Routes generator did not protect a non-owned route extern.");
  process.exit(1);
}

runParitySmoke();
runRoutesTaskSmoke();

function runGenerator(input, output, className = "Routes") {
  const result = spawnSync("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "generate-routes.rb"),
    "--input",
    input,
    "--output",
    output,
    "--class",
    className,
  ], {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });

  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
}

function runParitySmoke() {
  mkdirSync(parityRoot, { recursive: true });
  const routesPath = join(parityRoot, "routes.txt");
  writeFileSync(routesPath, [
    "Prefix Verb     URI Pattern                Controller#Action",
    "root GET        /                          posts#index",
    "post_search GET|POST /posts/search(.:format) posts#search",
    "health GET      /up(.:format)              health#show",
    "status GET      /api/status(.:format)      health#show",
    "",
  ].join("\n"));

  const happyManifest = {
    version: 1,
    source: "routes.AppRoutes",
    output: "config/routes.rb",
    class: "routes.AppRoutes",
    declarations: [
      { kind: "root", target: "posts#index", position: "AppRoutes.hx:1" },
      { kind: "match", name: "post_search", verbs: ["get", "post"], path: "posts/search", target: "posts#search", position: "AppRoutes.hx:2" },
      { kind: "verb", name: "health", verb: "get", path: "up", target: "health#show", position: "AppRoutes.hx:3" },
      {
        kind: "scope",
        path: "api",
        position: "AppRoutes.hx:4",
        children: [
          { kind: "verb", name: "status", verb: "get", path: "status", target: "health#show", position: "AppRoutes.hx:5" },
        ],
      },
    ],
  };
  expectParitySuccess("happy", happyManifest, routesPath);
  expectParityFailure("missing", {
    ...happyManifest,
    declarations: happyManifest.declarations.concat([{ kind: "verb", name: "missing", verb: "get", path: "missing", target: "missing#show", position: "AppRoutes.hx:6" }]),
  }, routesPath, "missing Haxe-owned route");
  expectParityFailure("wrong-target", {
    ...happyManifest,
    declarations: [{ kind: "verb", name: "health", verb: "get", path: "up", target: "legacy#show", position: "AppRoutes.hx:7" }],
  }, routesPath, "wrong target");
  expectParityFailure("wrong-path", {
    ...happyManifest,
    declarations: [{ kind: "verb", name: "health", verb: "get", path: "wrong", target: "health#show", position: "AppRoutes.hx:8" }],
  }, routesPath, "wrong path");
  expectParityFailure("wrong-verb", {
    ...happyManifest,
    declarations: [{ kind: "verb", name: "health", verb: "post", path: "up", target: "health#show", position: "AppRoutes.hx:9" }],
  }, routesPath, "wrong verb");
  expectParityFailure("opaque", {
    ...happyManifest,
    declarations: [{ kind: "rawRuby", opaque: true, lineSha256: "abc", position: "AppRoutes.hx:10" }],
  }, routesPath, "opaque raw Haxe-owned route");
  expectParityFailure("unsupported-version", {
    ...happyManifest,
    version: 99,
  }, routesPath, "unsupported Haxe-owned route manifest version");
  expectParityFailure("unknown-kind", {
    ...happyManifest,
    declarations: [{ kind: "mysteryRoute", position: "AppRoutes.hx:11" }],
  }, routesPath, "unknown Haxe-owned route manifest declaration kind mysteryRoute");

  const deviseManifest = {
    version: 2,
    source: "routes.AppRoutes",
    output: "config/routes.rb",
    class: "routes.AppRoutes",
    declarations: [
      {
        kind: "deviseFor",
        resource: "users",
        expectedMapping: { name: "user", className: "User", path: "users" },
        contract: { type: "app.auth.UserAuth", field: "scope", schema: 1 },
        options: {},
        position: "AppRoutes.hx:12",
      },
    ],
  };
  expectParityFailure("devise-missing-facts", deviseManifest, routesPath, "Devise route manifest entries require Devise mapping facts");
  expectParitySuccess("devise-happy", deviseManifest, routesPath, writeDeviseFacts("devise-happy", {
    mappings: {
      user: { name: "user", className: "User", path: "users", scopedPath: "users", modelHasDevise: true },
    },
  }));
  expectParityFailure("devise-missing-mapping", deviseManifest, routesPath, "missing Devise mapping", writeDeviseFacts("devise-missing-mapping", { mappings: {} }));
  expectParityFailure("devise-wrong-class", deviseManifest, routesPath, "wrong Devise mapping", writeDeviseFacts("devise-wrong-class", {
    mappings: {
      user: { name: "user", className: "Account", path: "users", scopedPath: "users", modelHasDevise: true },
    },
  }));
  expectParityFailure("devise-wrong-path", deviseManifest, routesPath, "wrong Devise mapping", writeDeviseFacts("devise-wrong-path", {
    mappings: {
      user: { name: "user", className: "User", path: "accounts", scopedPath: "accounts", modelHasDevise: true },
    },
  }));
  expectParityFailure("devise-model-missing-devise", deviseManifest, routesPath, "does not point at a model with Devise modules", writeDeviseFacts("devise-model-missing-devise", {
    mappings: {
      user: { name: "user", className: "User", path: "users", scopedPath: "users", modelHasDevise: false },
    },
  }));
  const malformedFactsPath = join(parityRoot, "devise-malformed-facts.json");
  writeFileSync(malformedFactsPath, "{not-json");
  expectParityFailure("devise-malformed-facts", deviseManifest, routesPath, "Invalid Haxe-owned route manifest or Devise mapping facts", malformedFactsPath);
}

function expectParitySuccess(name, manifest, routesPath, factsPath = null) {
  const manifestPath = writeParityManifest(name, manifest);
  const result = runParity(manifestPath, routesPath, factsPath);
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    console.error(`[routes-generator] expected route parity success for ${name}`);
    process.exit(1);
  }
}

function expectParityFailure(name, manifest, routesPath, expectedError, factsPath = null) {
  const manifestPath = writeParityManifest(name, manifest);
  const result = runParity(manifestPath, routesPath, factsPath);
  if (result.status === 0 || !result.stderr.includes(expectedError)) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    console.error(`[routes-generator] expected route parity failure ${name}: ${expectedError}`);
    process.exit(1);
  }
}

function writeParityManifest(name, manifest) {
  const path = join(parityRoot, `${name}.routes.haxe.json`);
  writeFileSync(path, `${JSON.stringify(manifest, null, 2)}\n`);
  return path;
}

function writeDeviseFacts(name, facts) {
  const path = join(parityRoot, `${name}.devise-facts.json`);
  writeFileSync(path, `${JSON.stringify(facts, null, 2)}\n`);
  return path;
}

function runParity(manifestPath, routesPath, factsPath = null) {
  const args = [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "check-routes-parity.rb"),
    "--manifest",
    manifestPath,
    "--input",
    routesPath,
  ];
  if (factsPath) {
    args.push("--devise-facts", factsPath);
  }
  return spawnSync("ruby", args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
}

function runRoutesTaskSmoke() {
  mkdirSync(taskRoot, { recursive: true });
  const railsStub = join(taskRoot, "rails_stub.rb");
  writeFileSync(railsStub, [
    'if ARGV.first == "routes"',
    '  if ENV["FAIL_ROUTES"] == "1"',
    '    warn "stubbed rails routes failure"',
    "    exit 7",
    "  end",
    '  puts File.read(ENV.fetch("ROUTES_FIXTURE"))',
    "else",
    '  abort "unexpected rails command: #{ARGV.join(" ")}"',
    "end",
    "",
  ].join("\n"));

  const taskOutput = join(taskRoot, "src_haxe", "routes", "Routes.hx");
  const ok = runRoutesTask({
    OUTPUT: taskOutput,
    RAILS: `ruby ${railsStub}`,
    ROUTES_FIXTURE: fixture,
    MODE: "rails-owned",
  });
  if (ok.status !== 0) {
    process.stdout.write(ok.stdout);
    process.stderr.write(ok.stderr);
    console.error("hxruby:routes MODE=rails-owned failed with a valid rails routes provider.");
    process.exit(1);
  }
  const generated = readFileSync(taskOutput, "utf8");
  for (const expected of ["public static function rootPath():String;", "public static function legacyHealthPath():String;"]) {
    if (!generated.includes(expected)) {
      console.error(`hxruby:routes MODE=rails-owned output missing expected helper: ${expected}`);
      process.exit(1);
    }
  }

  const failure = runRoutesTask({
    OUTPUT: join(taskRoot, "failure", "src_haxe", "routes", "Routes.hx"),
    RAILS: `ruby ${railsStub}`,
    ROUTES_FIXTURE: fixture,
    MODE: "rails-owned",
    FAIL_ROUTES: "1",
  });
  if (failure.status === 0 || !failure.stderr.includes("Rails route helper extraction failed")) {
    process.stdout.write(failure.stdout);
    process.stderr.write(failure.stderr);
    console.error("hxruby:routes did not fail loudly when rails routes failed.");
    process.exit(1);
  }
}

function runRoutesTask(extraEnv) {
  return spawnSync("ruby", [
    "-I",
    join(root, "lib"),
    "-e",
    'require "hxruby/tasks"; HXRuby::Tasks.install; Rake::Task["hxruby:routes"].invoke',
  ], {
    cwd: root,
    env: { ...process.env, ...extraEnv },
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
}
