#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "todoapp_rails");
const exampleDir = join(root, "examples", "todoapp_rails");
const invalidSourceDir = join(root, "test", ".generated", "todoapp_rails_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "todoapp_rails_invalid_out");
const rawErbInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_raw_erb_invalid_src");
const rawErbInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_raw_erb_invalid_out");
const typedTemplateInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_template_invalid_src");
const typedTemplateInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_template_invalid_out");
const typedPartialInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_partial_invalid_src");
const typedPartialInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_partial_invalid_out");
const typedRouteInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_route_invalid_src");
const typedRouteInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_route_invalid_out");
const typedRouteParamInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_route_param_invalid_src");
const typedRouteParamInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_route_param_invalid_out");
const typedFormInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_form_invalid_src");
const typedFormInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_form_invalid_out");
const typedSlotInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_slot_invalid_src");
const typedSlotInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_slot_invalid_out");
const templateRefInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_template_ref_invalid_src");
const templateRefInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_template_ref_invalid_out");
const templatePathInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_template_path_invalid_src");
const templatePathInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_template_path_invalid_out");
const templateBackslashPathInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_template_backslash_path_invalid_src");
const templateBackslashPathInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_template_backslash_path_invalid_out");
const rawLayoutInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_raw_layout_invalid_src");
const rawLayoutInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_raw_layout_invalid_out");
const typedFieldInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_field_invalid_src");
const typedFieldInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_field_invalid_out");
const typedParamsInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_params_invalid_src");
const typedParamsInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_params_invalid_out");
const typedParamsUnknownSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_params_unknown_src");
const typedParamsUnknownOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_params_unknown_out");
const migrationDuplicateTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_table_src");
const migrationDuplicateTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_table_out");
const migrationDuplicateFileSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_file_src");
const migrationDuplicateFileOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_file_out");
const migrationNonModelSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_non_model_src");
const migrationNonModelOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_non_model_out");
const migrationBadTimestampSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_bad_timestamp_src");
const migrationBadTimestampOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_bad_timestamp_out");
const migrationUnknownOptionSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_option_src");
const migrationUnknownOptionOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_option_out");
const migrationBadOperationSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_bad_operation_src");
const migrationBadOperationOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_bad_operation_out");
const migrationUnsafeSqlSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_sql_src");
const migrationUnsafeSqlOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_sql_out");
const migrationDuplicateTimestampSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_timestamp_src");
const migrationDuplicateTimestampOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_duplicate_timestamp_out");
const migrationForeignKeyOrderSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_foreign_key_order_src");
const migrationForeignKeyOrderOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_foreign_key_order_out");
const migrationIrreversibleOperationSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_irreversible_operation_src");
const migrationIrreversibleOperationOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_irreversible_operation_out");
const migrationUnknownTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_table_src");
const migrationUnknownTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_table_out");
const migrationUnknownColumnSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_column_src");
const migrationUnknownColumnOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unknown_column_out");
const migrationExternalTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_external_table_src");
const migrationExternalTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_external_table_out");
const migrationUnsafeExternalTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_external_table_src");
const migrationUnsafeExternalTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_unsafe_external_table_out");
const migrationDropTableSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_drop_table_src");
const migrationDropTableOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_drop_table_out");
const migrationSnapshotOpsSourceDir = join(root, "test", ".generated", "todoapp_rails_migration_snapshot_ops_src");
const migrationSnapshotOpsOutputDir = join(root, "test", ".generated", "todoapp_rails_migration_snapshot_ops_out");
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
rmSync(rawErbInvalidSourceDir, { force: true, recursive: true });
rmSync(rawErbInvalidOutputDir, { force: true, recursive: true });
rmSync(typedTemplateInvalidSourceDir, { force: true, recursive: true });
rmSync(typedTemplateInvalidOutputDir, { force: true, recursive: true });
rmSync(typedPartialInvalidSourceDir, { force: true, recursive: true });
rmSync(typedPartialInvalidOutputDir, { force: true, recursive: true });
rmSync(typedRouteInvalidSourceDir, { force: true, recursive: true });
rmSync(typedRouteInvalidOutputDir, { force: true, recursive: true });
rmSync(typedRouteParamInvalidSourceDir, { force: true, recursive: true });
rmSync(typedRouteParamInvalidOutputDir, { force: true, recursive: true });
rmSync(typedFormInvalidSourceDir, { force: true, recursive: true });
rmSync(typedFormInvalidOutputDir, { force: true, recursive: true });
rmSync(typedSlotInvalidSourceDir, { force: true, recursive: true });
rmSync(typedSlotInvalidOutputDir, { force: true, recursive: true });
rmSync(templateRefInvalidSourceDir, { force: true, recursive: true });
rmSync(templateRefInvalidOutputDir, { force: true, recursive: true });
rmSync(templatePathInvalidSourceDir, { force: true, recursive: true });
rmSync(templatePathInvalidOutputDir, { force: true, recursive: true });
rmSync(templateBackslashPathInvalidSourceDir, { force: true, recursive: true });
rmSync(templateBackslashPathInvalidOutputDir, { force: true, recursive: true });
rmSync(rawLayoutInvalidSourceDir, { force: true, recursive: true });
rmSync(rawLayoutInvalidOutputDir, { force: true, recursive: true });
rmSync(typedFieldInvalidSourceDir, { force: true, recursive: true });
rmSync(typedFieldInvalidOutputDir, { force: true, recursive: true });
rmSync(typedParamsInvalidSourceDir, { force: true, recursive: true });
rmSync(typedParamsInvalidOutputDir, { force: true, recursive: true });
rmSync(typedParamsUnknownSourceDir, { force: true, recursive: true });
rmSync(typedParamsUnknownOutputDir, { force: true, recursive: true });
rmSync(migrationDuplicateTableSourceDir, { force: true, recursive: true });
rmSync(migrationDuplicateTableOutputDir, { force: true, recursive: true });
rmSync(migrationDuplicateFileSourceDir, { force: true, recursive: true });
rmSync(migrationDuplicateFileOutputDir, { force: true, recursive: true });
rmSync(migrationNonModelSourceDir, { force: true, recursive: true });
rmSync(migrationNonModelOutputDir, { force: true, recursive: true });
rmSync(migrationBadTimestampSourceDir, { force: true, recursive: true });
rmSync(migrationBadTimestampOutputDir, { force: true, recursive: true });
rmSync(migrationUnknownOptionSourceDir, { force: true, recursive: true });
rmSync(migrationUnknownOptionOutputDir, { force: true, recursive: true });
rmSync(migrationBadOperationSourceDir, { force: true, recursive: true });
rmSync(migrationBadOperationOutputDir, { force: true, recursive: true });
rmSync(migrationUnsafeSqlSourceDir, { force: true, recursive: true });
rmSync(migrationUnsafeSqlOutputDir, { force: true, recursive: true });
rmSync(migrationDuplicateTimestampSourceDir, { force: true, recursive: true });
rmSync(migrationDuplicateTimestampOutputDir, { force: true, recursive: true });
rmSync(migrationForeignKeyOrderSourceDir, { force: true, recursive: true });
rmSync(migrationForeignKeyOrderOutputDir, { force: true, recursive: true });
rmSync(migrationIrreversibleOperationSourceDir, { force: true, recursive: true });
rmSync(migrationIrreversibleOperationOutputDir, { force: true, recursive: true });
rmSync(migrationUnknownTableSourceDir, { force: true, recursive: true });
rmSync(migrationUnknownTableOutputDir, { force: true, recursive: true });
rmSync(migrationUnknownColumnSourceDir, { force: true, recursive: true });
rmSync(migrationUnknownColumnOutputDir, { force: true, recursive: true });
rmSync(migrationExternalTableSourceDir, { force: true, recursive: true });
rmSync(migrationExternalTableOutputDir, { force: true, recursive: true });
rmSync(migrationUnsafeExternalTableSourceDir, { force: true, recursive: true });
rmSync(migrationUnsafeExternalTableOutputDir, { force: true, recursive: true });
rmSync(migrationDropTableSourceDir, { force: true, recursive: true });
rmSync(migrationDropTableOutputDir, { force: true, recursive: true });
rmSync(migrationSnapshotOpsSourceDir, { force: true, recursive: true });
rmSync(migrationSnapshotOpsOutputDir, { force: true, recursive: true });

exportTodoHooksForPlaywright();

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile todoapp_rails through Reflaxe.");
  process.exit(1);
}

