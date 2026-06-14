#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "routes_generator");
const outputFile = join(outputDir, "src_haxe", "routes", "Routes.hx");
const fixture = join(root, "test", "fixtures", "rails_routes", "routes.txt");
const complexOutputFile = join(outputDir, "src_haxe", "routes", "ComplexRoutes.hx");
const complexFixture = join(root, "test", "fixtures", "rails_routes", "complex_routes.txt");

rmSync(outputDir, { force: true, recursive: true });

runGenerator(fixture, outputFile);

if (!existsSync(outputFile)) {
  console.error(`Routes generator did not write ${outputFile}`);
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
  '@:native("todos_path")',
  "public static function todosPath():String;",
  '@:native("todo_path")',
  "public static function todoPath(id:RouteParam):String;",
  '@:native("user_url")',
  "public static function userUrl(id:RouteParam):String;",
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
