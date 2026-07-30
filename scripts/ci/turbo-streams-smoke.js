#!/usr/bin/env node

const { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "turbo_streams");
const runtimeAppDir = join(root, "test", ".generated", "turbo_streams_runtime");
const invalidSourceDir = join(root, "test", ".generated", "turbo_streams_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "turbo_streams_invalid_out");
const invalidStringTargetSourceDir = join(root, "test", ".generated", "turbo_streams_invalid_string_target_src");
const invalidStringTargetOutputDir = join(root, "test", ".generated", "turbo_streams_invalid_string_target_out");
const invalidRefreshStreamSourceDir = join(root, "test", ".generated", "turbo_streams_invalid_refresh_stream_src");
const invalidRefreshStreamOutputDir = join(root, "test", ".generated", "turbo_streams_invalid_refresh_stream_out");
const invalidRefreshRequestSourceDir = join(root, "test", ".generated", "turbo_streams_invalid_refresh_request_src");
const invalidRefreshRequestOutputDir = join(root, "test", ".generated", "turbo_streams_invalid_refresh_request_out");
const requireRails = process.env.REQUIRE_RAILS === "1" || process.env.CI_REQUIRE_RAILS === "1";
const supportMatrix = JSON.parse(readFileSync(join(root, "lib", "hxruby", "support_matrix.json"), "utf8"));
const railsVersion = supportMatrix.railsHx.verifiedRuntime.railsVersion;
// This focused fixture pins the exact upstream version whose refresh API shape
// and runtime bytes own the stable contract; public generated apps remain >=2.0.
const turboRailsVersion = "2.0.23";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
rmSync(runtimeAppDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });
rmSync(invalidStringTargetSourceDir, { force: true, recursive: true });
rmSync(invalidStringTargetOutputDir, { force: true, recursive: true });
rmSync(invalidRefreshStreamSourceDir, { force: true, recursive: true });
rmSync(invalidRefreshStreamOutputDir, { force: true, recursive: true });
rmSync(invalidRefreshRequestSourceDir, { force: true, recursive: true });
rmSync(invalidRefreshRequestOutputDir, { force: true, recursive: true });

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

