#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "active_job");
const invalidSourceDir = join(root, "test", ".generated", "active_job_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "active_job_invalid_out");
const invalidLifecycleSourceDir = join(root, "test", ".generated", "active_job_invalid_lifecycle_src");
const invalidLifecycleOutputDir = join(root, "test", ".generated", "active_job_invalid_lifecycle_out");
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
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });
rmSync(invalidLifecycleSourceDir, { force: true, recursive: true });
rmSync(invalidLifecycleOutputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for ActiveJob smoke.");
  process.exit(1);
}

compileActiveJob(outputDir);

for (const file of [
  "app/haxe_gen/jobs/send_welcome_email_job.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected ActiveJob output file missing: ${fullPath}`);
    process.exit(1);
  }
}

const jobRuby = readFileSync(join(outputDir, "app", "haxe_gen", "jobs", "send_welcome_email_job.rb"), "utf8");
for (const expected of [
  /require "active_job\/railtie"/,
  /module Jobs/,
  /class SendWelcomeEmailJob < ActiveJob::Base/,
  /queue_as :mailers/,
  /retry_on StandardError, wait: 5\.seconds, attempts: 3/,
  /discard_on ActiveJob::DeserializationError/,
  /def perform\(user_id__hx\d+, email__hx\d+\)/,
  /payload__hx\d+ = \("welcome:" \+ email__hx\d+\)/,
]) {
  if (!expected.test(jobRuby)) {
    console.error(`ActiveJob output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "app", "haxe_gen", "main.rb"), "utf8");
for (const expected of [
  /Jobs::SendWelcomeEmailJob\.perform_later\(42, "reader@example.test"\)/,
  /Jobs::SendWelcomeEmailJob\.perform_now\(7, "now@example.test"\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`ActiveJob enqueue output missing expected call: ${expected}`);
    process.exit(1);
  }
}

for (const file of ["app/haxe_gen/jobs/send_welcome_email_job.rb", "app/haxe_gen/main.rb", "run.rb"]) {
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
