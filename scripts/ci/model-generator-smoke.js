#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "model_generator");
const collisionDir = join(root, "test", ".generated", "model_generator_collision");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
rmSync(collisionDir, { force: true, recursive: true });

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "model.rb"),
  "Todo",
  "title:string!",
  "completed:boolean:index",
  "price:decimal{10,2}",
  "user:references!",
  "--validate",
  "title,presence",
  "--timestamp",
  "20260101020101",
  "--migration-version",
  "8.1",
  "--output",
  outputDir,
]);

mkdirSync(join(outputDir, "src_haxe", "models"), { recursive: true });
writeFileSync(join(outputDir, "src_haxe", "models", "User.hx"), [
  "package models;",
  "",
  "@:railsModel(\"users\")",
  "class User extends rails.active_record.Base<User> {",
  "\t@:railsColumn({primaryKey: true, dbType: \"bigint\"})",
  "\tpublic var id:Int;",
  "}",
  "",
].join("\n"));
writeFileSync(join(outputDir, "src_haxe", "Main.hx"), [
  "import migrations.CreateTodos;",
  "import models.Todo;",
  "import models.User;",
  "",
  "class Main {",
  "\tstatic function main() {",
  "\t\tvar todo:Todo = null;",
  "\t\tvar user:User = null;",
  "\t\tvar migration:Class<CreateTodos> = CreateTodos;",
  "\t\tSys.println(todo == null && user == null && migration != null);",
  "\t}",
  "}",
  "",
].join("\n"));

assertIncludes("src_haxe/models/Todo.hx", [
  "class Todo extends rails.active_record.Base<Todo>",
  "@:railsModel(\"todos\")",
  "@:railsTimestamps",
  "@:railsColumn({nullable: false})",
  "public var title:String;",
  "@:railsColumn({index: true})",
  "public var completed:Null<Bool>;",
  "@:railsColumn({dbType: \"decimal\"})",
  "public var price:Null<Float>;",
  "@:railsColumn({nullable: false})",
  "public var userId:Int;",
  "@:belongsTo({foreignKey: \"userId\", optional: false})",
  "public var user:rails.ActiveRecord.BelongsTo<User>;",
  "@:validates({presence: true})",
  "public var titleValidation:rails.ActiveRecord.Validation<String>;",
]);
assertIncludes("src_haxe/migrations/CreateTodos.hx", [
  "class CreateTodos extends Migration",
  'timestamp: "20260101020101"',
  'version: "8.1"',
  'CreateTable("todos", {',
  'Column("title", StringColumn({nullable: false})),',
  'Column("completed", BooleanColumn({})),',
  'Index(["completed"], {}),',
  'Column("price", DecimalColumn({precision: 10, scale: 2})),',
  'Reference("user", {nullable: false, foreignKey: true}),',
]);

const manifest = JSON.parse(readFileSync(join(outputDir, ".railshx", "manifest.json"), "utf8"));
for (const [output, kind, source] of [
  ["src_haxe/models/Todo.hx", "haxe_model_source", "hxruby:model"],
  ["src_haxe/migrations/CreateTodos.hx", "haxe_migration_source", "hxruby:migration"],
]) {
  const entry = manifest.outputs.find((candidate) => candidate.output === output);
  if (!entry || entry.kind !== kind || entry.source !== source || !entry.sha256) {
    console.error(`Model generator manifest missing expected ${output} ${kind} entry.`);
    process.exit(1);
  }
}

if (!compileWithFirstAvailableReflaxe(join(outputDir, "ruby"))) {
  console.error("Unable to compile generated model Haxe through Reflaxe.");
  process.exit(1);
}

assertIncludes("ruby/app/haxe_gen/models/todo.rb", [
  "module Models",
  "class Todo < ::ApplicationRecord",
  "belongs_to :user, foreign_key: \"user_id\", optional: false",
  "validates :title, presence: true",
  "rails_type: :decimal",
  "self.__hx_rails_schema",
]);
assertIncludes("ruby/db/migrate/20260101020101_create_todos.rb", [
  "class CreateTodos < ActiveRecord::Migration[8.1]",
  "create_table :todos do |t|",
  "t.string :title, null: false",
  "t.boolean :completed",
  "t.index [:completed]",
  "t.decimal :price, precision: 10, scale: 2",
  "t.references :user, null: false, foreign_key: true",
]);

const pretend = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "model.rb"),
  "Project",
  "name:string!",
  "--skip-migration",
  "--output",
  outputDir,
  "--pretend",
]);
if (!pretend.stdout.includes("class Project extends rails.active_record.Base<Project>") || existsSync(join(outputDir, "src_haxe", "models", "Project.hx"))) {
  console.error("Model generator --pretend/--skip-migration did not print without writing.");
  process.exit(1);
}

mkdirSync(join(collisionDir, "src_haxe", "models"), { recursive: true });
writeFileSync(join(collisionDir, "src_haxe", "models", "Todo.hx"), "// hand-written model\n");
const collision = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "model.rb"),
  "Todo",
  "title:string",
  "--output",
  collisionDir,
], { allowFailure: true });
if (collision.status === 0 || !collision.stderr.includes("Refusing to overwrite non-RailsHx-owned file")) {
  process.stdout.write(collision.stdout);
  process.stderr.write(collision.stderr);
  console.error("Model generator did not protect a non-owned model file.");
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

function compileWithFirstAvailableReflaxe(rubyOutput) {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${rubyOutput}`,
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
