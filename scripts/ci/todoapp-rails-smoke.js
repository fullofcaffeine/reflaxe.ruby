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
const typedFormInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_form_invalid_src");
const typedFormInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_form_invalid_out");
const typedSlotInvalidSourceDir = join(root, "test", ".generated", "todoapp_rails_typed_slot_invalid_src");
const typedSlotInvalidOutputDir = join(root, "test", ".generated", "todoapp_rails_typed_slot_invalid_out");
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
rmSync(typedFormInvalidSourceDir, { force: true, recursive: true });
rmSync(typedFormInvalidOutputDir, { force: true, recursive: true });
rmSync(typedSlotInvalidSourceDir, { force: true, recursive: true });
rmSync(typedSlotInvalidOutputDir, { force: true, recursive: true });

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
  "db/migrate/20260101000000_create_todos.rb",
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
  /self\.render\(template: "controllers\/todos\/index", locals: \{todos: todos__hx\d+, todo_count: todos__hx\d+\.length, typed_column_count: Models::Todo\.typed_column_count\(\), sample_user: Models::User\.first\(\)\}, layout: "application"\)/,
  /attrs__hx\d+ = self\.params\(\)\.require\("todo"\)\.permit\(\[:title, :notes, :user_id\]\)/,
  /todo__hx\d+ = Models::Todo\.create\(attrs__hx\d+\)/,
  /self\.redirect_to\(self\.todos_path\(\)\)/,
]) {
  if (!expected.test(controllerRuby)) {
    console.error(`todoapp_rails controller output missing expected line: ${expected}`);
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

const migrationRuby = readFileSync(join(outputDir, "db", "migrate", "20260101000000_create_todos.rb"), "utf8");
for (const expected of [
  "# Generated by RailsHx from @:railsMigration.",
  "class CreateTodos < ActiveRecord::Migration[7.1]",
  "create_table :users do |t|",
  "t.string :name, null: false",
  "t.index :name",
  "create_table :todos do |t|",
  "t.string :title, null: false",
  't.text :notes, null: false, default: ""',
  "t.boolean :is_completed, null: false, default: false",
  "t.references :user, null: false, foreign_key: true",
  "t.index :title",
]) {
  if (!migrationRuby.includes(expected)) {
    console.error(`todoapp_rails generated migration missing expected line: ${expected}`);
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
  '<content_for name="head">',
  '<partial template=${(Template.named("controllers/todos/composer")',
  '<partial template=${(Template.named("controllers/todos/list")',
  '<partial template=${(Template.named("controllers/todos/dashboard")',
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

const view = readFileSync(join(outputDir, "app", "views", "controllers", "todos", "index.html.erb"), "utf8");
for (const expected of [
  "RailsHx sample",
  "Typed Rails, polished Ruby.",
  "<% content_for :head do %>",
  '<meta name="railshx-template" content="todo-index">',
  "<%= todo_count %>",
  "<%= typed_column_count %>",
  '<%= render partial: "controllers/todos/composer", locals: {sample_user: sample_user} %>',
  '<%= render partial: "controllers/todos/list", locals: {todos: todos} %>',
  "todo-shell",
  '<%= render partial: "controllers/todos/dashboard", locals: {todos: todos, todo_count: todo_count, typed_column_count: typed_column_count, sample_user: sample_user} %>',
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
  '<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>',
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
  '<%= link_to "#open-work", class: "typed-route-link", "data-railshx-scroll": true do %>',
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
  '<ul class="todo-list">',
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

expectInvalidTemplateLocalsFailure();
expectRawErbRequiresOptInFailure();
expectTypedTemplateAstFieldFailure();
expectTypedPartialLocalsFailure();
expectTypedRouteHelperFailure();
expectTypedFormFieldRequiresFormFailure();
expectTypedSlotContentRequiresComponentFailure();

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
    "",
    "typedef TodoIndexLocals = {",
    "\tvar todos:Array<Todo>;",
    "}",
    "",
    "@:railsController",
    "class BadTodosController extends rails.action_controller.Base {",
    "\tpublic function index() {",
    "\t\tvar todos = Todo.incomplete();",
    "\t\tViewMacro.renderTemplate(this, (Template.named(\"controllers/todos/index\") : Template<TodoIndexLocals>), {items: todos});",
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
    "import views.TodoSummaryView.TodoSummaryLocals;",
    "",
    "@:railsTemplate(\"controllers/todos/bad_partial\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTypedPartialView {",
    "\tpublic static function render(todos:Array<Todo>):HtmlNode {",
    "\t\treturn H.partial((Template.named(\"controllers/todos/summary\") : Template<TodoSummaryLocals>), {items: todos});",
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
