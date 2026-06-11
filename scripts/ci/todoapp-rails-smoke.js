#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "todoapp_rails");
const exampleDir = join(root, "examples", "todoapp_rails");
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

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile todoapp_rails through Reflaxe.");
  process.exit(1);
}

for (const file of [
  "app/haxe_gen/models/todo.rb",
  "app/haxe_gen/models/user.rb",
  "app/haxe_gen/controllers/todos_controller.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected todoapp_rails output file missing: ${fullPath}`);
    process.exit(1);
  }
}

const todoRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "todo.rb"), "utf8");
for (const expected of [
  'require "active_record"',
  "module Models",
  "class Todo < ActiveRecord::Base",
  'self.table_name = "todos"',
  "def self.__hx_rails_schema()",
  'table_name: "todos"',
  "timestamps: true",
  "{name: :id, haxe_name: \"id\", ruby_name: \"id\", haxe_type: \"Int\", rails_type: :bigint, nullable: false, default: nil, primary_key: true, index: false, unique: false, db_type: :bigint}",
  "{name: :title, haxe_name: \"title\", ruby_name: \"title\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "{name: :is_completed, haxe_name: \"isCompleted\", ruby_name: \"is_completed\", haxe_type: \"Bool\", rails_type: :boolean, nullable: false, default: false, primary_key: false, index: false, unique: false, db_type: nil}",
  "{name: :user_id, haxe_name: \"userId\", ruby_name: \"user_id\", haxe_type: \"Int\", rails_type: :integer, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "belongs_to :user",
  "# haxe column id: Int",
  "# haxe column title: String",
  "# haxe column is_completed: Bool",
  "# haxe column user_id: Int",
  "validates :title, presence: true",
  "def self.incomplete()",
  "Models::Todo.where(is_completed: false)",
]) {
  if (!todoRuby.includes(expected)) {
    console.error(`todoapp_rails model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const userRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "user.rb"), "utf8");
for (const expected of [
  'require "active_record"',
  "module Models",
  "class User < ActiveRecord::Base",
  'self.table_name = "users"',
  "def self.__hx_rails_schema()",
  'table_name: "users"',
  "timestamps: true",
  "{name: :id, haxe_name: \"id\", ruby_name: \"id\", haxe_type: \"Int\", rails_type: :bigint, nullable: false, default: nil, primary_key: true, index: false, unique: false, db_type: :bigint}",
  "{name: :name, haxe_name: \"name\", ruby_name: \"name\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "has_many :todos",
  "# haxe column id: Int",
  "# haxe column name: String",
  "validates :name, presence: true",
]) {
  if (!userRuby.includes(expected)) {
    console.error(`todoapp_rails user model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const controllerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "controllers", "todos_controller.rb"), "utf8");
for (const expected of [
  /require "action_controller\/railtie"/,
  /module Controllers/,
  /class TodosController < ActionController::Base/,
  /todos__hx\d+ = Models::Todo\.incomplete\(\)/,
  /self\.render\(template: "controllers\/todos\/index", locals: \{"todos" => todos__hx\d+\}\)/,
  /attrs__hx\d+ = self\.params\(\)\.require\("todo"\)\.permit\(\[:title, :is_completed, :user_id\]\)/,
  /todo__hx\d+ = Models::Todo\.create\(attrs__hx\d+\)/,
  /self\.redirect_to\(self\.todos_path\(\)\)/,
]) {
  if (!expected.test(controllerRuby)) {
    console.error(`todoapp_rails controller output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const migrationRuby = readFileSync(join(exampleDir, "db", "migrate", "20260101000000_create_todos.rb"), "utf8");
for (const expected of [
  "class CreateTodos < ActiveRecord::Migration[7.1]",
  "create_table :users do |t|",
  "t.string :name, null: false",
  "create_table :todos do |t|",
  "t.string :title, null: false",
  "t.boolean :is_completed, null: false, default: false",
  "t.references :user, null: false, foreign_key: true",
]) {
  if (!migrationRuby.includes(expected)) {
    console.error(`todoapp_rails migration template missing expected line: ${expected}`);
    process.exit(1);
  }
}

const readme = readFileSync(join(exampleDir, "README.md"), "utf8");
for (const expected of [
  "RailsHx Todo App",
  "self.__hx_rails_schema",
  "ParamsMacro.requirePermit",
  "Rails migration template",
]) {
  if (!readme.includes(expected)) {
    console.error(`todoapp_rails README missing expected line: ${expected}`);
    process.exit(1);
  }
}

const view = readFileSync(join(exampleDir, "app", "views", "controllers", "todos", "index.html.erb"), "utf8");
for (const expected of [
  "Typed Rails, polished Ruby.",
  "RailsHx sample",
  "form_with",
  "todo-shell",
  "Models::Todo.__hx_rails_schema",
]) {
  if (!view.includes(expected)) {
    console.error(`todoapp_rails view missing expected content: ${expected}`);
    process.exit(1);
  }
}

function compileWithFirstAvailableReflaxe() {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${outputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
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
