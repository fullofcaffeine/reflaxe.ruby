#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "scaffold_cli");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });

run(process.execPath, [
  join(root, "scripts", "rails", "scaffold.js"),
  "--model",
  "Todo",
  "--fields",
  "title:String,isCompleted:Bool",
  "--validate",
  "title",
  "--controller",
  "--output",
  outputDir,
]);

for (const file of [
  "src_haxe/models/Todo.hx",
  "src_haxe/controllers/TodosController.hx",
  "src_haxe/routes/Routes.hx",
  "src_haxe/Main.hx",
  "db/migrate/20260101000000_create_todos.rb",
  "build.hxml",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Scaffold output missing ${fullPath}`);
    process.exit(1);
  }
}

assertIncludes("src_haxe/models/Todo.hx", [
  '@:railsModel("todos")',
  "class Todo extends rails.active_record.Base<Todo>",
  "@:railsColumn public var title:String;",
  "@:validates({presence: true})",
]);
assertIncludes("src_haxe/controllers/TodosController.hx", [
  "class TodosController extends rails.action_controller.Base",
  'ParamsMacro.requirePermit(this.params(), "todo", ["title", "isCompleted"])',
  "redirectTo(Routes.todosPath())",
]);
assertIncludes("src_haxe/routes/Routes.hx", [
  '@:native("self")',
  '@:native("todos_path")',
  "public static function todosPath():String;",
]);
assertIncludes("db/migrate/20260101000000_create_todos.rb", [
  "class CreateTodos < ActiveRecord::Migration[7.1]",
  "create_table :todos do |t|",
  "t.string :title",
  "t.boolean :is_completed",
]);

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile scaffolded Haxe project through Reflaxe.");
  process.exit(1);
}

function assertIncludes(relativeFile, expectedLines) {
  const content = readFileSync(join(outputDir, relativeFile), "utf8");
  for (const expected of expectedLines) {
    if (!content.includes(expected)) {
      console.error(`${relativeFile} missing expected line: ${expected}`);
      process.exit(1);
    }
  }
}

function compileWithFirstAvailableReflaxe() {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${join(outputDir, "ruby")}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      join(outputDir, "src_haxe"),
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