const mainRuby = readFileSync(join(outputDir, "app", "lib", "railshx", "generated", "main.rb"), "utf8");
for (const expected of [
  /def self\.refresh_tag\(\)/,
  /turbo_stream\.refresh\(\)/,
  /def self\.refresh_tag_for_request\(\)/,
  /turbo_stream\.refresh\(request_id: "request-123"\)/,
  /def self\.refresh_tag_with_display_options\(\)/,
  /turbo_stream\.refresh\(method: "morph", scroll: "preserve"\)/,
  /def self\.broadcast_refresh\(\)/,
  /Turbo::StreamsChannel\.broadcast_refresh_to\("todos"\)/,
  /def self\.broadcast_refresh_for_request\(\)/,
  /Turbo::StreamsChannel\.broadcast_refresh_to\("todos", request_id: "request-123"\)/,
  /def self\.broadcast_refresh_with_options\(\)/,
  /Turbo::StreamsChannel\.broadcast_refresh_to\("todos", request_id: "request-123", method: "morph", scroll: "preserve"\)/,
  /def self\.broadcast_refresh_later\(\)/,
  /Turbo::StreamsChannel\.broadcast_refresh_later_to\("todos"\)/,
  /def self\.broadcast_refresh_later_with_options\(\)/,
  /Turbo::StreamsChannel\.broadcast_refresh_later_to\("todos", request_id: "request-123", method: "morph", scroll: "preserve"\)/,
  /Turbo::StreamsChannel\.broadcast_append_later_to\("todos", target: "todos", partial: "todos\/todo", locals:/,
  /Turbo::StreamsChannel\.broadcast_prepend_later_to\("todos", target: "todos", partial: "todos\/todo", locals:/,
  /Turbo::StreamsChannel\.broadcast_before_later_to\("todos", target: "todos", partial: "todos\/todo", locals:/,
  /Turbo::StreamsChannel\.broadcast_after_later_to\("todos", target: "todos", partial: "todos\/todo", locals:/,
  /Turbo::StreamsChannel\.broadcast_replace_later_to\("todos", target: "todos", partial: "todos\/todo", locals:/,
  /Turbo::StreamsChannel\.broadcast_update_later_to\("todos", target: "todos", partial: "todos\/todo", locals:/,
]) {
  if (!expected.test(mainRuby)) {
    fail(`Typed Turbo Streams output missing expected structural call: ${expected}`);
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

const invalidDelayedLocals = compileTurboStreams(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidDelayedLocalsMain",
  allowFailure: true,
});
if (invalidDelayedLocals.status === 0) {
  fail("Expected invalid delayed Turbo Streams locals compile to fail.");
}
if (!/has no field completed|completed|Bool/.test(invalidDelayedLocals.stderr + invalidDelayedLocals.stdout)) {
  process.stdout.write(invalidDelayedLocals.stdout);
  process.stderr.write(invalidDelayedLocals.stderr);
  fail("Invalid delayed Turbo Streams locals failed for an unexpected reason.");
}

const invalidDelayedStream = compileTurboStreams(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidDelayedStreamMain",
  allowFailure: true,
});
if (invalidDelayedStream.status === 0) {
  fail("Expected delayed Turbo render broadcast to reject a raw String stream name.");
}
if (!/String should be rails\.turbo\.StreamName|StreamName|Cannot unify/.test(invalidDelayedStream.stderr + invalidDelayedStream.stdout)) {
  process.stdout.write(invalidDelayedStream.stdout);
  process.stderr.write(invalidDelayedStream.stderr);
  fail("Invalid delayed Turbo render stream failed for an unexpected reason.");
}

const invalidDelayedTarget = compileTurboStreams(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidDelayedTargetMain",
  allowFailure: true,
});
if (invalidDelayedTarget.status === 0) {
  fail("Expected delayed Turbo render broadcast to reject a raw String target.");
}
if (!/String should be rails\.turbo\.StreamTarget|StreamTarget|Cannot unify/.test(invalidDelayedTarget.stderr + invalidDelayedTarget.stdout)) {
  process.stdout.write(invalidDelayedTarget.stdout);
  process.stderr.write(invalidDelayedTarget.stderr);
  fail("Invalid delayed Turbo render target failed for an unexpected reason.");
}

const invalidDelayedTemplate = compileTurboStreams(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidDelayedTemplateMain",
  allowFailure: true,
});
if (invalidDelayedTemplate.status === 0) {
  fail("Expected delayed Turbo render broadcast to reject a raw String template.");
}
if (!/String should be rails\.action_view\.Template|Template|Cannot unify/.test(invalidDelayedTemplate.stderr + invalidDelayedTemplate.stdout)) {
  process.stdout.write(invalidDelayedTemplate.stdout);
  process.stderr.write(invalidDelayedTemplate.stderr);
  fail("Invalid delayed Turbo render template failed for an unexpected reason.");
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

writeInvalidRefreshStreamFixture();

const invalidRefreshStream = compileTurboStreams(invalidRefreshStreamOutputDir, {
  classPath: invalidRefreshStreamSourceDir,
  main: "InvalidRefreshStreamMain",
  allowFailure: true,
});
if (invalidRefreshStream.status === 0) {
  fail("Expected Turbo refresh broadcast to reject a raw String stream name.");
}
if (!/String should be rails\.turbo\.StreamName|StreamName|Cannot unify/.test(invalidRefreshStream.stderr + invalidRefreshStream.stdout)) {
  process.stdout.write(invalidRefreshStream.stdout);
  process.stderr.write(invalidRefreshStream.stderr);
  fail("Invalid Turbo refresh stream failed for an unexpected reason.");
}

writeInvalidRefreshRequestFixture();

const invalidRefreshRequest = compileTurboStreams(invalidRefreshRequestOutputDir, {
  classPath: invalidRefreshRequestSourceDir,
  main: "InvalidRefreshRequestMain",
  allowFailure: true,
});
if (invalidRefreshRequest.status === 0) {
  fail("Expected Turbo refresh to reject a raw String request ID.");
}
if (!/String should be (?:Null<)?rails\.turbo\.(?:TurboRequestId|TurboRefreshOptions)|TurboRequestId|TurboRefreshOptions|Cannot unify/.test(invalidRefreshRequest.stderr + invalidRefreshRequest.stdout)) {
  process.stdout.write(invalidRefreshRequest.stdout);
  process.stderr.write(invalidRefreshRequest.stderr);
  fail("Invalid Turbo refresh request ID failed for an unexpected reason.");
}

const invalidRefreshMethod = compileTurboStreams(invalidRefreshRequestOutputDir, {
  classPath: invalidRefreshRequestSourceDir,
  main: "InvalidRefreshMethodMain",
  allowFailure: true,
});
if (invalidRefreshMethod.status === 0) {
  fail("Expected Turbo refresh to reject a raw String method.");
}
if (!/String should be rails\.turbo\.TurboRefreshMethod|TurboRefreshMethod|Cannot unify/.test(invalidRefreshMethod.stderr + invalidRefreshMethod.stdout)) {
  process.stdout.write(invalidRefreshMethod.stdout);
  process.stderr.write(invalidRefreshMethod.stderr);
  fail("Invalid Turbo refresh method failed for an unexpected reason.");
}

const invalidRefreshScroll = compileTurboStreams(invalidRefreshRequestOutputDir, {
  classPath: invalidRefreshRequestSourceDir,
  main: "InvalidRefreshScrollMain",
  allowFailure: true,
});
if (invalidRefreshScroll.status === 0) {
  fail("Expected Turbo refresh to reject a raw String scroll strategy.");
}
if (!/String should be rails\.turbo\.TurboRefreshScroll|TurboRefreshScroll|Cannot unify/.test(invalidRefreshScroll.stderr + invalidRefreshScroll.stdout)) {
  process.stdout.write(invalidRefreshScroll.stdout);
  process.stderr.write(invalidRefreshScroll.stderr);
  fail("Invalid Turbo refresh scroll strategy failed for an unexpected reason.");
}

const invalidRefreshField = compileTurboStreams(invalidRefreshRequestOutputDir, {
  classPath: invalidRefreshRequestSourceDir,
  main: "InvalidRefreshFieldMain",
  allowFailure: true,
});
if (invalidRefreshField.status === 0) {
  fail("Expected Turbo refresh to reject an unknown option field.");
}
if (!/options must be a typed object literal|bogus|TurboRefreshOptions/.test(invalidRefreshField.stderr + invalidRefreshField.stdout)) {
  process.stdout.write(invalidRefreshField.stdout);
  process.stderr.write(invalidRefreshField.stderr);
  fail("Invalid Turbo refresh option field failed for an unexpected reason.");
}

const invalidRefreshLaterField = compileTurboStreams(invalidRefreshRequestOutputDir, {
  classPath: invalidRefreshRequestSourceDir,
  main: "InvalidRefreshLaterFieldMain",
  allowFailure: true,
});
if (invalidRefreshLaterField.status === 0) {
  fail("Expected delayed Turbo refresh to reject an unknown option field.");
}
if (!/options must be a typed object literal|bogus|TurboRefreshOptions/.test(invalidRefreshLaterField.stderr + invalidRefreshLaterField.stdout)) {
  process.stdout.write(invalidRefreshLaterField.stdout);
  process.stderr.write(invalidRefreshLaterField.stderr);
  fail("Invalid delayed Turbo refresh option field failed for an unexpected reason.");
}

materializeRuntimeRailsApp();

const bundleProbe = run("bundle", ["check"], {
  cwd: runtimeAppDir,
  allowFailure: true,
});
if (bundleProbe.status !== 0) {
  if (requireRails) {
    assertRuntimeRubySupportsRails();
    process.stdout.write("[turbo-streams] Rails/Turbo bundle missing; running bundle install because REQUIRE_RAILS=1.\n");
    run("bundle", ["install"], { cwd: runtimeAppDir });
  } else {
    process.stdout.write("[turbo-streams] Rails/Turbo bundle unavailable; skipped refresh runtime test pass.\n");
    process.stdout.write("[turbo-streams] Set REQUIRE_RAILS=1 to install verified gems and make this lane mandatory.\n");
    console.log("[turbo-streams] OK");
    process.exit(0);
  }
}

run("bundle", ["exec", "rails", "test"], {
  cwd: runtimeAppDir,
  env: { ...process.env, RAILS_ENV: "test" },
});
console.log("[turbo-streams] Rails refresh and delayed render broadcast runtime OK");

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
  writeFileSync(join(invalidSourceDir, "InvalidDelayedLocalsMain.hx"), [
    "import rails.action_view.Template;",
    "import rails.turbo.StreamName;",
    "import rails.turbo.StreamTarget;",
    "import rails.turbo.TurboStreams;",
    "import views.TodoRowView;",
    "import views.TodoRowView.TodoRowLocals;",
    "class InvalidDelayedLocalsMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.broadcastAppendLaterTo(StreamName.named(\"todos\"), StreamTarget.named(\"todos\"), (Template.of(TodoRowView) : Template<TodoRowLocals>), {domId: \"todo_1\", title: \"missing completion\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidDelayedStreamMain.hx"), [
    "import rails.action_view.Template;",
    "import rails.turbo.StreamTarget;",
    "import rails.turbo.TurboStreams;",
    "import views.TodoRowView;",
    "import views.TodoRowView.TodoRowLocals;",
    "class InvalidDelayedStreamMain {",
    "\tstatic function main():Void {",
    "\t\tvar locals:TodoRowLocals = {domId: \"todo_1\", title: \"typed\", completed: false};",
    "\t\tTurboStreams.broadcastAppendLaterTo(\"todos\", StreamTarget.named(\"todos\"), (Template.of(TodoRowView) : Template<TodoRowLocals>), locals);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidDelayedTargetMain.hx"), [
    "import rails.action_view.Template;",
    "import rails.turbo.StreamName;",
    "import rails.turbo.TurboStreams;",
    "import views.TodoRowView;",
    "import views.TodoRowView.TodoRowLocals;",
    "class InvalidDelayedTargetMain {",
    "\tstatic function main():Void {",
    "\t\tvar locals:TodoRowLocals = {domId: \"todo_1\", title: \"typed\", completed: false};",
    "\t\tTurboStreams.broadcastAppendLaterTo(StreamName.named(\"todos\"), \"todos\", (Template.of(TodoRowView) : Template<TodoRowLocals>), locals);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "InvalidDelayedTemplateMain.hx"), [
    "import rails.turbo.StreamName;",
    "import rails.turbo.StreamTarget;",
    "import rails.turbo.TurboStreams;",
    "import views.TodoRowView.TodoRowLocals;",
    "class InvalidDelayedTemplateMain {",
    "\tstatic function main():Void {",
    "\t\tvar locals:TodoRowLocals = {domId: \"todo_1\", title: \"typed\", completed: false};",
    "\t\tTurboStreams.broadcastAppendLaterTo(StreamName.named(\"todos\"), StreamTarget.named(\"todos\"), \"todos/todo\", locals);",
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

function writeInvalidRefreshStreamFixture() {
  mkdirSync(invalidRefreshStreamSourceDir, { recursive: true });
  writeFileSync(join(invalidRefreshStreamSourceDir, "InvalidRefreshStreamMain.hx"), [
    "import rails.turbo.TurboStreams;",
    "class InvalidRefreshStreamMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.broadcastRefreshLaterTo(\"todos\");",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function writeInvalidRefreshRequestFixture() {
  mkdirSync(invalidRefreshRequestSourceDir, { recursive: true });
  writeFileSync(join(invalidRefreshRequestSourceDir, "InvalidRefreshRequestMain.hx"), [
    "import rails.turbo.TurboStreams;",
    "class InvalidRefreshRequestMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.refresh(\"request-123\");",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidRefreshRequestSourceDir, "InvalidRefreshMethodMain.hx"), [
    "import rails.turbo.TurboStreams;",
    "class InvalidRefreshMethodMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.refresh({method: \"morph\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidRefreshRequestSourceDir, "InvalidRefreshScrollMain.hx"), [
    "import rails.turbo.TurboStreams;",
    "class InvalidRefreshScrollMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.refresh({scroll: \"preserve\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidRefreshRequestSourceDir, "InvalidRefreshFieldMain.hx"), [
    "import rails.turbo.TurboStreams;",
    "class InvalidRefreshFieldMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.refresh({bogus: true});",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidRefreshRequestSourceDir, "InvalidRefreshLaterFieldMain.hx"), [
    "import rails.turbo.StreamName;",
    "import rails.turbo.TurboStreams;",
    "class InvalidRefreshLaterFieldMain {",
    "\tstatic function main():Void {",
    "\t\tTurboStreams.broadcastRefreshLaterTo(StreamName.named(\"todos\"), {bogus: true});",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function materializeRuntimeRailsApp() {
  mkdirSync(runtimeAppDir, { recursive: true });
  copyFile(
    join(outputDir, "app", "lib", "railshx", "generated", "main.rb"),
    "app/lib/railshx/generated/main.rb",
  );
  copyFile(
    join(outputDir, "app", "views", "todos", "_todo.html.erb"),
    "app/views/todos/_todo.html.erb",
  );

  writeFile("Gemfile", `source "https://rubygems.org"

gem "rails", "${railsVersion}"
gem "turbo-rails", "${turboRailsVersion}"
`);

  writeFile("config/application.rb", `require "rails"
require "action_cable/engine"
require "turbo-rails"

module HXRubyTurboStreams
  class Application < Rails::Application
    config.load_defaults 8.1
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
    config.action_cable.adapter = :test
  end
end
`);

  writeFile("config/environment.rb", `require_relative "application"

Rails.application.initialize!
`);

  writeFile("test/test_helper.rb", `ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "action_cable/test_helper"
require "active_job/test_helper"
`);

  writeFile("test/turbo_refresh_test.rb", `require "test_helper"
require Rails.root.join("app/lib/railshx/generated/main")

class TurboRefreshTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  include ActiveJob::TestHelper

  setup do
    clear_enqueued_jobs
    clear_performed_jobs
    view_context = Object.new
    view_context.define_singleton_method(:formats) { @formats ||= [] }
    Main.define_singleton_method(:turbo_stream) do
      Turbo::Streams::TagBuilder.new(view_context)
    end
  end

  test "renders the generated targetless refresh action" do
    assert_equal '<turbo-stream action="refresh"></turbo-stream>', Main.refresh_tag.to_s
  end

  test "renders an explicit typed request id on the refresh action" do
    assert_equal '<turbo-stream request-id="request-123" action="refresh"></turbo-stream>', Main.refresh_tag_for_request.to_s
  end

  test "renders closed method and scroll options on the refresh action" do
    assert_equal '<turbo-stream method="morph" scroll="preserve" action="refresh"></turbo-stream>', Main.refresh_tag_with_display_options.to_s
  end

  test "broadcasts the generated refresh action to the typed stream" do
    assert_broadcasts("todos", 1) do
      Main.broadcast_refresh
    end

    assert_equal '<turbo-stream action="refresh"></turbo-stream>', broadcasts("todos").last
  end

  test "broadcasts an explicit typed request id to the typed stream" do
    assert_broadcasts("todos", 1) do
      Main.broadcast_refresh_for_request
    end

    assert_equal '<turbo-stream request-id="request-123" action="refresh"></turbo-stream>', broadcasts("todos").last
  end

  test "broadcasts request, method, and scroll options to the typed stream" do
    assert_broadcasts("todos", 1) do
      Main.broadcast_refresh_with_options
    end

    assert_equal '<turbo-stream request-id="request-123" method="morph" scroll="preserve" action="refresh"></turbo-stream>', broadcasts("todos").last
  end

  test "debounces and performs one typed delayed refresh broadcast" do
    2.times { Main.broadcast_refresh_later_with_options }
    Turbo::StreamsChannel.refresh_debouncer_for("todos", request_id: "request-123").wait

    assert_enqueued_jobs 1, only: Turbo::Streams::BroadcastStreamJob
    assert_broadcasts("todos", 1) do
      perform_enqueued_jobs only: Turbo::Streams::BroadcastStreamJob
    end

    assert_equal '<turbo-stream request-id="request-123" method="morph" scroll="preserve" action="refresh"></turbo-stream>', broadcasts("todos").last
  end

  test "enqueues and performs all typed delayed render broadcasts" do
    append_locals = {"domId" => "todo_1", "title" => "Appended later", "completed" => false}
    replace_locals = {"domId" => "todo_1", "title" => "Replaced later", "completed" => true}

    assert_enqueued_jobs 6, only: Turbo::Streams::ActionBroadcastJob do
      Main.broadcast_render_actions_later(append_locals, replace_locals)
    end

    arguments = enqueued_jobs
      .select { |job| job[:job] == Turbo::Streams::ActionBroadcastJob }
      .map { |job| ActiveJob::Arguments.deserialize(job[:args]) }
    assert_equal Array.new(6, "todos"), arguments.map(&:first)
    assert_equal %i[append prepend before after replace update], arguments.map { |args| args.fetch(1).fetch(:action) }
    assert_equal Array.new(6, "todos"), arguments.map { |args| args.fetch(1).fetch(:target) }
    assert_equal Array.new(6, "todos/todo"), arguments.map { |args| args.fetch(1).fetch(:partial) }

    assert_broadcasts("todos", 6) do
      perform_enqueued_jobs only: Turbo::Streams::ActionBroadcastJob
    end

    actions = broadcasts("todos").map { |content| content.match(/action="([^"]+)"/)[1] }
    assert_equal %w[append prepend before after replace update], actions
    assert broadcasts("todos").all? { |content| content.include?('target="todos"') }
    assert_includes broadcasts("todos")[0], "Appended later"
    assert_includes broadcasts("todos")[4], "Replaced later"
  end
end
`);
}

function copyFile(source, relativeTarget) {
  const target = join(runtimeAppDir, relativeTarget);
  mkdirSync(dirname(target), { recursive: true });
  copyFileSync(source, target);
}

function writeFile(relativePath, content) {
  const target = join(runtimeAppDir, relativePath);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, content);
}

function assertRuntimeRubySupportsRails() {
  const rubyVersion = run("ruby", ["-e", "print RUBY_VERSION"], { allowFailure: true }).stdout.trim();
  if (!rubyAtLeast(rubyVersion, "3.3.0")) {
    console.error(`[turbo-streams] REQUIRE_RAILS=1 requires Ruby >= 3.3.0; current ruby is ${rubyVersion || "unknown"}.`);
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
    env: options.env ?? process.env,
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
