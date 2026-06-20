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

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "scaffold.rb"),
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

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "scaffold.rb"),
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
  "src_haxe/migrations/CreateTodos.hx",
  "src_haxe/controllers/TodosController.hx",
  "src_haxe/views/todos/IndexView.hx",
  "src_haxe/views/todos/CreateView.hx",
  "src_haxe/routes/AppRoutes.hx",
  "src_haxe/routes/Routes.hx",
  "test_haxe/models/TodoHaxeTest.hx",
  "src_haxe/Main.hx",
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
assertIncludes("src_haxe/migrations/CreateTodos.hx", [
  "import rails.migration.Migration;",
  "@:railsMigration({",
  'timestamp: "20260101000000"',
  'className: "CreateTodos"',
  'models: ["models.Todo"]',
  "class CreateTodos extends Migration",
]);
assertIncludes("src_haxe/controllers/TodosController.hx", [
  "class TodosController extends rails.action_controller.Base",
  "static final lifecycle = [];",
  "typedef IndexLocals = {",
  "var todos:Array<Todo>;",
  "ViewMacro.renderTemplate(this, (Template.of(IndexView) : Template<IndexLocals>), {title: \"TodosController#index\", todos: todos})",
  'ParamsMacro.requirePermit(this.params(), "todo", ["title", "isCompleted"])',
  'redirectToOptions({action: "index"})',
]);
assertIncludes("src_haxe/views/todos/IndexView.hx", [
  "import controllers.TodosController.IndexLocals;",
  '@:railsTemplate("controllers/todos/index")',
  '@:railsTemplateAst("render")',
  "This scaffold view receives typed Todo records from the controller.",
  "<for ${todo in locals.todos}>",
  "<li>${todo.title}</li>",
]);
assertIncludes("src_haxe/routes/AppRoutes.hx", [
  "@:railsRoutes",
  "resources(Todo, TodosController, {only: [index, create]});",
]);
assertIncludes("src_haxe/routes/Routes.hx", [
  '@:native("self")',
  "Generated route helpers will be written here.",
]);
assertIncludes("test_haxe/models/TodoHaxeTest.hx", [
  '@:railsTest("models/todo_haxe_test")',
  "class TodoHaxeTest extends ModelTestCase",
  "@:railsTests",
  'test("generated model relation is typed", () -> {',
  "notNil(Todo.all());",
]);
assertIncludes("src_haxe/Main.hx", [
  "import test_haxe.models.TodoHaxeTest;",
  "var modelTest:Class<TodoHaxeTest> = TodoHaxeTest;",
]);
assertIncludes("build.hxml", [
  "-cp src_haxe",
  "-cp .",
]);
if (!compileWithFirstAvailableReflaxe(join(outputDir, "ruby"))) {
  console.error("Unable to compile scaffolded Haxe project through Reflaxe.");
  process.exit(1);
}

const manifest = JSON.parse(readFileSync(join(outputDir, ".railshx", "manifest.json"), "utf8"));
for (const [output, kind] of [
  ["src_haxe/models/Todo.hx", "haxe_source"],
  ["src_haxe/migrations/CreateTodos.hx", "haxe_migration_source"],
  ["src_haxe/routes/AppRoutes.hx", "haxe_source"],
  ["src_haxe/routes/Routes.hx", "haxe_source"],
  ["test_haxe/models/TodoHaxeTest.hx", "haxe_test_source"],
  ["build.hxml", "haxe_build"],
]) {
  const entry = manifest.outputs.find((candidate) => candidate.output === output);
  if (!entry || entry.kind !== kind || entry.source !== "hxruby:scaffold" || !entry.sha256) {
    console.error(`Scaffold manifest missing expected ${output} ${kind} entry.`);
    process.exit(1);
  }
}

const railsRoutesDir = join(root, "test", ".generated", "scaffold_cli_rails_routes");
rmSync(railsRoutesDir, { force: true, recursive: true });
run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "scaffold.rb"),
  "--model",
  "Todo",
  "--fields",
  "title:String",
  "--controller",
  "--routes",
  "rails",
  "--output",
  railsRoutesDir,
]);
const railsRoutesExtern = readFileSync(join(railsRoutesDir, "src_haxe", "routes", "Routes.hx"), "utf8");
if (!railsRoutesExtern.includes("public static function todosPath():String;")) {
  console.error("--routes=rails did not preserve Rails-owned helper extern generation.");
  process.exit(1);
}
const railsRoutesController = readFileSync(join(railsRoutesDir, "src_haxe", "controllers", "TodosController.hx"), "utf8");
if (!railsRoutesController.includes("redirectTo(Routes.todosPath())")) {
  console.error("--routes=rails controller did not use generated route helper extern.");
  process.exit(1);
}

const snippetRoutesDir = join(root, "test", ".generated", "scaffold_cli_snippet_routes");
rmSync(snippetRoutesDir, { force: true, recursive: true });
run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "scaffold.rb"),
  "--model",
  "Todo",
  "--fields",
  "title:String",
  "--controller",
  "--routes",
  "snippet",
  "--output",
  snippetRoutesDir,
]);
if (existsSync(join(snippetRoutesDir, "src_haxe", "routes", "AppRoutes.hx"))) {
  console.error("--routes=snippet should not create a Haxe-owned AppRoutes source.");
  process.exit(1);
}
if (!existsSync(join(snippetRoutesDir, "docs", "railshx", "routes_snippet.md"))) {
  console.error("--routes=snippet did not write reviewable route instructions.");
  process.exit(1);
}

