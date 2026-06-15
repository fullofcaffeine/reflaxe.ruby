#!/usr/bin/env node

const {
  copyFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync,
  mkdtempSync,
} = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "action_cable");
const runtimeAppDir = join(root, "test", ".generated", "action_cable_runtime");
const invalidSourceDir = join(root, "test", ".generated", "action_cable_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "action_cable_invalid_out");
const invalidRawStringSourceDir = join(root, "test", ".generated", "action_cable_invalid_raw_string_src");
const invalidRawStringOutputDir = join(root, "test", ".generated", "action_cable_invalid_raw_string_out");
const invalidConsumerSourceDir = join(root, "test", ".generated", "action_cable_invalid_consumer_src");
const invalidConsumerOutputDir = join(root, "test", ".generated", "action_cable_invalid_consumer_out");
const invalidPerformSourceDir = join(root, "test", ".generated", "action_cable_invalid_perform_src");
const invalidPerformOutputDir = join(root, "test", ".generated", "action_cable_invalid_perform_out");
const jsWorkDir = mkdtempSync(join(tmpdir(), "railshx-action-cable."));
const requireRails = process.env.REQUIRE_RAILS === "1" || process.env.CI_REQUIRE_RAILS === "1";
let currentStage = "startup";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
rmSync(runtimeAppDir, { force: true, recursive: true });
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
  /if \(list_id__hx\d+ == "reject"\)/,
  /self\.reject\(\)/,
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

stage("runtime materialization", materializeRuntimeRailsApp);
stage("runtime ruby syntax", () => syntaxCheck([
  "app/haxe_gen/channels/todos_channel.rb",
  "config/application.rb",
  "config/environment.rb",
  "test/channels/todos_channel_test.rb",
]));

const bundleProbe = stage("runtime bundle probe", () => run("bundle", ["check"], {
  cwd: runtimeAppDir,
  allowFailure: true,
}));
if (bundleProbe.status !== 0) {
  if (requireRails) {
    assertRuntimeRubySupportsRails();
    process.stdout.write("[action-cable] Rails bundle missing; running bundle install because REQUIRE_RAILS=1.\n");
    stage("runtime bundle install", () => run("bundle", ["install"], { cwd: runtimeAppDir }));
  } else {
    process.stdout.write("[action-cable] Rails bundle is not available for the generated ActionCable app; skipped runtime Rails test pass.\n");
    process.stdout.write("[action-cable] Set REQUIRE_RAILS=1 to install app gems and make this lane mandatory.\n");
    process.exit(0);
  }
}

stage("runtime channel tests", () => run("bundle", ["exec", "rails", "test"], {
  cwd: runtimeAppDir,
  env: { ...process.env, RAILS_ENV: "test" },
}));

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

function materializeRuntimeRailsApp() {
  mkdirSync(runtimeAppDir, { recursive: true });
  copyTree(join(outputDir, "app"), join(runtimeAppDir, "app"));
  copyTree(join(outputDir, "config"), join(runtimeAppDir, "config"));
  copyGeneratedSupportIntoHaxeGen();

  writeFile("Gemfile", `source "https://rubygems.org"

gem "rails", "7.2.3.1"
`);

  writeFile("config/application.rb", `require "rails"
require "action_cable/engine"

module HXRubyActionCable
  class Application < Rails::Application
    config.load_defaults 7.0
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
  end
end
`);

  writeFile("config/environment.rb", `require_relative "application"

Rails.application.initialize!
`);

  writeFile("test/test_helper.rb", `ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "action_cable/channel/test_case"
`);

  writeFile("test/channels/todos_channel_test.rb", `require "test_helper"
require Rails.root.join("app/haxe_gen/channels/todos_channel")

class TodosChannelTest < ActionCable::Channel::TestCase
  tests Channels::TodosChannel

  test "subscribes to the typed stream" do
    subscribe list_id: "open"

    assert subscription.confirmed?
    assert_has_stream "todos:open"
  end

  test "uses Rails connection stubs for identifier-backed channels" do
    stub_connection current_user_id: 42

    subscribe list_id: "open"

    assert_equal 42, connection.current_user_id
    assert_includes connection.identifiers, :current_user_id
    assert_has_stream "todos:open"
  end

  test "rejects typed subscription params through Rails rejection semantics" do
    subscribe list_id: "reject"

    assert subscription.rejected?
    assert_no_streams
  end

  test "unsubscribe clears typed streams through Rails lifecycle" do
    subscribe list_id: "open"
    assert_has_stream "todos:open"

    unsubscribe

    assert_no_streams
  end

  test "performs typed ping action and transmits payload" do
    subscribe list_id: "open"

    perform :ping

    assert_equal({"title" => "pong", "completed" => false}, transmissions.last)
  end

  test "broadcasts typed payload to stream" do
    assert_broadcast_on("todos:open", {"title" => "Typed cable payload", "completed" => false}) do
      Channels::TodosChannel.announce("open", "Typed cable payload")
    end
  end
end
`);
}

function copyGeneratedSupportIntoHaxeGen() {
  const haxeGenDir = join(runtimeAppDir, "app", "haxe_gen");
  for (const entry of readdirSync(outputDir, { withFileTypes: true })) {
    if (["app", "config", "run.rb", "_GeneratedFiles.json"].includes(entry.name)) {
      continue;
    }
    const sourcePath = join(outputDir, entry.name);
    const targetPath = join(haxeGenDir, entry.name);
    if (entry.isDirectory()) {
      copyTree(sourcePath, targetPath);
    } else if (entry.isFile()) {
      mkdirSync(dirname(targetPath), { recursive: true });
      copyFileSync(sourcePath, targetPath);
    }
  }
}

function syntaxCheck(relativeFiles) {
  for (const relativeFile of relativeFiles) {
    run("ruby", ["-c", join(runtimeAppDir, relativeFile)]);
  }
}

function copyTree(source, target) {
  mkdirSync(target, { recursive: true });
  for (const entry of readdirSync(source, { withFileTypes: true })) {
    const sourcePath = join(source, entry.name);
    const targetPath = join(target, entry.name);
    if (entry.isDirectory()) {
      copyTree(sourcePath, targetPath);
    } else if (entry.isFile()) {
      mkdirSync(dirname(targetPath), { recursive: true });
      copyFileSync(sourcePath, targetPath);
    }
  }
}

function writeFile(relativePath, content) {
  const fullPath = join(runtimeAppDir, relativePath);
  mkdirSync(dirname(fullPath), { recursive: true });
  writeFileSync(fullPath, content);
}

function stage(name, callback) {
  currentStage = name;
  process.stdout.write(`[action-cable] stage: ${name}\n`);
  return callback();
}

function assertRuntimeRubySupportsRails() {
  const rubyVersion = run("ruby", ["-e", "print RUBY_VERSION"], { allowFailure: true }).stdout.trim();
  if (!rubyAtLeast(rubyVersion, "3.1.0")) {
    console.error(`[action-cable] REQUIRE_RAILS=1 requires Ruby >= 3.1.0 for Rails 7.2.3.1; current ruby is ${rubyVersion || "unknown"}.`);
    console.error("[action-cable] Activate the repo .ruby-version Ruby before running npm run test:action-cable with REQUIRE_RAILS=1.");
    process.exit(1);
  }
}

function rubyAtLeast(actual, minimum) {
  const actualParts = actual.split(".").map((part) => Number.parseInt(part, 10));
  const minimumParts = minimum.split(".").map((part) => Number.parseInt(part, 10));
  for (let i = 0; i < minimumParts.length; i += 1) {
    const actualPart = Number.isFinite(actualParts[i]) ? actualParts[i] : 0;
    const minimumPart = minimumParts[i];
    if (actualPart > minimumPart) return true;
    if (actualPart < minimumPart) return false;
  }
  return true;
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stderr.write(`[action-cable] failed during ${currentStage}: ${command} ${args.join(" ")}\n`);
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
