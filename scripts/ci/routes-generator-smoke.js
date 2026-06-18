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
const parityRoot = join(outputDir, "parity");

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
const committed = readFileSync(join(root, "examples", "todoapp_rails", "src_haxe", "routes", "Routes.hx"), "utf8");
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
}

function expectParitySuccess(name, manifest, routesPath) {
  const manifestPath = writeParityManifest(name, manifest);
  const result = runParity(manifestPath, routesPath);
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    console.error(`[routes-generator] expected route parity success for ${name}`);
    process.exit(1);
  }
}

function expectParityFailure(name, manifest, routesPath, expectedError) {
  const manifestPath = writeParityManifest(name, manifest);
  const result = runParity(manifestPath, routesPath);
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

function runParity(manifestPath, routesPath) {
  return spawnSync("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "check-routes-parity.rb"),
    "--manifest",
    manifestPath,
    "--input",
    routesPath,
  ], {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
}
