#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "routes_generator");
const outputFile = join(outputDir, "src_haxe", "routes", "Routes.hx");
const fixture = join(root, "test", "fixtures", "rails_routes", "routes.txt");

rmSync(outputDir, { force: true, recursive: true });

const result = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "generate-routes.rb"),
  "--input",
  fixture,
  "--output",
  outputFile,
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
  '@:native("self")',
  "extern class Routes",
  '@:native("todos_path")',
  "public static function todosPath():String;",
  '@:native("todo_path")',
  "public static function todoPath(id:Dynamic):String;",
  '@:native("user_url")',
  "public static function userUrl(id:Dynamic):String;",
]) {
  if (!generated.includes(expected)) {
    console.error(`Routes generator output missing expected line: ${expected}`);
    process.exit(1);
  }
}
