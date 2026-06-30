#!/usr/bin/env node

const { existsSync, mkdirSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "turbo_streams");
const invalidSourceDir = join(root, "test", ".generated", "turbo_streams_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "turbo_streams_invalid_out");
const invalidStringTargetSourceDir = join(root, "test", ".generated", "turbo_streams_invalid_string_target_src");
const invalidStringTargetOutputDir = join(root, "test", ".generated", "turbo_streams_invalid_string_target_out");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });
rmSync(invalidStringTargetSourceDir, { force: true, recursive: true });
rmSync(invalidStringTargetOutputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  fail("Unable to find vendored Reflaxe source for Turbo Streams smoke.");
}

compileTurboStreams(outputDir);

// Generated stream helper Ruby and ERB partial shape is covered by committed
// snapshots. This smoke keeps the non-snapshot checks: required files, Ruby
// syntax, and negative typing diagnostics for locals and stream targets.
for (const file of [
  "app/lib/railshx/generated/main.rb",
  "app/lib/railshx/runtime/hxruby/core.rb",
  "app/views/todos/_todo.html.erb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    fail(`Expected Turbo Streams output file missing: ${fullPath}`);
  }
}

for (const file of ["app/lib/railshx/generated/main.rb", "run.rb"]) {
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

writeInvalidStringTargetFixture();

const invalidStringTarget = compileTurboStreams(invalidStringTargetOutputDir, {
  classPath: invalidStringTargetSourceDir,
  main: "InvalidStringTargetMain",
  allowFailure: true,
});
if (invalidStringTarget.status === 0) {
  fail("Expected invalid Turbo Streams raw string target compile to fail.");
}
if (!/String should be rails\.turbo\.StreamTarget|StreamTarget|Cannot unify/.test(invalidStringTarget.stderr + invalidStringTarget.stdout)) {
  process.stdout.write(invalidStringTarget.stdout);
  process.stderr.write(invalidStringTarget.stderr);
  fail("Invalid Turbo Streams raw string target failed for an unexpected reason.");
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
    "import rails.turbo.StreamTarget;",
    "import rails.turbo.TurboStreams;",
    "import views.TodoRowView;",
    "import views.TodoRowView.TodoRowLocals;",
    "class InvalidLocalsMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.append(StreamTarget.named(\"todos\"), (Template.of(TodoRowView) : Template<TodoRowLocals>), {domId: \"todo_1\", title: \"missing completion\"});",
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

function writeInvalidStringTargetFixture() {
  mkdirSync(invalidStringTargetSourceDir, { recursive: true });
  writeFileSync(join(invalidStringTargetSourceDir, "InvalidStringTargetMain.hx"), [
    "import rails.action_view.Template;",
    "import rails.turbo.TurboStreams;",
    "import views.TodoRowView;",
    "import views.TodoRowView.TodoRowLocals;",
    "class InvalidStringTargetMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.remove(\"todos\");",
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
