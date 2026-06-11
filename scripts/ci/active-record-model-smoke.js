#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "active_record_model");
const invalidSourceDir = join(root, "test", ".generated", "active_record_model_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "active_record_model_invalid_out");
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
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile active_record_model through Reflaxe.");
  process.exit(1);
}

for (const file of [
  "app/haxe_gen/models/todo.rb",
  "app/haxe_gen/models/audit_log.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected ActiveRecord output file missing: ${fullPath}`);
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
  "{name: :completed, haxe_name: \"completed\", ruby_name: \"completed\", haxe_type: \"Bool\", rails_type: :boolean, nullable: false, default: false, primary_key: false, index: false, unique: false, db_type: nil}",
  "{name: :notes, haxe_name: \"notes\", ruby_name: \"notes\", haxe_type: \"String\", rails_type: :text, nullable: true, default: nil, primary_key: false, index: false, unique: false, db_type: :text}",
  "{name: :external_id, haxe_name: \"externalId\", ruby_name: \"external_id\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: false, unique: true, db_type: nil}",
  "# haxe column id: Int",
  "# haxe column title: String",
  "# haxe column completed: Bool",
  "# haxe column notes: Null",
  "# haxe column external_id: String",
]) {
  if (!todoRuby.includes(expected)) {
    console.error(`ActiveRecord model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

for (const unexpected of ["def self.where", "def self.create"]) {
  if (todoRuby.includes(unexpected)) {
    console.error(`Typed interop stub should not be emitted into model Ruby: ${unexpected}`);
    process.exit(1);
  }
}

const auditLogRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "audit_log.rb"), "utf8");
for (const expected of [
  "class AuditLog < ActiveRecord::Base",
  'self.table_name = "audit_logs"',
  "def self.__hx_rails_schema()",
  'table_name: "audit_logs"',
  "timestamps: false",
  "{name: :event_count, haxe_name: \"eventCount\", ruby_name: \"event_count\", haxe_type: \"Int\", rails_type: :integer, nullable: false, default: 0, primary_key: false, index: false, unique: false, db_type: nil}",
]) {
  if (!auditLogRuby.includes(expected)) {
    console.error(`ActiveRecord inferred model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "app", "haxe_gen", "main.rb"), "utf8");
for (const expected of [
  'Models::Todo.where(title: "ship")',
  'Models::Todo.create(title: "ship")',
  "Models::AuditLog.where(event_count: 1)",
]) {
  if (!mainRuby.includes(expected)) {
    console.error(`ActiveRecord call shape missing from main.rb: ${expected}`);
    process.exit(1);
  }
}

expectInvalidColumnDefaultFailure();

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
      join(root, "examples", "active_record_model"),
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

function expectInvalidColumnDefaultFailure() {
  mkdirSync(join(invalidSourceDir, "models"), { recursive: true });
  writeFileSync(join(invalidSourceDir, "Main.hx"), [
    "import models.BadModel;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad:BadModel = null;",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "models", "BadModel.hx"), [
    "package models;",
    "",
    "@:railsModel",
    "class BadModel extends rails.active_record.Base<BadModel> {",
    "\t@:railsColumn({defaultValue: \"not_bool\"})",
    "\tpublic var enabled:Bool;",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${invalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      invalidSourceDir,
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
      console.error("Expected invalid ActiveRecord column defaultValue compile to fail.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("@:railsColumn defaultValue for Bool fields must be a Bool literal.")) {
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      console.error("Invalid ActiveRecord column defaultValue failed without the expected diagnostic.");
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to find Reflaxe source for invalid ActiveRecord compile check.");
    process.exit(1);
  }
}
