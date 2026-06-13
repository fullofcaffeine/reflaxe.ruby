#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "turbo_streams");
const invalidSourceDir = join(root, "test", ".generated", "turbo_streams_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "turbo_streams_invalid_out");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  fail("Unable to find vendored Reflaxe source for Turbo Streams smoke.");
}

compileTurboStreams(outputDir);

for (const file of [
  "app/haxe_gen/main.rb",
  "app/haxe_gen/views/todo_row_view.rb",
  "app/views/todos/_todo.html.erb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    fail(`Expected Turbo Streams output file missing: ${fullPath}`);
  }
}

const mainRuby = readFileSync(join(outputDir, "app", "haxe_gen", "main.rb"), "utf8");
for (const expected of [
  /turbo_stream\.append\("todos", partial: "todos\/todo", locals: \{completed: \(append_locals__hx\d+\)\["completed"\], dom_id: \(append_locals__hx\d+\)\["domId"\], title: \(append_locals__hx\d+\)\["title"\]\}\)/,
  /turbo_stream\.replace\("todos", partial: "todos\/todo", locals: \{completed: \(replace_locals__hx\d+\)\["completed"\], dom_id: \(replace_locals__hx\d+\)\["domId"\], title: \(replace_locals__hx\d+\)\["title"\]\}\)/,
  /turbo_stream\.update\("todos", partial: "todos\/todo", locals: \{dom_id: "todo_2", title: "Inline locals still work", completed: false\}\)/,
  /turbo_stream\.prepend\("todos", partial: "todos\/todo", locals: dynamic_locals__hx\d+\)/,
  /turbo_stream\.remove\("todos"\)/,
  /Turbo::StreamsChannel\.broadcast_append_to\("todos", target: "todos", partial: "todos\/todo", locals: \{completed: \(append_locals__hx\d+\)\["completed"\], dom_id: \(append_locals__hx\d+\)\["domId"\], title: \(append_locals__hx\d+\)\["title"\]\}\)/,
]) {
  if (!expected.test(mainRuby)) {
    fail(`Turbo Streams output missing expected line: ${expected}`);
  }
}

const erb = readFileSync(join(outputDir, "app", "views", "todos", "_todo.html.erb"), "utf8");
for (const expected of [
  "<li",
  "<%= dom_id %>",
  "<%= title %>",
  "completed",
]) {
  if (!erb.includes(expected)) {
    fail(`Turbo Streams partial missing expected ERB output: ${expected}`);
  }
}

for (const file of ["app/haxe_gen/main.rb", "app/haxe_gen/views/todo_row_view.rb", "run.rb"]) {
  const result = run("ruby", ["-c", join(outputDir, file)], { allowFailure: true });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
}

writeInvalidFixtures();

const invalidLocals = compileTurboStreams(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidLocalsMain",
  allowFailure: true,
});
if (invalidLocals.status === 0) {
  fail("Expected invalid Turbo Streams locals compile to fail.");
}
if (!/has no field completed|completed|Bool/.test(invalidLocals.stderr + invalidLocals.stdout)) {
  process.stdout.write(invalidLocals.stdout);
  process.stderr.write(invalidLocals.stderr);
  fail("Invalid Turbo Streams locals failed for an unexpected reason.");
}

const invalidTarget = compileTurboStreams(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidTargetMain",
  allowFailure: true,
});
if (invalidTarget.status === 0) {
  fail("Expected invalid Turbo Streams target compile to fail.");
}
if (!/Int should be rails\.turbo\.StreamTarget|StreamTarget|Cannot unify/.test(invalidTarget.stderr + invalidTarget.stdout)) {
  process.stdout.write(invalidTarget.stdout);
  process.stderr.write(invalidTarget.stderr);
  fail("Invalid Turbo Streams target failed for an unexpected reason.");
}

console.log("[turbo-streams] OK");

function compileTurboStreams(targetDir, options = {}) {
  const args = [
    "-D",
    `ruby_output=${targetDir}`,
    "-D",
    "reflaxe_runtime",
    "-D",
    "reflaxe_ruby_rails",
    "-cp",
    join(root, "src"),
    "-cp",
    options.classPath ?? join(root, "examples", "turbo_streams"),
    "-cp",
    join(root, "examples", "turbo_streams"),
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    options.main ?? "Main",
  ];
  return run("haxe", args, { allowFailure: options.allowFailure });
}

function writeInvalidFixtures() {
  mkdirSync(invalidSourceDir, { recursive: true });
  writeFileSync(join(invalidSourceDir, "InvalidLocalsMain.hx"), [
    "import rails.action_view.Template;",
    "import rails.turbo.TurboStreams;",
    "import views.TodoRowView;",
    "import views.TodoRowView.TodoRowLocals;",
    "class InvalidLocalsMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.append(\"todos\", (Template.of(TodoRowView) : Template<TodoRowLocals>), {domId: \"todo_1\", title: \"missing completion\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidTargetMain.hx"), [
    "import rails.action_view.Template;",
    "import rails.turbo.TurboStreams;",
    "import views.TodoRowView;",
    "import views.TodoRowView.TodoRowLocals;",
    "class InvalidTargetMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.remove(42);",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
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

function fail(message) {
  console.error(`[turbo-streams] ERROR: ${message}`);
  process.exit(1);
}
