#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "active_storage");
const invalidUnknownSourceDir = join(root, "test", ".generated", "active_storage_invalid_unknown_src");
const invalidUnknownOutputDir = join(root, "test", ".generated", "active_storage_invalid_unknown_out");
const invalidKindSourceDir = join(root, "test", ".generated", "active_storage_invalid_kind_src");
const invalidKindOutputDir = join(root, "test", ".generated", "active_storage_invalid_kind_out");
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

for (const dir of [outputDir, invalidUnknownSourceDir, invalidUnknownOutputDir, invalidKindSourceDir, invalidKindOutputDir]) {
  rmSync(dir, { force: true, recursive: true });
}

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for ActiveStorage smoke.");
  process.exit(1);
}

compileActiveStorage(outputDir);

for (const file of [
  "app/haxe_gen/models/profile.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected ActiveStorage output file missing: ${fullPath}`);
    process.exit(1);
  }
}

const profileRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "profile.rb"), "utf8");
for (const expected of [
  'require "active_record"',
  'require "active_storage/engine"',
  "class Profile < ::ApplicationRecord",
  'self.table_name = "profiles"',
  "has_one_attached :avatar",
  "has_many_attached :gallery",
  "# haxe column id: Int",
  "# haxe column name: String",
]) {
  if (!profileRuby.includes(expected)) {
    console.error(`ActiveStorage model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "app", "haxe_gen", "main.rb"), "utf8");
for (const expected of [
  /has_avatar__hx\d+ = profile__hx\d+\.avatar\(\)\.attached\?\(\)/,
  /profile__hx\d+\.avatar\(\)\.attach\("avatar.png"\)/,
  /profile__hx\d+\.avatar\(\)\.purge\(\)/,
  /has_gallery__hx\d+ = profile__hx\d+\.gallery\(\)\.attached\?\(\)/,
  /profile__hx\d+\.gallery\(\)\.attach\(\["one.png", "two.png"\]\)/,
  /profile__hx\d+\.gallery\(\)\.purge\(\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`ActiveStorage helper output missing expected call: ${expected}`);
    process.exit(1);
  }
}

for (const file of ["app/haxe_gen/models/profile.rb", "app/haxe_gen/main.rb", "run.rb"]) {
  const result = run("ruby", ["-c", join(outputDir, file)], { allowFailure: true });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
}

writeInvalidUnknownFixture();
const invalidUnknown = compileActiveStorage(invalidUnknownOutputDir, {
  classPath: invalidUnknownSourceDir,
  main: "InvalidUnknownMain",
  allowFailure: true,
});
if (invalidUnknown.status === 0) {
  console.error("Expected unknown ActiveStorage attachment compile to fail.");
  process.exit(1);
}
if (!/has no field missing|missing/.test(invalidUnknown.stderr + invalidUnknown.stdout)) {
  process.stdout.write(invalidUnknown.stdout);
  process.stderr.write(invalidUnknown.stderr);
  console.error("Unknown ActiveStorage attachment failed for an unexpected reason.");
  process.exit(1);
}

writeInvalidKindFixture();
const invalidKind = compileActiveStorage(invalidKindOutputDir, {
  classPath: invalidKindSourceDir,
  main: "InvalidKindMain",
  allowFailure: true,
});
if (invalidKind.status === 0) {
  console.error("Expected mismatched ActiveStorage attachment kind compile to fail.");
  process.exit(1);
}
if (!/must be typed as rails\.ActiveStorage\.One/.test(invalidKind.stderr + invalidKind.stdout)) {
  process.stdout.write(invalidKind.stdout);
  process.stderr.write(invalidKind.stderr);
  console.error("Mismatched ActiveStorage attachment kind failed for an unexpected reason.");
  process.exit(1);
}

function compileActiveStorage(targetDir, options = {}) {
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
    options.classPath ?? join(root, "examples", "active_storage"),
    "-cp",
    join(root, "examples", "active_storage"),
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

function writeInvalidUnknownFixture() {
  mkdirSync(invalidUnknownSourceDir, { recursive: true });
  writeFileSync(
    join(invalidUnknownSourceDir, "InvalidUnknownMain.hx"),
    [
      "import models.Profile;",
      "",
      "class InvalidUnknownMain {",
      "\tstatic function main():Void {",
      "\t\tvar profile = new Profile();",
      "\t\tProfile.attachments.missing.attach(profile, \"missing.png\");",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
}

function writeInvalidKindFixture() {
  mkdirSync(join(invalidKindSourceDir, "models"), { recursive: true });
  writeFileSync(
    join(invalidKindSourceDir, "InvalidKindMain.hx"),
    [
      "import models.BadProfile;",
      "",
      "class InvalidKindMain {",
      "\tstatic function main():Void {",
      "\t\tvar profile = new BadProfile();",
      "\t\tBadProfile.attachments.avatar.attach(profile, \"avatar.png\");",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
  writeFileSync(
    join(invalidKindSourceDir, "models", "BadProfile.hx"),
    [
      "package models;",
      "",
      "@:railsModel(\"bad_profiles\")",
      "class BadProfile extends rails.active_record.Base<BadProfile> {",
      "\t@:railsColumn({primaryKey: true, dbType: \"bigint\"}) public var id:Int;",
      "\t@:hasOneAttached public var avatar:rails.ActiveStorage.Many<BadProfile>;",
      "}",
      "",
    ].join("\n"),
  );
}
