#!/usr/bin/env node

const {
  copyFileSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "active_job");
const runtimeAppDir = join(root, "test", ".generated", "active_job_runtime");
const invalidSourceDir = join(root, "test", ".generated", "active_job_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "active_job_invalid_out");
const invalidLifecycleSourceDir = join(root, "test", ".generated", "active_job_invalid_lifecycle_src");
const invalidLifecycleOutputDir = join(root, "test", ".generated", "active_job_invalid_lifecycle_out");
const returnSourceDir = join(root, "test", ".generated", "active_job_return_src");
const returnOutputDir = join(root, "test", ".generated", "active_job_return_out");
const invalidReturnSourceDir = join(root, "test", ".generated", "active_job_invalid_return_src");
const invalidReturnOutputDir = join(root, "test", ".generated", "active_job_invalid_return_out");
const requireRails = process.env.REQUIRE_RAILS === "1" || process.env.CI_REQUIRE_RAILS === "1";
let currentStage = "startup";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stderr.write(`[active-job] failed during ${currentStage}: ${command} ${args.join(" ")}\n`);
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

rmSync(outputDir, { force: true, recursive: true });
rmSync(runtimeAppDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });
rmSync(invalidLifecycleSourceDir, { force: true, recursive: true });
rmSync(invalidLifecycleOutputDir, { force: true, recursive: true });
rmSync(returnSourceDir, { force: true, recursive: true });
rmSync(returnOutputDir, { force: true, recursive: true });
rmSync(invalidReturnSourceDir, { force: true, recursive: true });
rmSync(invalidReturnOutputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for ActiveJob smoke.");
  process.exit(1);
}

compileActiveJob(outputDir);

for (const file of [
  "app/jobs/discard_probe_job.rb",
  "app/jobs/retry_probe_job.rb",
  "app/jobs/send_welcome_email_job.rb",
  "app/lib/railshx/generated/main.rb",
  "app/lib/railshx/runtime/hxruby/core.rb",
  "app/lib/railshx/runtime/hxruby/hx_exception.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected ActiveJob output file missing: ${fullPath}`);
    process.exit(1);
  }
}

for (const legacyFile of [
  "app/haxe_gen/jobs/discard_probe_job.rb",
  "app/haxe_gen/jobs/retry_probe_job.rb",
  "app/haxe_gen/jobs/send_welcome_email_job.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
]) {
  const fullPath = join(outputDir, legacyFile);
  if (existsSync(fullPath)) {
    console.error(`ActiveJob smoke should not emit legacy haxe_gen/autoload file: ${fullPath}`);
    process.exit(1);
  }
}

