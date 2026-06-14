#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync, mkdtempSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "action_cable");
const invalidSourceDir = join(root, "test", ".generated", "action_cable_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "action_cable_invalid_out");
const invalidRawStringSourceDir = join(root, "test", ".generated", "action_cable_invalid_raw_string_src");
const invalidRawStringOutputDir = join(root, "test", ".generated", "action_cable_invalid_raw_string_out");
const invalidConsumerSourceDir = join(root, "test", ".generated", "action_cable_invalid_consumer_src");
const invalidConsumerOutputDir = join(root, "test", ".generated", "action_cable_invalid_consumer_out");
const invalidPerformSourceDir = join(root, "test", ".generated", "action_cable_invalid_perform_src");
const invalidPerformOutputDir = join(root, "test", ".generated", "action_cable_invalid_perform_out");
const jsWorkDir = mkdtempSync(join(tmpdir(), "railshx-action-cable."));
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });
rmSync(invalidRawStringSourceDir, { force: true, recursive: true });
rmSync(invalidRawStringOutputDir, { force: true, recursive: true });
rmSync(invalidConsumerSourceDir, { force: true, recursive: true });
rmSync(invalidConsumerOutputDir, { force: true, recursive: true });
rmSync(invalidPerformSourceDir, { force: true, recursive: true });
rmSync(invalidPerformOutputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  fail("Unable to find vendored Reflaxe source for ActionCable smoke.");
}

compileActionCable(outputDir);

for (const file of [
  "app/haxe_gen/channels/todos_channel.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    fail(`Expected ActionCable output file missing: ${fullPath}`);
  }
}

const channelRuby = readFileSync(join(outputDir, "app", "haxe_gen", "channels", "todos_channel.rb"), "utf8");
for (const expected of [
  /require "action_cable\/engine"/,
  /module Channels/,
  /class TodosChannel < ActionCable::Channel::Base/,
  /def subscribed\(\)/,
  /params\["list_id"\]/,
  /self\.stream_from/,
  /def unsubscribed\(\)/,
  /self\.stop_all_streams\(\)/,
  /def ping\(\)/,
  /self\.transmit\(\{"title" => "pong", "completed" => false\}\)/,
  /def self\.announce\(list_id__hx\d+, title__hx\d+\)/,
  /ActionCable\.server\.broadcast/,
  /\{"title" => title__hx\d+, "completed" => false\}/,
]) {
  if (!expected.test(channelRuby)) {
    fail(`ActionCable channel output missing expected line: ${expected}`);
  }
}

const mainRuby = readFileSync(join(outputDir, "app", "haxe_gen", "main.rb"), "utf8");
if (!/Channels::TodosChannel\.announce\("open", "Typed cable payload"\)/.test(mainRuby)) {
  fail("ActionCable main output missing typed broadcast call.");
}

for (const file of ["app/haxe_gen/channels/todos_channel.rb", "app/haxe_gen/main.rb", "run.rb"]) {
  const result = run("ruby", ["-c", join(outputDir, file)], { allowFailure: true });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
}

compileClient();
writeInvalidFixtures();
writeInvalidRawStringFixtures();
writeInvalidConsumerFixtures();
writeInvalidPerformFixtures();

const invalidPayload = compileActionCable(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidPayloadMain",
  allowFailure: true,
});
if (invalidPayload.status === 0) {
  fail("Expected invalid ActionCable payload compile to fail.");
}
if (!/has no field completed|completed/.test(invalidPayload.stderr + invalidPayload.stdout)) {
  process.stdout.write(invalidPayload.stdout);
  process.stderr.write(invalidPayload.stderr);
  fail("Invalid ActionCable payload failed for an unexpected reason.");
}

const invalidParam = compileActionCable(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidParamMain",
  allowFailure: true,
});
if (invalidParam.status === 0) {
  fail("Expected invalid ActionCable param compile to fail.");
}
if (!/String should be Int|Cannot unify|Int should be String/.test(invalidParam.stderr + invalidParam.stdout)) {
  process.stdout.write(invalidParam.stdout);
  process.stderr.write(invalidParam.stderr);
  fail("Invalid ActionCable param failed for an unexpected reason.");
}

const invalidChannel = compileActionCable(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidChannelMain",
  allowFailure: true,
});
if (invalidChannel.status === 0) {
  fail("Expected missing subscribed() ActionCable channel compile to fail.");
}
if (!/@:railsChannel classes must define an instance subscribed\(\) method/.test(invalidChannel.stderr + invalidChannel.stdout)) {
  process.stdout.write(invalidChannel.stdout);
  process.stderr.write(invalidChannel.stderr);
  fail("Invalid ActionCable channel failed for an unexpected reason.");
}

