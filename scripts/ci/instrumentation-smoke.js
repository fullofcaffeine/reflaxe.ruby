#!/usr/bin/env node

const { existsSync, mkdirSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "instrumentation");
const invalidSourceDir = join(root, "test", ".generated", "instrumentation_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "instrumentation_invalid_out");
const invalidSubscriptionSourceDir = join(root, "test", ".generated", "instrumentation_invalid_subscription_src");
const invalidSubscriptionOutputDir = join(root, "test", ".generated", "instrumentation_invalid_subscription_out");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });
rmSync(invalidSubscriptionSourceDir, { force: true, recursive: true });
rmSync(invalidSubscriptionOutputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  fail("Unable to find vendored Reflaxe source for instrumentation smoke.");
}

compileInstrumentation(outputDir);

// Generated ActiveSupport::Notifications Ruby shape is covered by committed
// snapshots. This smoke keeps the non-snapshot checks: required files, Ruby
// syntax, negative payload/subscription typing, and optional ActiveSupport
// runtime consumption when the gem is available.
for (const file of [
  "app/lib/railshx/generated/main.rb",
  "app/lib/railshx/runtime/hxruby/core.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    fail(`Expected instrumentation output file missing: ${fullPath}`);
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
writeInvalidSubscriptionFixtures();

const invalidPayload = compileInstrumentation(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidPayloadMain",
  allowFailure: true,
});
if (invalidPayload.status === 0) {
  fail("Expected invalid instrumentation payload compile to fail.");
}
if (!/has no field count|count/.test(invalidPayload.stderr + invalidPayload.stdout)) {
  process.stdout.write(invalidPayload.stdout);
  process.stderr.write(invalidPayload.stderr);
  fail("Invalid instrumentation payload failed for an unexpected reason.");
}

const invalidSubscriber = compileInstrumentation(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidSubscriberMain",
  allowFailure: true,
});
if (invalidSubscriber.status === 0) {
  fail("Expected invalid instrumentation subscriber compile to fail.");
}
if (!/String should be Int|Cannot unify|Int should be String/.test(invalidSubscriber.stderr + invalidSubscriber.stdout)) {
  process.stdout.write(invalidSubscriber.stdout);
  process.stderr.write(invalidSubscriber.stderr);
  fail("Invalid instrumentation subscriber failed for an unexpected reason.");
}

const invalidSubscription = compileInstrumentation(invalidSubscriptionOutputDir, {
  classPath: invalidSubscriptionSourceDir,
  main: "InvalidSubscriptionMain",
  allowFailure: true,
});
if (invalidSubscription.status === 0) {
  fail("Expected invalid instrumentation subscription handle compile to fail.");
}
if (!/rails\.active_support\.Subscription|Subscription|Cannot unify/.test(invalidSubscription.stderr + invalidSubscription.stdout)) {
  process.stdout.write(invalidSubscription.stdout);
  process.stderr.write(invalidSubscription.stderr);
  fail("Invalid instrumentation subscription handle failed for an unexpected reason.");
}

const activeSupportCheck = run("ruby", ["-e", 'require "active_support/notifications"'], { allowFailure: true });
if (activeSupportCheck.status !== 0) {
  console.log("[instrumentation] ActiveSupport is unavailable; skipped runtime notification pass.");
  console.log("[instrumentation] Static compile, Ruby syntax, and negative type checks passed.");
  process.exit(0);
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "open:2",
  "instrumented",
  "",
].join("\n");

if (actual !== expected) {
  console.error("instrumentation stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

console.log("[instrumentation] OK");

function compileInstrumentation(targetDir, options = {}) {
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
    options.classPath ?? join(root, "examples", "instrumentation"),
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
  writeFileSync(join(invalidSourceDir, "InvalidPayloadMain.hx"), [
    "import rails.active_support.EventName;",
    "import rails.active_support.Notifications;",
    "typedef TodoShipPayload = {",
    "\tvar listId:String;",
    "\tvar count:Int;",
    "}",
    "class TodoEvents {",
    "\tpublic static inline var shipped:EventName<TodoShipPayload> = \"todo.shipped\";",
    "}",
    "class InvalidPayloadMain {",
    "\tstatic function main():Void {",
    "\t\tNotifications.instrument(TodoEvents.shipped, {listId: \"open\"}, function():String {",
    "\t\t\treturn \"bad\";",
    "\t\t});",
    "\t}",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(invalidSourceDir, "InvalidSubscriberMain.hx"), [
    "import rails.active_support.EventName;",
    "import rails.active_support.NotificationEvent;",
    "import rails.active_support.Notifications;",
    "typedef TodoShipPayload = {",
    "\tvar listId:String;",
    "\tvar count:Int;",
    "}",
    "class TodoEvents {",
    "\tpublic static inline var shipped:EventName<TodoShipPayload> = \"todo.shipped\";",
    "}",
    "class InvalidSubscriberMain {",
    "\tstatic function main():Void {",
    "\t\tNotifications.subscribe(TodoEvents.shipped, function(event:NotificationEvent<TodoShipPayload>):Void {",
    "\t\t\tvar wrong:Int = event.payload.listId;",
    "\t\t});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function writeInvalidSubscriptionFixtures() {
  mkdirSync(invalidSubscriptionSourceDir, { recursive: true });
  writeFileSync(join(invalidSubscriptionSourceDir, "InvalidSubscriptionMain.hx"), [
    "import rails.active_support.Notifications;",
    "class InvalidSubscriptionMain {",
    "\tstatic function main():Void {",
    "\t\tNotifications.unsubscribe({});",
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
  console.error(`[instrumentation] ERROR: ${message}`);
  process.exit(1);
}