const jobRuby = readFileSync(join(outputDir, "app", "jobs", "send_welcome_email_job.rb"), "utf8");
for (const expected of [
  /require "active_job\/railtie"/,
  /class SendWelcomeEmailJob < ActiveJob::Base/,
  /queue_as :mailers/,
  /retry_on StandardError, wait: 5\.seconds, attempts: 3/,
  /discard_on ActiveJob::DeserializationError/,
  /def perform\(user_id(?:__hx\d+)?, email(?:__hx\d+)?\)/,
  /payload(?:__hx\d+)? = \("welcome:" \+ email(?:__hx\d+)?\)/,
]) {
  if (!expected.test(jobRuby)) {
    console.error(`ActiveJob output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const retryJobRuby = readFileSync(join(outputDir, "app", "jobs", "retry_probe_job.rb"), "utf8");
for (const expected of [
	/class RetryProbeJob < ActiveJob::Base/,
	/queue_as :critical/,
	/retry_on StandardError, wait: 5\.seconds, attempts: 2, queue: :retries/,
	/def perform\(attempt(?:__hx\d+)?\)/,
	/raise HxException\.wrap\(\("retry:" \+ HXRuby\.stringify\(attempt(?:__hx\d+)?\)\)\)/,
]) {
  if (!expected.test(retryJobRuby)) {
    console.error(`ActiveJob retry output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const discardJobRuby = readFileSync(join(outputDir, "app", "jobs", "discard_probe_job.rb"), "utf8");
for (const expected of [
	/class DiscardProbeJob < ActiveJob::Base/,
	/queue_as :critical/,
	/discard_on ActiveJob::DeserializationError/,
	/def perform\(record_id(?:__hx\d+)?\)/,
	/raise ActiveJob::DeserializationError\.new\(\("discard:" \+ HXRuby\.stringify\(record_id(?:__hx\d+)?\)\)\)/,
]) {
  if (!expected.test(discardJobRuby)) {
    console.error(`ActiveJob discard output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "app", "lib", "railshx", "generated", "main.rb"), "utf8");
for (const expected of [
  /SendWelcomeEmailJob\.perform_later\(42, "reader@example.test"\)/,
  /SendWelcomeEmailJob\.perform_now\(7, "now@example.test"\)/,
  /RetryProbeJob\.perform_later\(1\)/,
  /DiscardProbeJob\.perform_later\(9\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`ActiveJob enqueue output missing expected call: ${expected}`);
    process.exit(1);
  }
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
for (const forbidden of [/require_relative "haxe\/macro\//, /require_relative "rails\/macros\//]) {
  if (forbidden.test(runRuby)) {
    console.error(`ActiveJob run.rb should not require macro-only runtime files: ${forbidden}`);
    process.exit(1);
  }
}

for (const file of [
  "app/jobs/send_welcome_email_job.rb",
  "app/jobs/retry_probe_job.rb",
  "app/jobs/discard_probe_job.rb",
  "app/lib/railshx/generated/main.rb",
  "run.rb",
]) {
  const result = run("ruby", ["-c", join(outputDir, file)], { allowFailure: true });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
}

writeInvalidFixture();
const invalid = compileActiveJob(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidMain",
  allowFailure: true,
});
if (invalid.status === 0) {
  console.error("Expected invalid ActiveJob enqueue compile to fail.");
  process.exit(1);
}
if (!/String should be Int|Int should be String|Cannot unify|Float should be Int/.test(invalid.stderr + invalid.stdout)) {
  process.stdout.write(invalid.stdout);
  process.stderr.write(invalid.stderr);
  console.error("Invalid ActiveJob enqueue compile failed for an unexpected reason.");
  process.exit(1);
}

writeReturnFixture(returnSourceDir, "ReturnMain", false);
compileActiveJob(returnOutputDir, {
  classPath: returnSourceDir,
  main: "ReturnMain",
});

writeReturnFixture(invalidReturnSourceDir, "InvalidReturnMain", true);
const invalidReturn = compileActiveJob(invalidReturnOutputDir, {
  classPath: invalidReturnSourceDir,
  main: "InvalidReturnMain",
  allowFailure: true,
});
if (invalidReturn.status === 0) {
  console.error("Expected invalid ActiveJob performNow return compile to fail.");
  process.exit(1);
}
if (!/String should be Int|Int should be String|Cannot unify/.test(invalidReturn.stderr + invalidReturn.stdout)) {
  process.stdout.write(invalidReturn.stdout);
  process.stderr.write(invalidReturn.stderr);
  console.error("Invalid ActiveJob return compile failed for an unexpected reason.");
  process.exit(1);
}

writeInvalidLifecycleFixture();
const invalidLifecycle = compileActiveJob(invalidLifecycleOutputDir, {
  classPath: invalidLifecycleSourceDir,
  main: "InvalidLifecycleMain",
  allowFailure: true,
});
if (invalidLifecycle.status === 0) {
  console.error("Expected invalid ActiveJob lifecycle compile to fail.");
  process.exit(1);
}
if (!/retryOnNamed exception "not a constant" is not a safe Ruby constant path/.test(invalidLifecycle.stderr + invalidLifecycle.stdout)) {
  process.stdout.write(invalidLifecycle.stdout);
  process.stderr.write(invalidLifecycle.stderr);
  console.error("Invalid ActiveJob lifecycle compile failed for an unexpected reason.");
  process.exit(1);
}

stage("runtime materialization", materializeRuntimeRailsApp);
stage("runtime ruby syntax", () => syntaxCheck([
  "app/jobs/send_welcome_email_job.rb",
  "app/jobs/retry_probe_job.rb",
  "app/jobs/discard_probe_job.rb",
  "config/application.rb",
  "config/environment.rb",
  "test/jobs/send_welcome_email_job_test.rb",
]));

const bundleProbe = stage("runtime bundle probe", () => run("bundle", ["check"], {
  cwd: runtimeAppDir,
  allowFailure: true,
}));
if (bundleProbe.status !== 0) {
  if (requireRails) {
    assertRuntimeRubySupportsRails();
    process.stdout.write("[active-job] Rails bundle missing; running bundle install because REQUIRE_RAILS=1.\n");
    stage("runtime bundle install", () => run("bundle", ["install"], { cwd: runtimeAppDir }));
  } else {
    process.stdout.write("[active-job] Rails bundle is not available for the generated ActiveJob app; skipped runtime Rails test pass.\n");
    process.stdout.write("[active-job] Set REQUIRE_RAILS=1 to install app gems and make this lane mandatory.\n");
    process.exit(0);
  }
}

stage("runtime job tests", () => run("bundle", ["exec", "rails", "test"], {
  cwd: runtimeAppDir,
  env: { ...process.env, RAILS_ENV: "test" },
}));

function compileActiveJob(targetDir, options = {}) {
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
    options.classPath ?? join(root, "examples", "active_job"),
    "-cp",
    join(root, "examples", "active_job"),
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

function writeInvalidFixture() {
  mkdirSync(invalidSourceDir, { recursive: true });
  writeFileSync(
    join(invalidSourceDir, "InvalidMain.hx"),
    [
      "import jobs.SendWelcomeEmailJob;",
      "",
      "class InvalidMain {",
      "\tstatic function main():Void {",
      "\t\tSendWelcomeEmailJob.performLater(\"not-an-int\", 42);",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
}

function writeReturnFixture(sourceDir, mainName, invalid) {
  mkdirSync(join(sourceDir, "jobs"), { recursive: true });
  writeFileSync(
    join(sourceDir, "jobs", "ReturnValueJob.hx"),
    [
      "package jobs;",
      "",
      "@:railsJob",
      "class ReturnValueJob extends rails.active_job.Base {",
      "\tpublic function perform(userId:Int):String {",
      "\t\treturn \"job:\" + Std.string(userId);",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
  writeFileSync(
    join(sourceDir, `${mainName}.hx`),
    [
      "import jobs.ReturnValueJob;",
      "",
      `class ${mainName} {`,
      "\tstatic function main():Void {",
      invalid
        ? "\t\tvar result:Int = ReturnValueJob.performNow(1);"
        : "\t\tvar result:String = ReturnValueJob.performNow(1);",
      "\t\tvar enqueued:rails.active_job.Base = ReturnValueJob.performLater(1);",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
}

function writeInvalidLifecycleFixture() {
  mkdirSync(invalidLifecycleSourceDir, { recursive: true });
  writeFileSync(
    join(invalidLifecycleSourceDir, "InvalidLifecycleMain.hx"),
    [
      "import rails.macros.JobDsl.*;",
      "",
      "@:railsJob",
      "class BadLifecycleJob extends rails.active_job.Base {",
      "\tstatic final lifecycle = {",
      "\t\tretryOnNamed(\"not a constant\", {attempts: 1});",
      "\t}",
      "",
      "\tpublic function perform():Void {}",
      "}",
      "",
      "class InvalidLifecycleMain {",
      "\tstatic function main():Void {",
      "\t\tBadLifecycleJob.performLater();",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
}

function materializeRuntimeRailsApp() {
  mkdirSync(runtimeAppDir, { recursive: true });
  copyTree(join(outputDir, "app"), join(runtimeAppDir, "app"));

  writeFile("Gemfile", `source "https://rubygems.org"

gem "rails", "8.1.3"
`);

  writeFile("config/application.rb", `require "rails"
require "active_job/railtie"

module HXRubyActiveJob
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
require "active_job/test_helper"
require Rails.root.join("app/lib/railshx/runtime/hxruby/core")
require Rails.root.join("app/lib/railshx/runtime/hxruby/hx_exception")
`);

  writeFile("test/jobs/send_welcome_email_job_test.rb", `require "test_helper"
require Rails.root.join("app/jobs/send_welcome_email_job")
require Rails.root.join("app/jobs/retry_probe_job")
require Rails.root.join("app/jobs/discard_probe_job")

class SendWelcomeEmailJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "uses the typed lifecycle queue" do
    assert_equal "mailers", SendWelcomeEmailJob.queue_name
  end

  test "enqueues with typed perform arguments" do
    assert_enqueued_with(job: SendWelcomeEmailJob, args: [42, "reader@example.test"], queue: "mailers") do
      SendWelcomeEmailJob.perform_later(42, "reader@example.test")
    end
  end

  test "serializes and deserializes typed perform arguments" do
    job = SendWelcomeEmailJob.new(42, "reader@example.test")
    payload = job.serialize

    assert_equal [42, "reader@example.test"], payload["arguments"]

    restored = ActiveJob::Base.deserialize(payload)
    assert_instance_of SendWelcomeEmailJob, restored
    assert_equal [42, "reader@example.test"], restored.arguments
  end

  test "performs enqueued work through Rails test helper" do
    assert_performed_jobs 1 do
      perform_enqueued_jobs do
        SendWelcomeEmailJob.perform_later(7, "now@example.test")
      end
    end
  end

  test "retry_on re-enqueues failed work on the typed retry queue" do
    assert_enqueued_with(job: RetryProbeJob, args: [1], queue: "retries") do
      perform_enqueued_jobs(only: RetryProbeJob) do
        RetryProbeJob.perform_later(1)
      end
    end
  end

  test "discard_on records discarded generated work through Rails test adapter" do
    assert_discarded_jobs 1 do
      perform_enqueued_jobs(only: DiscardProbeJob) do
        DiscardProbeJob.perform_later(9)
      end
    end
  end
end
`);
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
  process.stdout.write(`[active-job] stage: ${name}\n`);
  return callback();
}

function assertRuntimeRubySupportsRails() {
  const rubyVersion = run("ruby", ["-e", "print RUBY_VERSION"], { allowFailure: true }).stdout.trim();
  if (!rubyAtLeast(rubyVersion, "3.3.0")) {
    console.error(`[active-job] REQUIRE_RAILS=1 requires Ruby >= 3.3.0 for the supported RailsHx runtime; current ruby is ${rubyVersion || "unknown"}.`);
    console.error("[active-job] Activate the repo .ruby-version Ruby before running npm run test:rails-runtime.");
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