const invalidRawParam = compileActionCable(invalidRawStringOutputDir, {
  classPath: invalidRawStringSourceDir,
  main: "InvalidRawParamMain",
  allowFailure: true,
});
if (invalidRawParam.status === 0) {
  fail("Expected raw string ActionCable param compile to fail.");
}
if (!/String should be rails\.action_cable\.SubscriptionParam|SubscriptionParam|Cannot unify/.test(invalidRawParam.stderr + invalidRawParam.stdout)) {
  process.stdout.write(invalidRawParam.stdout);
  process.stderr.write(invalidRawParam.stderr);
  fail("Raw string ActionCable param failed for an unexpected reason.");
}

const invalidRawStream = compileActionCable(invalidRawStringOutputDir, {
  classPath: invalidRawStringSourceDir,
  main: "InvalidRawStreamMain",
  allowFailure: true,
});
if (invalidRawStream.status === 0) {
  fail("Expected raw string ActionCable stream compile to fail.");
}
if (!/String should be rails\.action_cable\.Stream|Stream|Cannot unify/.test(invalidRawStream.stderr + invalidRawStream.stdout)) {
  process.stdout.write(invalidRawStream.stdout);
  process.stderr.write(invalidRawStream.stderr);
  fail("Raw string ActionCable stream failed for an unexpected reason.");
}

const invalidConsumer = compileClient({
  classPath: invalidConsumerSourceDir,
  main: "InvalidConsumerMain",
  allowFailure: true,
});
if (invalidConsumer.status === 0) {
  fail("Expected raw object ActionCable consumer compile to fail.");
}
if (!/rails\.action_cable\.Consumer|Consumer|Cannot unify/.test(invalidConsumer.stderr + invalidConsumer.stdout)) {
  process.stdout.write(invalidConsumer.stdout);
  process.stderr.write(invalidConsumer.stderr);
  fail("Raw object ActionCable consumer failed for an unexpected reason.");
}

const invalidRawPerform = compileClient({
  classPath: invalidPerformSourceDir,
  main: "InvalidRawPerformMain",
  allowFailure: true,
});
if (invalidRawPerform.status === 0) {
  fail("Expected raw string ActionCable perform action compile to fail.");
}
if (!/rails\.action_cable\.Action|Action|Cannot unify/.test(invalidRawPerform.stderr + invalidRawPerform.stdout)) {
  process.stdout.write(invalidRawPerform.stdout);
  process.stderr.write(invalidRawPerform.stderr);
  fail("Raw string ActionCable perform action failed for an unexpected reason.");
}

const invalidPerformPayload = compileClient({
  classPath: invalidPerformSourceDir,
  main: "InvalidPerformPayloadMain",
  allowFailure: true,
});
if (invalidPerformPayload.status === 0) {
  fail("Expected invalid ActionCable perform payload compile to fail.");
}
if (!/has no field title|title|Cannot unify/.test(invalidPerformPayload.stderr + invalidPerformPayload.stdout)) {
  process.stdout.write(invalidPerformPayload.stdout);
  process.stderr.write(invalidPerformPayload.stderr);
  fail("Invalid ActionCable perform payload failed for an unexpected reason.");
}

console.log("[action-cable] OK");