const noRoutesDir = join(root, "test", ".generated", "scaffold_cli_no_routes");
rmSync(noRoutesDir, { force: true, recursive: true });
run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "scaffold.rb"),
  "--model",
  "Todo",
  "--fields",
  "title:String",
  "--controller",
  "--routes",
  "none",
  "--output",
  noRoutesDir,
]);
if (existsSync(join(noRoutesDir, "src_haxe", "routes"))) {
  console.error("--routes=none should leave route files untouched.");
  process.exit(1);
}

const noTestsDir = join(root, "test", ".generated", "scaffold_cli_no_tests");
rmSync(noTestsDir, { force: true, recursive: true });
run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "scaffold.rb"),
  "--model",
  "Todo",
  "--fields",
  "title:String",
  "--skip-tests",
  "--output",
  noTestsDir,
]);
if (existsSync(join(noTestsDir, "test_haxe"))) {
  console.error("--skip-tests should not create Haxe-authored test sources.");
  process.exit(1);
}
if (readFileSync(join(noTestsDir, "build.hxml"), "utf8").includes("-cp .")) {
  console.error("--skip-tests should not add the app root classpath to build.hxml.");
  process.exit(1);
}

const collisionDir = join(root, "test", ".generated", "scaffold_cli_collision");
rmSync(collisionDir, { force: true, recursive: true });
run("ruby", [
  "-e",
  `require 'fileutils'; FileUtils.mkdir_p(${JSON.stringify(join(collisionDir, "src_haxe", "models"))}); File.write(${JSON.stringify(join(collisionDir, "src_haxe", "models", "Todo.hx"))}, "// hand-written model\\n")`,
]);
const collision = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "scaffold.rb"),
  "--model",
  "Todo",
  "--fields",
  "title:String",
  "--output",
  collisionDir,
], { allowFailure: true });
if (collision.status === 0 || !collision.stderr.includes("Refusing to overwrite non-RailsHx-owned file")) {
  process.stdout.write(collision.stdout);
  process.stderr.write(collision.stderr);
  console.error("Scaffold generator did not protect a non-owned Haxe model.");
  process.exit(1);
}

const compilerCollisionOutput = join(root, "test", ".generated", "scaffold_cli_compiler_collision");
rmSync(compilerCollisionOutput, { force: true, recursive: true });
run("ruby", [
  "-e",
  `require 'fileutils'; FileUtils.mkdir_p(${JSON.stringify(join(compilerCollisionOutput, "db", "migrate"))}); File.write(${JSON.stringify(join(compilerCollisionOutput, "db", "migrate", "20260101000000_create_todos.rb"))}, "# hand-written migration\\n")`,
]);
const compilerCollision = compileWithFirstAvailableReflaxe(compilerCollisionOutput, { allowFailure: true });
if (!compilerCollision || compilerCollision.status === 0 || !compilerCollision.stderr.includes("RailsHx refuses to overwrite non-owned Rails artifact db/migrate/20260101000000_create_todos.rb")) {
  if (compilerCollision) {
    process.stdout.write(compilerCollision.stdout);
    process.stderr.write(compilerCollision.stderr);
  }
  console.error("Compiler did not protect a non-owned generated migration path.");
  process.exit(1);
}

assertIncludes("ruby/db/migrate/20260101000000_create_todos.rb", [
  "# Generated by RailsHx from @:railsMigration.",
  "class CreateTodos < ActiveRecord::Migration[7.1]",
  "create_table :todos do |t|",
  "t.string :title",
  "t.boolean :is_completed",
]);
assertIncludes("ruby/app/haxe_gen/controllers/todos_controller.rb", [
  "todos__hx0 = Models::Todo.all().to_a()",
  'self.render(template: "controllers/todos/index", locals: {title: "TodosController#index", todos: todos__hx0})',
  'self.params().require("todo").permit([:title, :is_completed])',
]);
assertIncludes("ruby/app/views/controllers/todos/index.html.erb", [
  "<% todos.each do |todo| %>",
  "<%= todo.title %>",
]);
assertIncludes("ruby/test/generated/models/todo_haxe_test.rb", [
  "# Generated by RailsHx from @:railsTest.",
  'test "generated model relation is typed" do',
  "assert_not_nil(Models::Todo.all())",
]);

function assertIncludes(relativeFile, expectedLines) {
  const content = readFileSync(join(outputDir, relativeFile), "utf8");
  for (const expected of expectedLines) {
    if (!content.includes(expected)) {
      console.error(`${relativeFile} missing expected line: ${expected}`);
      process.exit(1);
    }
  }
}

function compileWithFirstAvailableReflaxe(rubyOutput, options = {}) {
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
      ...(existsSync(join(outputDir, "test_haxe")) ? ["-cp", outputDir] : []),
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "Main",
    ], { allowFailure: true });
    if (result.status === 0 || options.allowFailure) {
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