for (const file of [
  "app/haxe_gen/models/todo.rb",
  "app/haxe_gen/models/user.rb",
  "app/haxe_gen/controllers/todo_index_locals.rb",
  "app/haxe_gen/controllers/todos_controller.rb",
  "app/haxe_gen/migrations/create_todos.rb",
  "app/haxe_gen/migrations/update_todos.rb",
  "app/haxe_gen/views/application_layout_view.rb",
  "app/haxe_gen/views/todo_card_view.rb",
  "app/haxe_gen/views/todo_composer_view.rb",
  "app/haxe_gen/views/todo_dashboard_view.rb",
  "app/haxe_gen/views/todo_form_view.rb",
  "app/haxe_gen/views/todo_index_view.rb",
  "app/haxe_gen/views/todo_list_view.rb",
  "app/haxe_gen/views/todo_summary_view.rb",
  "app/views/controllers/todos/index.html.erb",
  "app/views/controllers/todos/_card.html.erb",
  "app/views/controllers/todos/_composer.html.erb",
  "app/views/controllers/todos/_dashboard.html.erb",
  "app/views/controllers/todos/_list.html.erb",
  "app/views/controllers/todos/_summary.html.erb",
  "app/views/controllers/todos/_typed_form.html.erb",
  "app/views/layouts/application.html.erb",
  "config/routes.rb",
  "db/migrate/20260101000000_create_todos.rb",
  "db/migrate/20260101000001_update_todos.rb",
  "test/generated/models/todo_haxe_test.rb",
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
  "class Todo < ::ApplicationRecord",
  'self.table_name = "todos"',
  "def self.__hx_rails_schema()",
  'table_name: "todos"',
  "timestamps: true",
  "{name: :id, haxe_name: \"id\", ruby_name: \"id\", haxe_type: \"Int\", rails_type: :bigint, nullable: false, default: nil, primary_key: true, index: false, unique: false, db_type: :bigint}",
  "{name: :title, haxe_name: \"title\", ruby_name: \"title\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "{name: :notes, haxe_name: \"notes\", ruby_name: \"notes\", haxe_type: \"String\", rails_type: :text, nullable: false, default: \"\", primary_key: false, index: false, unique: false, db_type: :text}",
  "{name: :is_completed, haxe_name: \"isCompleted\", ruby_name: \"is_completed\", haxe_type: \"Bool\", rails_type: :boolean, nullable: false, default: false, primary_key: false, index: false, unique: false, db_type: nil}",
  "{name: :user_id, haxe_name: \"userId\", ruby_name: \"user_id\", haxe_type: \"Int\", rails_type: :integer, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "def self.typed_column_count()",
  "__hx_rails_schema()[:columns].length",
  "belongs_to :user",
  "# haxe column id: Int",
  "# haxe column title: String",
  "# haxe column notes: String",
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
  "class User < ::ApplicationRecord",
  'self.table_name = "users"',
  "def self.__hx_rails_schema()",
  'table_name: "users"',
  "timestamps: true",
  "{name: :id, haxe_name: \"id\", ruby_name: \"id\", haxe_type: \"Int\", rails_type: :bigint, nullable: false, default: nil, primary_key: true, index: false, unique: false, db_type: :bigint}",
  "{name: :name, haxe_name: \"name\", ruby_name: \"name\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "{name: :email, haxe_name: \"email\", ruby_name: \"email\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "{name: :role, haxe_name: \"role\", ruby_name: \"role\", haxe_type: \"String\", rails_type: :string, nullable: false, default: \"member\", primary_key: false, index: true, unique: false, db_type: nil}",
  "has_many :todos",
  "# haxe column id: Int",
  "# haxe column name: String",
  "# haxe column email: String",
  "# haxe column role: String",
  "validates :name, presence: true",
  "validates :email, presence: true",
  "def role_label()",
  "def initials()",
  "trimmed__hx0[0, 1].upcase()",
]) {
  if (!userRuby.includes(expected)) {
    console.error(`todoapp_rails user model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const haxeAuthoredTestRuby = readFileSync(join(outputDir, "test", "generated", "models", "todo_haxe_test.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsTest.",
  'require "test_helper"',
  "class TodoHaxeTest < ActiveSupport::TestCase",
  'test "typed incomplete scope returns typed titles" do',
  'user__hx0 = Models::User.create(name: "haxe test owner", email: "haxe-test-owner@example.test", role: "admin")',
  'Models::Todo.create(title: "ship haxe tests", notes: "generated Minitest", is_completed: false, user_id: user__hx0.id)',
  'Models::Todo.create(title: "hide completed work", notes: "done", is_completed: true, user_id: user__hx0.id)',
  'assert_equal(["ship haxe tests"], Models::Todo.incomplete().pluck(:title))',
]) {
  if (!haxeAuthoredTestRuby.includes(expected)) {
    console.error(`todoapp_rails Haxe-authored test output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const generatedRoutes = readFileSync(join(outputDir, "config", "routes.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsRoutes.",
  "# Source: routes.AppRoutes",
  "Rails.application.routes.draw do",
  'root "controllers/todos#index"',
  'resources :todos, controller: "controllers/todos", only: [:index, :create]',
  'get "users", to: "controllers/users#index", as: :users',
  'post "session", to: "controllers/sessions#create", as: :sign_in',
  'delete "session", to: "controllers/sessions#destroy", as: :sign_out',
]) {
  if (!generatedRoutes.includes(expected)) {
    console.error(`todoapp_rails generated routes missing expected line: ${expected}`);
    process.exit(1);
  }
}

const committedRoutesExtern = readFileSync(join(exampleDir, "src_haxe", "routes", "Routes.hx"), "utf8");
for (const expected of [
  '@:native("users_path")',
  "public static function usersPath():String;",
  '@:native("sign_in_path")',
  "public static function signInPath():String;",
  '@:native("sign_out_path")',
  "public static function signOutPath():String;",
  '@:native("legacy_health_path")',
  "public static function legacyHealthPath():String;",
]) {
  if (!committedRoutesExtern.includes(expected)) {
    console.error(`todoapp_rails route extern missing typed Rails-owned route helper: ${expected}`);
    process.exit(1);
  }
}

const controllerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "controllers", "todos_controller.rb"), "utf8");
for (const expected of [
  /require "action_controller\/railtie"/,
  /module Controllers/,
  /class TodosController < ActionController::Base/,
  /todos__hx\d+ = Models::Todo\.incomplete\(\)\.includes\(:user\)\.order\(title: :asc\)\.limit\(10\)\.to_a\(\)/,
  /users__hx\d+ = Models::User\.order\(name: :asc\)\.to_a\(\)/,
  /current_user__hx\d+ = Controllers::UserSession\.current_user\(self\)/,
  /self\.render\(template: "controllers\/todos\/index", locals: \{todos: todos__hx\d+, users: users__hx\d+, todo_count: todos__hx\d+\.length, typed_column_count: Models::Todo\.typed_column_count\(\), sample_user: current_user__hx\d+, current_user: current_user__hx\d+\}, layout: "application"\)/,
  /attrs__hx\d+ = self\.params\(\)\.require\("todo"\)\.permit\(\[:title, :notes, :user_id\]\)/,
  /todo__hx\d+ = Models::Todo\.create\(attrs__hx\d+\)/,
  /self\.respond_to\(\) do \|format__hx\d+\|/,
  /format__hx\d+\.turbo_stream\(\) \{ gthis__hx\d+\.render\(turbo_stream: turbo_stream\.replace\("railshx-todo-list", partial: "controllers\/todos\/list", locals: \{todos: Models::Todo\.incomplete\(\)\.includes\(:user\)\.order\(title: :asc\)\.limit\(10\)\.to_a\(\)\}\)\) \}/,
  /format__hx\d+\.html\(\) \{ gthis__hx\d+\.redirect_to\(self\.todos_path\(\), status: :see_other\) \}/,
]) {
  if (!expected.test(controllerRuby)) {
    console.error(`todoapp_rails controller output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const sessionsControllerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "controllers", "sessions_controller.rb"), "utf8");
for (const expected of [
  /class SessionsController < ActionController::Base/,
  /user_params__hx\d+ = self\.params\(\)\.require\("user"\)/,
  /self\.params\(\)\.require\("user"\)\.permit\(\[:id\]\)/,
  /user__hx\d+ = Models::User\.find\(user_params__hx\d+\[:id\]\)/,
  /self\.session\(\)\[:current_user_id\] = user__hx\d+\.id/,
  /self\.flash\(\)\[:notice\] = \("Signed in as " \+ user__hx\d+\.name\)/,
  /self\.session\(\)\.delete\(:current_user_id\)/,
  /format__hx\d+\.turbo_stream\(\) \{ gthis__hx\d+\.render\(turbo_stream: turbo_stream\.replace\("railshx-session-panel", partial: "controllers\/todos\/user_switcher", locals: \{users: Models::User\.order\(name: :asc\)\.to_a\(\), current_user: user__hx\d+\}\)\) \}/,
  /format__hx\d+\.turbo_stream\(\) \{ gthis__hx\d+\.render\(turbo_stream: turbo_stream\.replace\("railshx-session-panel", partial: "controllers\/todos\/user_switcher", locals: \{users: Models::User\.order\(name: :asc\)\.to_a\(\), current_user: nil\}\)\) \}/,
  /format__hx\d+\.html\(\) \{ gthis__hx\d+\.redirect_to\(self\.todos_path\(\), status: :see_other\) \}/,
]) {
  if (!expected.test(sessionsControllerRuby)) {
    console.error(`todoapp_rails sessions controller output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const usersControllerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "controllers", "users_controller.rb"), "utf8");
for (const expected of [
  /class UsersController < ActionController::Base/,
  /users__hx\d+ = Models::User\.order\(name: :asc\)\.to_a\(\)/,
  /self\.render\(template: "controllers\/users\/index", locals: \{users: users__hx\d+, current_user: Controllers::UserSession\.current_user\(self\)\}, layout: "application"\)/,
]) {
  if (!expected.test(usersControllerRuby)) {
    console.error(`todoapp_rails users controller output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const migrationClassRuby = readFileSync(join(outputDir, "app", "haxe_gen", "migrations", "create_todos.rb"), "utf8");
for (const expected of [
  "module Migrations",
  "class CreateTodos",
  'def self.__hx_name()',
  '"migrations.CreateTodos"',
]) {
  if (!migrationClassRuby.includes(expected)) {
    console.error(`todoapp_rails migration marker output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const updateMigrationClassRuby = readFileSync(join(outputDir, "app", "haxe_gen", "migrations", "update_todos.rb"), "utf8");
for (const expected of [
  "module Migrations",
  "class UpdateTodos",
  'def self.__hx_name()',
  '"migrations.UpdateTodos"',
]) {
  if (!updateMigrationClassRuby.includes(expected)) {
    console.error(`todoapp_rails update migration marker output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const migrationRuby = readFileSync(join(outputDir, "db", "migrate", "20260101000000_create_todos.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsMigration.",
  "class CreateTodos < ActiveRecord::Migration[7.1]",
  "create_table :users do |t|",
  "t.string :name, null: false",
  "t.index [:name]",
  "create_table :todos do |t|",
  "t.string :title, null: false",
  't.text :notes, null: false, default: ""',
  "t.boolean :is_completed, null: false, default: false",
  "t.references :user, null: false, foreign_key: true",
  "t.index [:title]",
]) {
  if (!migrationRuby.includes(expected)) {
    console.error(`todoapp_rails generated migration missing expected line: ${expected}`);
    process.exit(1);
  }
}

const updateMigrationRuby = readFileSync(join(outputDir, "db", "migrate", "20260101000001_update_todos.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsMigration.",
  "class UpdateTodos < ActiveRecord::Migration[7.1]",
  "change_column :todos, :title, :string, null: false",
  "reversible do |dir|",
  "dir.up do",
  "add_foreign_key :todos, :users, column: :user_id, on_delete: :cascade",
  "dir.down do",
  "remove_foreign_key :todos, :users",
  "change_column :todos, :title, :string",
  "add_column :todos, :priority, :integer, null: false, default: 0",
  "add_index :todos, :priority",
  "add_index :todos, [:user_id, :priority]",
  "execute \"UPDATE todos SET priority = 0 WHERE priority IS NULL\"",
  "execute \"UPDATE todos SET priority = NULL WHERE priority = 0\"",
]) {
  if (!updateMigrationRuby.includes(expected)) {
    console.error(`todoapp_rails generated update migration missing expected line: ${expected}`);
    process.exit(1);
  }
}

const readme = readFileSync(join(exampleDir, "README.md"), "utf8");
for (const expected of [
  "RailsHx Todo App",
  "self.__hx_rails_schema",
  "ParamsMacro.requirePermit",
  "ViewMacro.renderTemplate",
  "Haxe-authored Rails migration",
  "<text_area>",
  "Haxe-authored JavaScript",
]) {
  if (!readme.includes(expected)) {
    console.error(`todoapp_rails README missing expected line: ${expected}`);
    process.exit(1);
  }
}

const layoutSource = readFileSync(join(exampleDir, "views", "ApplicationLayoutView.hx"), "utf8");
for (const expected of [
  '@:railsTemplate("layouts/application")',
  '@:railsTemplateAst("render")',
  "<doctype_html />",
  "<csrf_meta_tags />",
  '<yield_content name="head" />',
  '<stylesheet_link_tag name="application" data-turbo-track="reload" />',
  "<javascript_importmap_tags />",
  "<rails_yield />",
]) {
  if (!layoutSource.includes(expected)) {
    console.error(`todoapp_rails layout source is missing expected HHX content: ${expected}`);
    process.exit(1);
  }
}
for (const forbidden of ["public static var body", "public static var erb", "public static var template", "<%"]) {
  if (layoutSource.includes(forbidden)) {
    console.error(`todoapp_rails layout source must stay HHX-first and cannot contain: ${forbidden}`);
    process.exit(1);
  }
}

const indexSource = readFileSync(join(exampleDir, "views", "TodoIndexView.hx"), "utf8");
for (const expected of [
  '@:railsTemplateAst("render")',
  "return <>",
  '<content_for name=${TodoHooks.headSlot}>',
  '<meta name=${TodoHooks.templateMetaName} content=${TodoHooks.templateMetaContent} />',
  '<main class=${TodoHooks.shellClass}>',
  '<partial template=${(Template.of(TodoComposerView)',
  '<partial template=${(Template.of(TodoListView)',
  '<partial template=${(Template.of(TodoDashboardView)',
]) {
  if (!indexSource.includes(expected)) {
    console.error(`todoapp_rails index source is missing expected HHX content: ${expected}`);
    process.exit(1);
  }
}
for (const forbidden of [
  "@:railsAllowRawErb",
  "public static var body",
  "public static var erb",
  "public static var template",
  "<%",
  "<%=",
]) {
  if (indexSource.includes(forbidden)) {
    console.error(`todoapp_rails index source must stay HHX-first and cannot contain: ${forbidden}`);
    process.exit(1);
  }
}

const routesSource = readFileSync(join(exampleDir, "src_haxe", "routes", "AppRoutes.hx"), "utf8");
for (const expected of [
  "@:railsRoutes",
  "static final routes = {",
  "root(to(TodosController, index));",
  "resources(Todo, TodosController, {only: [index, create]});",
  'get("users", to(UsersController, index), {asName: routeName("users")});',
  'post("session", to(SessionsController, create), {asName: routeName("sign_in")});',
  'delete("session", to(SessionsController, destroy), {asName: routeName("sign_out")});',
]) {
  if (!routesSource.includes(expected)) {
    console.error(`todoapp_rails route source is missing expected Haxe-owned route content: ${expected}`);
    process.exit(1);
  }
}
for (const forbidden of ['"controllers/todos#index"', 'writeFile("config/routes.rb"']) {
  if (routesSource.includes(forbidden)) {
    console.error(`todoapp_rails Haxe route source should use typed route declarations, not raw route output: ${forbidden}`);
    process.exit(1);
  }
}

const hooksSource = readFileSync(join(exampleDir, "shared", "TodoHooks.hx"), "utf8");
for (const expected of [
  "class TodoHooks",
  "abstract CssClass(String)",
  'public static inline var formClass:CssClass = "todo-form";',
  'public static inline var sessionFormClass:CssClass = "session-form";',
  'public static inline var sessionFooterClass:CssClass = "session-footer";',
  'public static inline var openWorkId:DomId = "open-work";',
  'public static inline var boundAttr:DataAttr = "data-railshx-bound";',
  'public static inline var sessionAttr:DataAttr = "data-railshx-session";',
  "public static inline function classSelector",
]) {
  if (!hooksSource.includes(expected)) {
    console.error(`todoapp_rails hook source missing expected typed hook content: ${expected}`);
    process.exit(1);
  }
}

const hookExportSource = readFileSync(join(exampleDir, "tools", "ExportTodoHooks.hx"), "utf8");
for (const expected of [
  "import shared.TodoHooks;",
  "examples/todoapp_rails/e2e/todo_hooks.ts",
  "TodoHooks.classSelector(TodoHooks.formClass)",
]) {
  if (!hookExportSource.includes(expected)) {
    console.error(`todoapp_rails hook exporter missing expected content: ${expected}`);
    process.exit(1);
  }
}

const hookSpecSource = readFileSync(join(exampleDir, "e2e", "todoapp.spec.ts"), "utf8");
for (const expected of [
  "import { hooks } from './todo_hooks'",
  "hooks.selectors.form",
  "hooks.selectors.sessionForms",
  "hooks.selectors.sessionFooter",
  "hooks.attrs.bound",
  "hooks.selectors.openWork",
]) {
  if (!hookSpecSource.includes(expected)) {
    console.error(`todoapp_rails Playwright spec missing generated hook usage: ${expected}`);
    process.exit(1);
  }
}

const hookManifest = readFileSync(join(exampleDir, "e2e", "todo_hooks.ts"), "utf8");
for (const expected of [
  "// Generated by examples/todoapp_rails/tools/ExportTodoHooks.hx.",
  'form: "todo-form"',
  'sessionForm: "session-form"',
  'sessionFooter: "session-footer"',
  'scrollLinks: "[data-railshx-scroll]"',
  'sessionForms: ".session-form"',
  'sessionFooter: ".session-footer"',
  'openWork: "#open-work"',
]) {
  if (!hookManifest.includes(expected)) {
    console.error(`todoapp_rails generated Playwright hook manifest missing expected content: ${expected}`);
    process.exit(1);
  }
}

const view = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "index.html.erb"), "utf8");
for (const expected of [
  "RailsHx sample",
  "Typed Rails, polished Ruby.",
  "<% content_for :head do %>",
  '<meta name="railshx-template" content="todo-index">',
  "<%= todo_count %>",
  "<%= typed_column_count %>",
  '<%= render partial: "controllers/todos/user_switcher", locals: {users: users, current_user: current_user} %>',
  '<%= render partial: "controllers/todos/composer", locals: {sample_user: sample_user} %>',
  '<%= render partial: "controllers/todos/list", locals: {todos: todos} %>',
  "todo-shell",
  '<%= render partial: "controllers/todos/dashboard", locals: {todos: todos, users: users, todo_count: todo_count, typed_column_count: typed_column_count, sample_user: sample_user, current_user: current_user} %>',
]) {
  if (!view.includes(expected)) {
    console.error(`todoapp_rails view missing expected content: ${expected}`);
    process.exit(1);
  }
}

const layoutView = readFileSync(join(outputDir, "app", "views", "layouts", "application.html.erb"), "utf8");
for (const expected of [
  "<!DOCTYPE html>",
  "<title>RailsHx Todoapp</title>",
  '<%= csrf_meta_tags %>',
  '<%= csp_meta_tag %>',
  '<%= yield :head %>',
  '<%= stylesheet_link_tag "application", data: {turbo_track: "reload"} %>',
  '<%= javascript_importmap_tags %>',
  '<%= yield %>',
]) {
  if (!layoutView.includes(expected)) {
    console.error(`todoapp_rails layout output missing expected content: ${expected}`);
    process.exit(1);
  }
}
for (const forbidden of ["<% todos ||= [] %>", "<% sample_user = Models::User.order(:id).first %>", "controllers/todos/hero"]) {
  if (view.includes(forbidden)) {
    console.error(`todoapp_rails HHX index should not contain raw shell content: ${forbidden}`);
    process.exit(1);
  }
}

const typedPartial = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_summary.html.erb"), "utf8");
for (const expected of [
  "Typed template partial",
  "typed Rails HHX",
  "<%= todos.length %>",
  "<% if todos.length == 0 %>",
  "No typed HHX todos yet.",
  "<% else %>",
  "<% todos.each do |todo| %>",
  "<%= todo.title %>",
  "<%= todo.notes %>",
  "typed-template-card",
]) {
  if (!typedPartial.includes(expected)) {
    console.error(`todoapp_rails typed template partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedCard = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_card.html.erb"), "utf8");
for (const expected of [
  '<span class="eyebrow"><%= eyebrow %></span>',
  "<h2><%= title %></h2>",
  "<%= body %>",
  "typed-dashboard",
]) {
  if (!typedCard.includes(expected)) {
    console.error(`todoapp_rails typed card component missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedDashboard = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_dashboard.html.erb"), "utf8");
for (const expected of [
  "<% railshx_component_body = capture do %>",
  '<%= link_to "#open-work", class: "typed-route-link", data: {railshx_scroll: true} do %>',
  '<%= link_to legacy_health_path(), class: "typed-route-link rails-owned-route-link" do %>',
  "Rails-owned route, typed in Haxe",
  '<span><%= (if todos.length > 0 then "Jump to open work" else "Jump to the empty state" end) %></span>',
  '<span class="typed-route-count"><%= todos.length %></span>',
  '<% end %>',
  '<%= render partial: "controllers/todos/summary", locals: {todos: todos} %>',
  '<%= render partial: "controllers/todos/card", locals: {eyebrow: "Composed typed component", title: "One typed component, reused by Rails.", body: railshx_component_body} %>',
]) {
  if (!typedDashboard.includes(expected)) {
    console.error(`todoapp_rails typed dashboard partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedComposer = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_composer.html.erb"), "utf8");
for (const expected of [
  "<% if sample_user != nil %>",
  '<%= render partial: "controllers/todos/typed_form", locals: {sample_user_id: sample_user.id} %>',
  "<% else %>",
  "Create a user first; the integration fixture seeds one before exercising this page.",
]) {
  if (!typedComposer.includes(expected)) {
    console.error(`todoapp_rails typed composer partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedList = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_list.html.erb"), "utf8");
for (const expected of [
  "<% if todos.length > 0 %>",
  '<ul id="railshx-todo-list" class="todo-list">',
  "<% todos.each do |todo| %>",
  '<li class="todo-item">',
  "<%= todo.title %>",
  "<%= todo.notes %>",
  "<% else %>",
  "No open tasks. Serene, but suspicious.",
]) {
  if (!typedList.includes(expected)) {
    console.error(`todoapp_rails typed list partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedForm = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_typed_form.html.erb"), "utf8");
for (const expected of [
  '<%= form_with url: todos_path(), scope: :todo, local: true, class: "todo-form" do |form| %>',
  '<%= form.hidden_field :user_id, value: sample_user_id %>',
  '<%= form.label :title, "What should ship next?" %>',
  '<%= form.text_field :title, placeholder: "Write the HHX form DSL", required: true %>',
  '<%= form.label :notes, "Why does it matter?" %>',
  '<%= form.text_area :notes, placeholder: "Add a short implementation note", rows: 3 %>',
  '<%= form.submit "Add task", type: "submit" %>',
]) {
  if (!typedForm.includes(expected)) {
    console.error(`todoapp_rails typed form partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedUserSwitcher = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "_user_switcher.html.erb"), "utf8");
for (const expected of [
  "Typed session layer",
  "Choose a demo user",
  '<%= link_to users_path(), class: "typed-route-link team-route-link" do %>',
  '<div class="team-members" data-railshx-session-zone>',
  "<% users.each do |user| %>",
  '<%= form_with url: sign_in_path(), scope: :user, local: true, class: "session-form", data: {railshx_session: true} do |form| %>',
  "<%= form.hidden_field :id, value: user.id %>",
  '<span class="avatar"><%= user.initials() %></span>',
  "<strong><%= user.name %></strong>",
  "<span><%= user.email %></span>",
  '<span class="role-pill"><%= user.role_label() %></span>',
  '<%= form_with url: sign_out_path(), scope: :session, method: "delete", local: true, class: "session-clear-form", data: {railshx_session: true} do |form| %>',
  '<%= form.submit "Clear session", type: "submit" %>',
]) {
  if (!typedUserSwitcher.includes(expected)) {
    console.error(`todoapp_rails typed user switcher partial missing expected content: ${expected}`);
    process.exit(1);
  }
}

const typedUsersPage = readFileSync(join(outputDir, "app", "views", "controllers", "users", "index.html.erb"), "utf8");
for (const expected of [
  "RailsHx user management",
  "Typed users, ordinary Rails output.",
  '<%= link_to todos_path(), class: "typed-route-link" do %>',
  "<% users.each do |user| %>",
  '<span class="avatar"><%= user.initials() %></span>',
  "<h2><%= user.name %></h2>",
  "<p><%= user.email %></p>",
  '<span class="role-pill"><%= user.role_label() %></span>',
]) {
  if (!typedUsersPage.includes(expected)) {
    console.error(`todoapp_rails typed users page missing expected content: ${expected}`);
    process.exit(1);
  }
}

expectInvalidTemplateLocalsFailure();
expectRawErbRequiresOptInFailure();
expectTypedTemplateAstFieldFailure();
expectTypedPartialLocalsFailure();
expectTypedRouteHelperFailure();
expectTypedRouteParamFailure();
expectTypedFormFieldRequiresFormFailure();
expectTypedSlotContentRequiresComponentFailure();
expectTemplateOfRequiresRailsTemplateFailure();
expectUnsafeRailsTemplatePathFailure();
expectBackslashRailsTemplatePathFailure();
expectRawLayoutStringFailure();
expectUnknownTypedFormFieldFailure();
expectUnknownStrongParamsFieldFailure();
expectMixedModelStrongParamsFailure();
expectMigrationDuplicateTableFailure();
expectMigrationDuplicateFileFailure();
expectMigrationNonModelFailure();
expectMigrationBadTimestampFailure();
expectMigrationUnknownOptionFailure();
expectMigrationBadOperationFailure();
expectMigrationUnsafeSqlFailure();
expectMigrationDuplicateTimestampFailure();
expectMigrationForeignKeyOrderFailure();
expectMigrationIrreversibleOperationFailure();
expectMigrationUnknownTableFailure();
expectMigrationUnknownColumnFailure();
expectMigrationExternalTableAllowed();
expectMigrationUnsafeExternalTableFailure();
expectMigrationDropTableReversibleOutput();
expectMigrationSnapshotOperationsOutput();

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

function exportTodoHooksForPlaywright() {
  run("haxe", [
    "-cp",
    exampleDir,
    "-main",
    "tools.ExportTodoHooks",
    "--interp",
  ]);
}

function expectInvalidMigrationCompile(sourceDir, invalidOutputDir, mainClass, successMessage, expectedDiagnostic) {
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
      exampleDir,
      "-cp",
      sourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      mainClass,
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error(successMessage);
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes(expectedDiagnostic)) {
      console.error(`Invalid migration failed, but not with the expected diagnostic: ${expectedDiagnostic}`);
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid migration check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function compileValidMigration(sourceDir, validOutputDir, mainClass) {
  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${validOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      sourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      mainClass,
    ], { allowFailure: true });
    if (result.status === 0) {
      return;
    }
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  if (!sawCandidate) {
    console.error("Unable to run valid migration check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectMigrationDuplicateTableFailure() {
  mkdirSync(join(migrationDuplicateTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationDuplicateTableSourceDir, "InvalidDuplicateTableMain.hx"), [
    "import migrations.BadDuplicateTable;",
    "",
    "class InvalidDuplicateTableMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadDuplicateTable> = BadDuplicateTable;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateTableSourceDir, "migrations", "BadDuplicateTable.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000001\",",
    "\tclassName: \"BadDuplicateTable\",",
    "\tmodels: [\"models.User\", \"models.User\"]",
    "})",
    "class BadDuplicateTable extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationDuplicateTableSourceDir,
    migrationDuplicateTableOutputDir,
    "InvalidDuplicateTableMain",
    "Duplicate-table RailsHx migration compiled successfully.",
    "@:railsMigration cannot create table \"users\" more than once"
  );
}

function expectMigrationDuplicateFileFailure() {
  mkdirSync(join(migrationDuplicateFileSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationDuplicateFileSourceDir, "InvalidDuplicateFileMain.hx"), [
    "import migrations.BadDuplicateFileA;",
    "import migrations.BadDuplicateFileB;",
    "",
    "class InvalidDuplicateFileMain {",
    "\tstatic function main() {",
    "\t\tvar first:Class<BadDuplicateFileA> = BadDuplicateFileA;",
    "\t\tvar second:Class<BadDuplicateFileB> = BadDuplicateFileB;",
    "\t\tSys.println(first != null && second != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateFileSourceDir, "migrations", "BadDuplicateFileA.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000002\",",
    "\tclassName: \"BadDuplicateFile\",",
    "\tmodels: [\"models.User\"]",
    "})",
    "class BadDuplicateFileA extends Migration {}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateFileSourceDir, "migrations", "BadDuplicateFileB.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000002\",",
    "\tclassName: \"BadDuplicateFile\",",
    "\tmodels: [\"models.Todo\"]",
    "})",
    "class BadDuplicateFileB extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationDuplicateFileSourceDir,
    migrationDuplicateFileOutputDir,
    "InvalidDuplicateFileMain",
    "Duplicate-file RailsHx migration compiled successfully.",
    "@:railsMigration emits duplicate migration file db/migrate/20260101000002_bad_duplicate_file.rb"
  );
}

function expectMigrationNonModelFailure() {
  mkdirSync(join(migrationNonModelSourceDir, "invalid"), { recursive: true });
  mkdirSync(join(migrationNonModelSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationNonModelSourceDir, "InvalidNonModelMigrationMain.hx"), [
    "import migrations.BadNonModelMigration;",
    "",
    "class InvalidNonModelMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadNonModelMigration> = BadNonModelMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationNonModelSourceDir, "invalid", "Plain.hx"), [
    "package invalid;",
    "",
    "class Plain {}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationNonModelSourceDir, "migrations", "BadNonModelMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000003\",",
    "\tclassName: \"BadNonModelMigration\",",
    "\tmodels: [\"invalid.Plain\"]",
    "})",
    "class BadNonModelMigration extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationNonModelSourceDir,
    migrationNonModelOutputDir,
    "InvalidNonModelMigrationMain",
    "Non-model RailsHx migration compiled successfully.",
    "@:railsMigration model \"invalid.Plain\" must be annotated with @:railsModel"
  );
}

function expectMigrationBadTimestampFailure() {
  mkdirSync(join(migrationBadTimestampSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationBadTimestampSourceDir, "InvalidBadTimestampMigrationMain.hx"), [
    "import migrations.BadTimestampMigration;",
    "",
    "class InvalidBadTimestampMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadTimestampMigration> = BadTimestampMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationBadTimestampSourceDir, "migrations", "BadTimestampMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"tomorrow\",",
    "\tclassName: \"BadTimestampMigration\",",
    "\tmodels: [\"models.User\"]",
    "})",
    "class BadTimestampMigration extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationBadTimestampSourceDir,
    migrationBadTimestampOutputDir,
    "InvalidBadTimestampMigrationMain",
    "Bad-timestamp RailsHx migration compiled successfully.",
    "@:railsMigration timestamp must be a 14-digit string"
  );
}

function expectMigrationUnknownOptionFailure() {
  mkdirSync(join(migrationUnknownOptionSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnknownOptionSourceDir, "InvalidUnknownOptionMigrationMain.hx"), [
    "import migrations.BadUnknownOptionMigration;",
    "",
    "class InvalidUnknownOptionMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadUnknownOptionMigration> = BadUnknownOptionMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnknownOptionSourceDir, "migrations", "BadUnknownOptionMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000004\",",
    "\tclassName: \"BadUnknownOptionMigration\",",
    "\tmodels: [\"models.User\"],",
    "\tmagic: true",
    "})",
    "class BadUnknownOptionMigration extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnknownOptionSourceDir,
    migrationUnknownOptionOutputDir,
    "InvalidUnknownOptionMigrationMain",
    "Unknown-option RailsHx migration compiled successfully.",
    "@:railsMigration unknown option magic"
  );
}

function expectMigrationBadOperationFailure() {
	mkdirSync(join(migrationBadOperationSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationBadOperationSourceDir, "InvalidBadOperationMigrationMain.hx"), [
    "import migrations.BadOperationMigration;",
    "",
    "class InvalidBadOperationMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadOperationMigration> = BadOperationMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationBadOperationSourceDir, "migrations", "BadOperationMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000005\",",
    "\tclassName: \"BadOperationMigration\",",
    "\tmodels: []",
    "})",
    "class BadOperationMigration extends Migration {",
    "\tstatic final tableName = \"todos\";",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddColumn(tableName, \"priority\", IntegerColumn({nullable: false}))",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationBadOperationSourceDir,
    migrationBadOperationOutputDir,
    "InvalidBadOperationMigrationMain",
    "Bad-operation RailsHx migration compiled successfully.",
    "@:railsMigration AddColumn table must be a non-empty String literal"
	);
}

function expectMigrationUnsafeSqlFailure() {
	mkdirSync(join(migrationUnsafeSqlSourceDir, "migrations"), { recursive: true });
	writeFileSync(join(migrationUnsafeSqlSourceDir, "InvalidUnsafeSqlMigrationMain.hx"), [
		"import migrations.BadUnsafeSqlMigration;",
		"",
		"class InvalidUnsafeSqlMigrationMain {",
		"\tstatic function main() {",
		"\t\tvar migration:Class<BadUnsafeSqlMigration> = BadUnsafeSqlMigration;",
		"\t\tSys.println(migration != null);",
		"\t}",
		"}",
		"",
	].join("\n"));
	writeFileSync(join(migrationUnsafeSqlSourceDir, "migrations", "BadUnsafeSqlMigration.hx"), [
		"package migrations;",
		"",
		"import rails.migration.Migration;",
		"import rails.migration.MigrationOperation;",
		"",
		"@:railsMigration({",
		"\ttimestamp: \"20260101000015\",",
		"\tclassName: \"BadUnsafeSqlMigration\",",
		"\tmodels: []",
		"})",
		"class BadUnsafeSqlMigration extends Migration {",
		"\tpublic static final operations:Array<MigrationOperation> = [",
		"\t\tExecuteSql(\"UPDATE todos SET title = 'x'\", \"\")",
		"\t];",
		"}",
		"",
	].join("\n"));
	expectInvalidMigrationCompile(
		migrationUnsafeSqlSourceDir,
		migrationUnsafeSqlOutputDir,
		"InvalidUnsafeSqlMigrationMain",
		"Unsafe-SQL RailsHx migration compiled successfully.",
		"@:railsMigration ExecuteSql expects non-empty literal up and rollback SQL strings."
	);
}

function expectMigrationDuplicateTimestampFailure() {
	mkdirSync(join(migrationDuplicateTimestampSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationDuplicateTimestampSourceDir, "InvalidDuplicateTimestampMigrationMain.hx"), [
    "import migrations.BadDuplicateTimestampA;",
    "import migrations.BadDuplicateTimestampB;",
    "",
    "class InvalidDuplicateTimestampMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar first:Class<BadDuplicateTimestampA> = BadDuplicateTimestampA;",
    "\t\tvar second:Class<BadDuplicateTimestampB> = BadDuplicateTimestampB;",
    "\t\tSys.println(first != null && second != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateTimestampSourceDir, "migrations", "BadDuplicateTimestampA.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000006\",",
    "\tclassName: \"BadDuplicateTimestampA\",",
    "\tmodels: [\"models.User\"]",
    "})",
    "class BadDuplicateTimestampA extends Migration {}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDuplicateTimestampSourceDir, "migrations", "BadDuplicateTimestampB.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000006\",",
    "\tclassName: \"BadDuplicateTimestampB\",",
    "\tmodels: [\"models.Todo\"]",
    "})",
    "class BadDuplicateTimestampB extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationDuplicateTimestampSourceDir,
    migrationDuplicateTimestampOutputDir,
    "InvalidDuplicateTimestampMigrationMain",
    "Duplicate-timestamp RailsHx migration compiled successfully.",
    "@:railsMigration timestamp 20260101000006 is already used"
  );
}

function expectMigrationForeignKeyOrderFailure() {
  mkdirSync(join(migrationForeignKeyOrderSourceDir, "models"), { recursive: true });
  mkdirSync(join(migrationForeignKeyOrderSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "InvalidForeignKeyOrderMigrationMain.hx"), [
    "import migrations.BadCreateTodosFirst;",
    "import migrations.BadCreateUsersLater;",
    "",
    "class InvalidForeignKeyOrderMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar todos:Class<BadCreateTodosFirst> = BadCreateTodosFirst;",
    "\t\tvar users:Class<BadCreateUsersLater> = BadCreateUsersLater;",
    "\t\tSys.println(todos != null && users != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "models", "LateUser.hx"), [
    "package models;",
    "",
    "import rails.ActiveRecord;",
    "",
    "@:railsModel(\"users\")",
    "class LateUser extends ActiveRecord {",
    "\t@:railsColumn({type: \"integer\", primaryKey: true})",
    "\tpublic var id:Int;",
    "",
    "\t@:railsColumn({type: \"string\", nullable: false})",
    "\tpublic var name:String;",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "models", "EarlyTodo.hx"), [
    "package models;",
    "",
    "import rails.ActiveRecord;",
    "",
    "@:railsModel(\"todos\")",
    "class EarlyTodo extends ActiveRecord {",
    "\t@:railsColumn({type: \"integer\", primaryKey: true})",
    "\tpublic var id:Int;",
    "",
    "\t@:railsColumn({type: \"string\", nullable: false})",
    "\tpublic var title:String;",
    "",
    "\t@:railsColumn({type: \"integer\", nullable: false})",
    "\tpublic var userId:Int;",
    "",
    "\t@:belongsTo public var user:rails.ActiveRecord.BelongsTo<LateUser>;",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "migrations", "BadCreateTodosFirst.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000007\",",
    "\tclassName: \"BadCreateTodosFirst\",",
    "\tmodels: [\"models.EarlyTodo\"]",
    "})",
    "class BadCreateTodosFirst extends Migration {}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationForeignKeyOrderSourceDir, "migrations", "BadCreateUsersLater.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000008\",",
    "\tclassName: \"BadCreateUsersLater\",",
    "\tmodels: [\"models.LateUser\"]",
    "})",
    "class BadCreateUsersLater extends Migration {}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationForeignKeyOrderSourceDir,
    migrationForeignKeyOrderOutputDir,
    "InvalidForeignKeyOrderMigrationMain",
    "Foreign-key-order RailsHx migration compiled successfully.",
    "@:railsMigration foreign key target table \"users\" is created"
  );
}

function expectMigrationIrreversibleOperationFailure() {
  mkdirSync(join(migrationIrreversibleOperationSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationIrreversibleOperationSourceDir, "InvalidIrreversibleOperationMigrationMain.hx"), [
    "import migrations.BadIrreversibleOperationMigration;",
    "",
    "class InvalidIrreversibleOperationMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadIrreversibleOperationMigration> = BadIrreversibleOperationMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationIrreversibleOperationSourceDir, "migrations", "BadIrreversibleOperationMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000009\",",
    "\tclassName: \"BadIrreversibleOperationMigration\",",
    "\tmodels: []",
    "})",
    "class BadIrreversibleOperationMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tChangeColumn(\"todos\", \"title\", StringColumn({nullable: false}))",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationIrreversibleOperationSourceDir,
    migrationIrreversibleOperationOutputDir,
    "InvalidIrreversibleOperationMigrationMain",
    "Irreversible-operation RailsHx migration compiled successfully.",
    "@:railsMigration ChangeColumn must be wrapped in Reversible(up, down)"
  );
}

function expectMigrationUnknownTableFailure() {
  mkdirSync(join(migrationUnknownTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnknownTableSourceDir, "InvalidUnknownTableMigrationMain.hx"), [
    "import migrations.BadUnknownTableMigration;",
    "",
    "class InvalidUnknownTableMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadUnknownTableMigration> = BadUnknownTableMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnknownTableSourceDir, "migrations", "BadUnknownTableMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates fail-closed table validation: knownModels gives the compiler",
    "// the existing typed schema, so misspelled table names are rejected before",
    "// Rails sees the migration.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000010\",",
    "\tclassName: \"BadUnknownTableMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class BadUnknownTableMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddIndex(\"todoss\", \"title\", {unique: false})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnknownTableSourceDir,
    migrationUnknownTableOutputDir,
    "InvalidUnknownTableMigrationMain",
    "Unknown-table RailsHx migration compiled successfully.",
    "@:railsMigration AddIndex table references unknown table \"todoss\""
  );
}

function expectMigrationUnknownColumnFailure() {
  mkdirSync(join(migrationUnknownColumnSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnknownColumnSourceDir, "InvalidUnknownColumnMigrationMain.hx"), [
    "import migrations.BadUnknownColumnMigration;",
    "",
    "class InvalidUnknownColumnMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<BadUnknownColumnMigration> = BadUnknownColumnMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnknownColumnSourceDir, "migrations", "BadUnknownColumnMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates fail-closed column validation: typed model metadata lets",
    "// RailsHx reject invalid index references while preserving Rails-shaped",
    "// string/symbol output in the generated migration.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000011\",",
    "\tclassName: \"BadUnknownColumnMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class BadUnknownColumnMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddIndex(\"todos\", \"missing_title\", {unique: false})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnknownColumnSourceDir,
    migrationUnknownColumnOutputDir,
    "InvalidUnknownColumnMigrationMain",
    "Unknown-column RailsHx migration compiled successfully.",
    "@:railsMigration AddIndex column references unknown column \"missing_title\" on table \"todos\""
  );
}

function expectMigrationExternalTableAllowed() {
  mkdirSync(join(migrationExternalTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationExternalTableSourceDir, "ExternalTableMigrationMain.hx"), [
    "import migrations.ExternalTableMigration;",
    "",
    "class ExternalTableMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<ExternalTableMigration> = ExternalTableMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationExternalTableSourceDir, "migrations", "ExternalTableMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates the Rails-owned table escape path: externalTables keeps",
    "// known typed models checked while allowing deliberate integration with",
    "// pre-existing/engine-owned Rails schema that Haxe does not own.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000012\",",
    "\tclassName: \"ExternalTableMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"],",
    "\texternalTables: [\"legacy_events\"]",
    "})",
    "class ExternalTableMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddIndex(\"legacy_events\", \"external_id\", {unique: true})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  compileValidMigration(
    migrationExternalTableSourceDir,
    migrationExternalTableOutputDir,
    "ExternalTableMigrationMain"
  );
  const migrationRuby = readFileSync(join(migrationExternalTableOutputDir, "db", "migrate", "20260101000012_external_table_migration.rb"), "utf8");
  if (!migrationRuby.includes("add_index :legacy_events, :external_id, unique: true")) {
    console.error("External-table migration did not emit the expected unchecked Rails index.");
    process.exit(1);
  }
}

function expectMigrationUnsafeExternalTableFailure() {
  mkdirSync(join(migrationUnsafeExternalTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationUnsafeExternalTableSourceDir, "UnsafeExternalTableMigrationMain.hx"), [
    "import migrations.UnsafeExternalTableMigration;",
    "",
    "class UnsafeExternalTableMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<UnsafeExternalTableMigration> = UnsafeExternalTableMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationUnsafeExternalTableSourceDir, "migrations", "UnsafeExternalTableMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000013\",",
    "\tclassName: \"UnsafeExternalTableMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"],",
    "\texternalTables: [\"../legacy/events\"]",
    "})",
    "class UnsafeExternalTableMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tAddIndex(\"legacy_events\", \"external_id\", {unique: true})",
    "\t];",
    "}",
    "",
  ].join("\n"));
  expectInvalidMigrationCompile(
    migrationUnsafeExternalTableSourceDir,
    migrationUnsafeExternalTableOutputDir,
    "UnsafeExternalTableMigrationMain",
    "Unsafe externalTables RailsHx migration compiled successfully.",
    "@:railsMigration externalTables entries must be safe Rails table identifiers"
  );
}

function expectMigrationDropTableReversibleOutput() {
  mkdirSync(join(migrationDropTableSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationDropTableSourceDir, "DropTableMigrationMain.hx"), [
    "import migrations.DropTableMigration;",
    "",
    "class DropTableMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<DropTableMigration> = DropTableMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationDropTableSourceDir, "migrations", "DropTableMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "",
    "// Demonstrates reversible destructive migration validation: DropTable is",
    "// allowed only inside Reversible, and knownModels makes the table reference",
    "// compile-time checked without emitting another create_table.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000013\",",
    "\tclassName: \"DropTableMigration\",",
    "\tmodels: [],",
    "\tknownModels: [\"models.Todo\"]",
    "})",
    "class DropTableMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tReversible([DropTable(\"todos\")], [])",
    "\t];",
    "}",
    "",
  ].join("\n"));
  compileValidMigration(
    migrationDropTableSourceDir,
    migrationDropTableOutputDir,
    "DropTableMigrationMain"
  );
  const migrationRuby = readFileSync(join(migrationDropTableOutputDir, "db", "migrate", "20260101000013_drop_table_migration.rb"), "utf8");
  if (!migrationRuby.includes("drop_table :todos")) {
    console.error("Drop-table migration did not emit the expected reversible drop_table statement.");
    process.exit(1);
  }
}

function expectMigrationSnapshotOperationsOutput() {
  mkdirSync(join(migrationSnapshotOpsSourceDir, "migrations"), { recursive: true });
  writeFileSync(join(migrationSnapshotOpsSourceDir, "SnapshotOperationsMigrationMain.hx"), [
    "import migrations.SnapshotOperationsMigration;",
    "",
    "class SnapshotOperationsMigrationMain {",
    "\tstatic function main() {",
    "\t\tvar migration:Class<SnapshotOperationsMigration> = SnapshotOperationsMigration;",
    "\t\tSys.println(migration != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(migrationSnapshotOpsSourceDir, "migrations", "SnapshotOperationsMigration.hx"), [
    "package migrations;",
    "",
    "import rails.migration.Migration;",
    "import rails.migration.MigrationOperation;",
    "import rails.migration.MigrationOperation.CreateTableItem;",
    "",
    "// Demonstrates production snapshot migration operations. The migration owns",
    "// explicit historical operations instead of deriving from mutable model",
    "// metadata, which keeps old migrations stable as models evolve.",
    "@:railsMigration({",
    "\ttimestamp: \"20260101000014\",",
    "\tclassName: \"SnapshotOperationsMigration\",",
    "\tversion: \"8.1\",",
    "\tmodels: []",
    "})",
    "class SnapshotOperationsMigration extends Migration {",
    "\tpublic static final operations:Array<MigrationOperation> = [",
    "\t\tCreateTable(\"audit_events\", {",
    "\t\t\tcolumns: [",
    "\t\t\t\tColumn(\"title\", StringColumn({nullable: false, limit: 120})),",
    "\t\t\t\tColumn(\"amount\", DecimalColumn({precision: 10, scale: 2})),",
    "\t\t\t\tReference(\"user\", {nullable: false, foreignKey: true}),",
    "\t\t\t\tIndex([\"user_id\", \"title\"], {unique: true})",
    "\t\t\t],",
    "\t\t\ttimestamps: true",
    "\t\t}),",
    "\t\tAddReference(\"audit_events\", \"account\", {index: false}),",
    "\t\tAddCompositeIndex(\"audit_events\", [\"account_id\", \"title\"], {}),",
    "\t\tChangeNull(\"audit_events\", \"title\", false),",
    "\t\tAddCheckConstraint(\"audit_events\", \"amount >= 0\", {name: \"amount_non_negative\"}),",
    "\t\tExecuteSql(\"UPDATE audit_events SET title = 'untitled' WHERE title IS NULL\", \"UPDATE audit_events SET title = NULL WHERE title = 'untitled'\"),",
    "\t\tDataMigration(\"UPDATE audit_events SET amount = 0 WHERE amount IS NULL\", \"UPDATE audit_events SET amount = NULL WHERE amount = 0\"),",
    "\t\tReversible([",
    "\t\t\tRenameColumn(\"audit_events\", \"title\", \"headline\"),",
    "\t\t\tRenameTable(\"audit_events\", \"audit_entries\"),",
    "\t\t\tRemoveCheckConstraint(\"audit_entries\", \"amount_non_negative\"),",
    "\t\t\tRemoveReference(\"audit_entries\", \"account\", {})",
    "\t\t], [",
    "\t\t\tAddReference(\"audit_entries\", \"account\", {}),",
    "\t\t\tAddCheckConstraint(\"audit_entries\", \"amount >= 0\", {name: \"amount_non_negative\"}),",
    "\t\t\tRenameTable(\"audit_entries\", \"audit_events\"),",
    "\t\t\tRenameColumn(\"audit_events\", \"headline\", \"title\")",
    "\t\t])",
    "\t];",
    "}",
    "",
  ].join("\n"));
  compileValidMigration(
    migrationSnapshotOpsSourceDir,
    migrationSnapshotOpsOutputDir,
    "SnapshotOperationsMigrationMain"
  );
  const migrationRuby = readFileSync(join(migrationSnapshotOpsOutputDir, "db", "migrate", "20260101000014_snapshot_operations_migration.rb"), "utf8");
  for (const expected of [
    "class SnapshotOperationsMigration < ActiveRecord::Migration[8.1]",
    "create_table :audit_events do |t|",
    "t.string :title, null: false, limit: 120",
    "t.decimal :amount, precision: 10, scale: 2",
    "t.references :user, null: false, foreign_key: true",
    "t.index [:user_id, :title], unique: true",
    "t.timestamps",
    "add_reference :audit_events, :account, index: false",
    "add_index :audit_events, [:account_id, :title]",
    "change_column_null :audit_events, :title, false",
    "add_check_constraint :audit_events, \"amount >= 0\", name: \"amount_non_negative\"",
    "execute \"UPDATE audit_events SET title = 'untitled' WHERE title IS NULL\"",
    "execute \"UPDATE audit_events SET title = NULL WHERE title = 'untitled'\"",
    "execute \"UPDATE audit_events SET amount = 0 WHERE amount IS NULL\"",
    "execute \"UPDATE audit_events SET amount = NULL WHERE amount = 0\"",
    "rename_column :audit_events, :title, :headline",
    "rename_table :audit_events, :audit_entries",
    "remove_check_constraint :audit_entries, name: \"amount_non_negative\"",
    "remove_reference :audit_entries, :account",
  ]) {
    if (!migrationRuby.includes(expected)) {
      console.error(`Snapshot operation migration missing expected line: ${expected}`);
      process.exit(1);
    }
  }
}

function expectInvalidTemplateLocalsFailure() {
  mkdirSync(join(invalidSourceDir, "controllers"), { recursive: true });
  writeFileSync(join(invalidSourceDir, "InvalidMain.hx"), [
    "import controllers.BadTodosController;",
    "",
    "class InvalidMain {",
    "\tstatic function main() {",
    "\t\tvar controller:BadTodosController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "controllers", "BadTodosController.hx"), [
    "package controllers;",
    "",
    "import models.Todo;",
    "import rails.action_view.Template;",
    "import rails.macros.ViewMacro;",
    "import views.TodoIndexView;",
    "",
    "typedef TodoIndexLocals = {",
    "\tvar todos:Array<Todo>;",
    "}",
    "",
    "@:railsController",
    "class BadTodosController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function index() {",
    "\t\tvar todos = Todo.incomplete();",
    "\t\tViewMacro.renderTemplate(this, (Template.of(TodoIndexView) : Template<TodoIndexLocals>), {items: todos});",
    "\t}",
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
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
      "-cp",
      invalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid ViewMacro.renderTemplate locals compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("ViewMacro.renderTemplate locals do not match the Template<TLocals> contract.")
      && !output.includes("TodoIndexLocals")
      && !output.includes("has no field todos")) {
      console.error("Invalid ViewMacro.renderTemplate locals failed, but not with the expected typed locals error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid ViewMacro.renderTemplate locals check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectRawErbRequiresOptInFailure() {
  mkdirSync(join(rawErbInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(rawErbInvalidSourceDir, "InvalidRawErbMain.hx"), [
    "import views.BadRawErbView;",
    "",
    "class InvalidRawErbMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadRawErbView> = BadRawErbView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(rawErbInvalidSourceDir, "views", "BadRawErbView.hx"), [
    "package views;",
    "",
    "@:railsTemplate(\"controllers/todos/bad\")",
    "class BadRawErbView {",
    "\tpublic static var body:String = \"<%= dangerous %>\";",
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
      `ruby_output=${rawErbInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      rawErbInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidRawErbMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Raw ERB template without @:railsAllowRawErb compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("@:railsTemplate raw ERB blocks require @:railsAllowRawErb")) {
      console.error("Raw ERB template failed, but not with the expected escape-hatch error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run raw ERB escape-hatch check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedTemplateAstFieldFailure() {
  mkdirSync(join(typedTemplateInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedTemplateInvalidSourceDir, "InvalidTypedTemplateMain.hx"), [
    "import views.BadTypedTemplateView;",
    "",
    "class InvalidTypedTemplateMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedTemplateView> = BadTypedTemplateView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedTemplateInvalidSourceDir, "views", "BadTypedTemplateView.hx"), [
    "package views;",
    "",
    "import models.Todo;",
    "import rails.action_view.HtmlAttr;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_typed\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedTemplateView {",
    "\tpublic static function render(todos:Array<Todo>):HtmlNode {",
    "\t\treturn HtmlNode.Element(\"div\", [HtmlAttr.Static(\"class\", \"bad\")], [",
    "\t\t\tHtmlNode.ExprText(todos[0].missingTitle)",
    "\t\t]);",
    "\t}",
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
      `ruby_output=${typedTemplateInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      typedTemplateInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedTemplateMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid @:railsTemplateAst field access compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("missingTitle") && !output.includes("has no field")) {
      console.error("Invalid @:railsTemplateAst field access failed, but not with the expected typed field error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid @:railsTemplateAst field check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedPartialLocalsFailure() {
  mkdirSync(join(typedPartialInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedPartialInvalidSourceDir, "InvalidTypedPartialMain.hx"), [
    "import views.BadTypedPartialView;",
    "",
    "class InvalidTypedPartialMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedPartialView> = BadTypedPartialView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedPartialInvalidSourceDir, "views", "BadTypedPartialView.hx"), [
    "package views;",
    "",
    "import models.Todo;",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Template;",
    "import views.TodoSummaryView;",
    "import views.TodoSummaryView.TodoSummaryLocals;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_partial\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedPartialView {",
    "\tpublic static function render(todos:Array<Todo>):HtmlNode {",
    "\t\treturn H.partial((Template.of(TodoSummaryView) : Template<TodoSummaryLocals>), {items: todos});",
    "\t}",
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
      `ruby_output=${typedPartialInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      typedPartialInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedPartialMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid H.partial locals compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("TodoSummaryLocals") && !output.includes("has no field todos") && !output.includes("Object requires field todos")) {
      console.error("Invalid H.partial locals failed, but not with the expected typed locals error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid H.partial locals check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedRouteHelperFailure() {
  mkdirSync(join(typedRouteInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedRouteInvalidSourceDir, "InvalidTypedRouteMain.hx"), [
    "import views.BadTypedRouteView;",
    "",
    "class InvalidTypedRouteMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedRouteView> = BadTypedRouteView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedRouteInvalidSourceDir, "views", "BadTypedRouteView.hx"), [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import routes.Routes;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_route\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedRouteView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.linkTo(\"Broken\", Routes.missingPath(), []);",
    "\t}",
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
      `ruby_output=${typedRouteInvalidOutputDir}`,
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
      typedRouteInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedRouteMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid typed route helper compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("missingPath") && !output.includes("has no field")) {
      console.error("Invalid typed route helper failed, but not with the expected typed route error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed route helper check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedRouteParamFailure() {
  mkdirSync(join(typedRouteParamInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedRouteParamInvalidSourceDir, "InvalidTypedRouteParamMain.hx"), [
    "import views.BadTypedRouteParamView;",
    "",
    "class InvalidTypedRouteParamMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedRouteParamView> = BadTypedRouteParamView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedRouteParamInvalidSourceDir, "views", "BadTypedRouteParamView.hx"), [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import routes.Routes;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_route_param\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedRouteParamView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.linkTo(\"Broken\", Routes.rootPath({id: 1}), []);",
    "\t}",
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
      `ruby_output=${typedRouteParamInvalidOutputDir}`,
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
      typedRouteParamInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedRouteParamMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid typed route helper param compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("Too many arguments") && !output.includes("expects no arguments")) {
      console.error("Invalid typed route helper param failed, but not with the expected route arity error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed route helper param check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedFormFieldRequiresFormFailure() {
  mkdirSync(join(typedFormInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedFormInvalidSourceDir, "InvalidTypedFormMain.hx"), [
    "import views.BadTypedFormView;",
    "",
    "class InvalidTypedFormMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedFormView> = BadTypedFormView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedFormInvalidSourceDir, "views", "BadTypedFormView.hx"), [
    "package views;",
    "",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_form\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedFormView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <text_field name=\"title\" />;",
    "\t}",
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
      `ruby_output=${typedFormInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      typedFormInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedFormMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid typed form field outside <form_with> compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("Rails form field helpers must be used inside <form_with>")) {
      console.error("Invalid typed form field failed, but not with the expected form context error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed form field check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTypedSlotContentRequiresComponentFailure() {
  mkdirSync(join(typedSlotInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedSlotInvalidSourceDir, "InvalidTypedSlotMain.hx"), [
    "import views.BadTypedSlotView;",
    "",
    "class InvalidTypedSlotMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedSlotView> = BadTypedSlotView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedSlotInvalidSourceDir, "views", "BadTypedSlotView.hx"), [
    "package views;",
    "",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Slot;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_slot\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedSlotView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <div>${Slot.content()}</div>;",
    "\t}",
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
      `ruby_output=${typedSlotInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      typedSlotInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedSlotMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Slot.content() outside HtmlNode.Component compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("Slot.content() may only be used as the matching slot local for HtmlNode.Component")) {
      console.error("Invalid Slot.content() usage failed, but not with the expected typed slot error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed slot check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectTemplateOfRequiresRailsTemplateFailure() {
  mkdirSync(join(templateRefInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(templateRefInvalidSourceDir, "InvalidTemplateRefMain.hx"), [
    "import views.BadTemplateRefView;",
    "",
    "class InvalidTemplateRefMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTemplateRefView> = BadTemplateRefView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(templateRefInvalidSourceDir, "views", "PlainView.hx"), [
    "package views;",
    "",
    "class PlainView {}",
    "",
  ].join("\n"));
  writeFileSync(join(templateRefInvalidSourceDir, "views", "BadTemplateRefView.hx"), [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Template;",
    "",
    "typedef DummyLocals = {",
    "\tvar title:String;",
    "}",
    "",
    "@:railsTemplate(\"controllers/todos/bad_template_ref\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTemplateRefView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.partial((Template.of(PlainView) : Template<DummyLocals>), {title: \"bad\"});",
    "\t}",
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
      `ruby_output=${templateRefInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      templateRefInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTemplateRefMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Template.of accepted a class without @:railsTemplate.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("Template.of/layout expects a class annotated with @:railsTemplate")) {
      console.error("Invalid Template.of view failed, but not with the expected template annotation error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid Template.of check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectUnsafeRailsTemplatePathFailure() {
  mkdirSync(join(templatePathInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(templatePathInvalidSourceDir, "InvalidTemplatePathMain.hx"), [
    "import views.BadTemplatePathView;",
    "",
    "class InvalidTemplatePathMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTemplatePathView> = BadTemplatePathView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(templatePathInvalidSourceDir, "views", "BadTemplatePathView.hx"), [
    "package views;",
    "",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"../bad\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTemplatePathView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <div>bad</div>;",
    "\t}",
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
      `ruby_output=${templatePathInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      templatePathInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTemplatePathMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Unsafe @:railsTemplate path compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("@:railsTemplate path must be a safe Rails template path relative to app/views")) {
      console.error("Unsafe @:railsTemplate path failed, but not with the expected path safety error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid @:railsTemplate path check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectBackslashRailsTemplatePathFailure() {
  mkdirSync(join(templateBackslashPathInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(templateBackslashPathInvalidSourceDir, "InvalidTemplateBackslashPathMain.hx"), [
    "import views.BadTemplateBackslashPathView;",
    "",
    "class InvalidTemplateBackslashPathMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTemplateBackslashPathView> = BadTemplateBackslashPathView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(templateBackslashPathInvalidSourceDir, "views", "BadTemplateBackslashPathView.hx"), [
    "package views;",
    "",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers\\\\todos\\\\bad\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTemplateBackslashPathView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <div>bad</div>;",
    "\t}",
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
      `ruby_output=${templateBackslashPathInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      templateBackslashPathInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTemplateBackslashPathMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Backslash @:railsTemplate path compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("@:railsTemplate path must be a safe Rails template path relative to app/views")) {
      console.error("Backslash @:railsTemplate path failed, but not with the expected path safety error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid backslash @:railsTemplate path check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectRawLayoutStringFailure() {
  mkdirSync(join(rawLayoutInvalidSourceDir, "controllers"), { recursive: true });
  writeFileSync(join(rawLayoutInvalidSourceDir, "RawLayoutMain.hx"), [
    "import controllers.RawLayoutController;",
    "",
    "class RawLayoutMain {",
    "\tstatic function main() {",
    "\t\tvar controller:RawLayoutController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(rawLayoutInvalidSourceDir, "controllers", "RawLayoutController.hx"), [
    "package controllers;",
    "",
    "import models.Todo;",
    "import rails.action_view.Template;",
    "import rails.macros.ViewMacro;",
    "import views.TodoIndexView;",
    "import views.TodoIndexView.TodoIndexLocals;",
    "",
    "@:railsController",
    "class RawLayoutController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function index() {",
    "\t\tvar todos = Todo.incomplete();",
    "\t\tViewMacro.renderTemplateWithLayout(this, (Template.of(TodoIndexView) : Template<TodoIndexLocals>), {",
    "\t\t\ttodos: todos,",
    "\t\t\ttodoCount: todos.length,",
    "\t\t\ttypedColumnCount: Todo.typedColumnCount(),",
    "\t\t\tsampleUser: models.User.first()",
    "\t\t}, \"application\");",
    "\t}",
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
      `ruby_output=${rawLayoutInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      rawLayoutInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "RawLayoutMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Raw string layout compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("String should be rails.action_view.Layout")
      && !output.includes("ViewMacro.renderTemplateWithLayout layout expects Template.layout")) {
      console.error("Raw string layout failed, but not with the expected typed layout diagnostic.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run raw layout string check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectUnknownTypedFormFieldFailure() {
  mkdirSync(join(typedFieldInvalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(typedFieldInvalidSourceDir, "InvalidTypedFieldMain.hx"), [
    "import views.BadTypedFieldView;",
    "",
    "class InvalidTypedFieldMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadTypedFieldView> = BadTypedFieldView;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedFieldInvalidSourceDir, "views", "BadTypedFieldView.hx"), [
    "package views;",
    "",
    "import models.Todo;",
    "import rails.action_view.HtmlNode;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_typed_field\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedFieldView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <form_with url=\"/todos\" scope=${Todo.railsParamKey}><text_field name=${Todo.f.missing} /></form_with>;",
    "\t}",
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
      `ruby_output=${typedFieldInvalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      typedFieldInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedFieldMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Unknown typed RailsHx form field compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("has no field missing")) {
      console.error("Unknown typed RailsHx form field failed, but not with the expected missing field error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid typed form field ref check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectMixedModelStrongParamsFailure() {
  mkdirSync(join(typedParamsInvalidSourceDir, "controllers"), { recursive: true });
  writeFileSync(join(typedParamsInvalidSourceDir, "InvalidTypedParamsMain.hx"), [
    "import controllers.BadTypedParamsController;",
    "",
    "class InvalidTypedParamsMain {",
    "\tstatic function main() {",
    "\t\tvar controller:BadTypedParamsController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedParamsInvalidSourceDir, "controllers", "BadTypedParamsController.hx"), [
    "package controllers;",
    "",
    "import models.Todo;",
    "import models.User;",
    "import rails.macros.ParamsMacro;",
    "",
    "@:railsController",
    "class BadTypedParamsController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function create() {",
    "\t\tParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title, User.f.name]);",
    "\t}",
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
      `ruby_output=${typedParamsInvalidOutputDir}`,
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
      typedParamsInvalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidTypedParamsMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Mixed-model ParamsMacro.requirePermit field refs compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("ParamsMacro.requirePermit field refs must belong to the same model as the typed params root")) {
      console.error("Mixed-model ParamsMacro.requirePermit failed, but not with the expected model-scope error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid mixed-model strong params check; no Reflaxe candidate found.");
    process.exit(1);
  }
}

function expectUnknownStrongParamsFieldFailure() {
  mkdirSync(join(typedParamsUnknownSourceDir, "controllers"), { recursive: true });
  writeFileSync(join(typedParamsUnknownSourceDir, "InvalidUnknownParamsMain.hx"), [
    "import controllers.BadUnknownParamsController;",
    "",
    "class InvalidUnknownParamsMain {",
    "\tstatic function main() {",
    "\t\tvar controller:BadUnknownParamsController = null;",
    "\t\tSys.println(controller == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(typedParamsUnknownSourceDir, "controllers", "BadUnknownParamsController.hx"), [
    "package controllers;",
    "",
    "import models.Todo;",
    "import rails.macros.ParamsMacro;",
    "",
    "@:railsController",
    "class BadUnknownParamsController extends rails.action_controller.Base {",
    "\tstatic final lifecycle = [];",
    "",
    "\tpublic function create() {",
    "\t\tParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.missing]);",
    "\t}",
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
      `ruby_output=${typedParamsUnknownOutputDir}`,
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
      typedParamsUnknownSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidUnknownParamsMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Unknown ParamsMacro.requirePermit field ref compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("has no field missing")) {
      console.error("Unknown ParamsMacro.requirePermit field failed, but not with the expected missing field error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to run invalid unknown strong params field check; no Reflaxe candidate found.");
    process.exit(1);
  }
}