function compileActionCable(targetDir, options = {}) {
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
    options.classPath ?? join(root, "examples", "action_cable"),
    "-cp",
    join(root, "examples", "action_cable"),
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

function compileClient(options = {}) {
  const srcDir = options.classPath ?? join(jsWorkDir, "src");
  const outFile = join(jsWorkDir, `${options.main ?? "cable_client"}.js`);
  mkdirSync(srcDir, { recursive: true });
  if (!options.classPath) {
    writeFileSync(join(srcDir, "CableClientMain.hx"), [
      "import client.TodosCableClient;",
      "import rails.action_cable.Consumer;",
      "class CableClientMain {",
      "\tstatic function main():Void {",
      "\t\tvar consumer = Consumer.create();",
      "\t\tTodosCableClient.subscribe(consumer, \"open\", function(title) {});",
      "\t}",
      "}",
      "",
    ].join("\n"));
  }
  const result = run("haxe", [
    "-cp",
    join(root, "std"),
    "-cp",
    join(root, "examples", "action_cable"),
    "-cp",
    srcDir,
    "-main",
    options.main ?? "CableClientMain",
    "-js",
    outFile,
    "--dce=full",
  ], { allowFailure: options.allowFailure });
  if (options.allowFailure) {
    return result;
  }
  const js = readFileSync(outFile, "utf8");
  for (const expected of [
    "ActionCable.createConsumer()",
    "Object.assign({ channel: channel }, params)",
    "consumer.subscriptions.create(identifier, callbacks)",
    "subscription.perform(\"ping\", { title : \"client ping\"})",
    "Channels::TodosChannel",
    "received",
  ]) {
    if (!js.includes(expected)) {
      fail(`ActionCable JS client output missing ${expected}`);
    }
  }
  return result;
}

function writeInvalidFixtures() {
  mkdirSync(invalidSourceDir, { recursive: true });
  writeFileSync(join(invalidSourceDir, "InvalidPayloadMain.hx"), [
    "import rails.ActionCable;",
    "import channels.TodosChannel.TodoCable;",
    "class InvalidPayloadMain {",
    "\tstatic function main():Void {",
    "\t\tActionCable.broadcast(TodoCable.listStream(\"open\"), {title: \"missing completed\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidParamMain.hx"), [
    "import channels.TodosChannel.TodoCable;",
    "import rails.action_cable.Channel;",
    "import channels.TodosChannel.TodoBroadcast;",
    "import channels.TodosChannel.TodoSubscriptionParams;",
    "@:railsChannel",
    "class BadParamChannel extends Channel<TodoSubscriptionParams, TodoBroadcast> {",
    "\tpublic function subscribed():Void {",
    "\t\tvar wrong:Int = param(TodoCable.listId());",
    "\t}",
    "}",
    "class InvalidParamMain { static function main():Void {} }",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidChannelMain.hx"), [
    "import rails.action_cable.Channel;",
    "import channels.TodosChannel.TodoBroadcast;",
    "import channels.TodosChannel.TodoSubscriptionParams;",
    "@:railsChannel",
    "class MissingSubscribedChannel extends Channel<TodoSubscriptionParams, TodoBroadcast> {}",
    "class InvalidChannelMain { static function main():Void {} }",
    "",
  ].join("\n"));
}

function writeInvalidRawStringFixtures() {
  mkdirSync(invalidRawStringSourceDir, { recursive: true });
  writeFileSync(join(invalidRawStringSourceDir, "InvalidRawParamMain.hx"), [
    "import rails.action_cable.Channel;",
    "import channels.TodosChannel.TodoBroadcast;",
    "import channels.TodosChannel.TodoSubscriptionParams;",
    "@:railsChannel",
    "class RawParamChannel extends Channel<TodoSubscriptionParams, TodoBroadcast> {",
    "\tpublic function subscribed():Void {",
    "\t\tvar listId = param(\"listId\");",
    "\t}",
    "}",
    "class InvalidRawParamMain { static function main():Void {} }",
    "",
  ].join("\n"));
  writeFileSync(join(invalidRawStringSourceDir, "InvalidRawStreamMain.hx"), [
    "import rails.ActionCable;",
    "class InvalidRawStreamMain {",
    "\tstatic function main():Void {",
    "\t\tActionCable.broadcast(\"todos:open\", {title: \"raw\", completed: false});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function writeInvalidConsumerFixtures() {
  mkdirSync(invalidConsumerSourceDir, { recursive: true });
  writeFileSync(join(invalidConsumerSourceDir, "InvalidConsumerMain.hx"), [
    "import client.TodosCableClient;",
    "class InvalidConsumerMain {",
    "\tstatic function main():Void {",
    "\t\tTodosCableClient.subscribe({}, \"open\", function(title) {});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function writeInvalidPerformFixtures() {
  mkdirSync(invalidPerformSourceDir, { recursive: true });
  writeFileSync(join(invalidPerformSourceDir, "InvalidRawPerformMain.hx"), [
    "import rails.action_cable.Consumer;",
    "class InvalidRawPerformMain {",
    "\tstatic function main():Void {",
    "\t\tvar subscription = Consumer.subscribe(Consumer.create(), \"Channels::TodosChannel\", {listId: \"open\"}, {});",
    "\t\tsubscription.perform(\"ping\", {title: \"raw action string\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidPerformSourceDir, "InvalidPerformPayloadMain.hx"), [
    "import channels.TodosChannel.TodoCable;",
    "import rails.action_cable.Consumer;",
    "class InvalidPerformPayloadMain {",
    "\tstatic function main():Void {",
    "\t\tvar subscription = Consumer.subscribe(Consumer.create(), \"Channels::TodosChannel\", {listId: \"open\"}, {});",
    "\t\tsubscription.perform(TodoCable.pingAction(), {missingTitle: \"bad payload\"});",
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
  console.error(`[action-cable] ERROR: ${message}`);
  process.exit(1);
}
