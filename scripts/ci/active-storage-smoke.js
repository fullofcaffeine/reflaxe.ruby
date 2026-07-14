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
const outputDir = join(root, "test", ".generated", "active_storage");
const runtimeAppDir = join(root, "test", ".generated", "active_storage_runtime");
const invalidUnknownSourceDir = join(root, "test", ".generated", "active_storage_invalid_unknown_src");
const invalidUnknownOutputDir = join(root, "test", ".generated", "active_storage_invalid_unknown_out");
const invalidKindSourceDir = join(root, "test", ".generated", "active_storage_invalid_kind_src");
const invalidKindOutputDir = join(root, "test", ".generated", "active_storage_invalid_kind_out");
const invalidAttachSourceDir = join(root, "test", ".generated", "active_storage_invalid_attach_src");
const invalidAttachOutputDir = join(root, "test", ".generated", "active_storage_invalid_attach_out");
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
    env: options.env ?? process.env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stderr.write(`[active-storage] failed during ${currentStage}: ${command} ${args.join(" ")}\n`);
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

for (const dir of [outputDir, runtimeAppDir, invalidUnknownSourceDir, invalidUnknownOutputDir, invalidKindSourceDir, invalidKindOutputDir, invalidAttachSourceDir, invalidAttachOutputDir]) {
  rmSync(dir, { force: true, recursive: true });
}

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for ActiveStorage smoke.");
  process.exit(1);
}

compileActiveStorage(outputDir);

for (const file of [
  "app/models/profile.rb",
  "app/lib/railshx/generated/main.rb",
  "app/views/profiles/_upload_form.html.erb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected ActiveStorage output file missing: ${fullPath}`);
    process.exit(1);
  }
}

for (const legacyFile of [
  "app/haxe_gen/models/profile.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
]) {
  const fullPath = join(outputDir, legacyFile);
  if (existsSync(fullPath)) {
    console.error(`ActiveStorage smoke should not emit legacy haxe_gen/autoload file: ${fullPath}`);
    process.exit(1);
  }
}

const profileRuby = readFileSync(join(outputDir, "app", "models", "profile.rb"), "utf8");
for (const expected of [
  'require "active_record"',
  'require "active_storage/engine"',
  "class Profile < ApplicationRecord",
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

const mainRuby = readFileSync(join(outputDir, "app", "lib", "railshx", "generated", "main.rb"), "utf8");
for (const expected of [
  /has_avatar(?:__hx\d+)? = profile(?:__hx\d+)?\.avatar\(\)\.attached\?\(\)/,
  /profile(?:__hx\d+)?\.avatar\(\)\.attach\("avatar.png"\)/,
  /profile(?:__hx\d+)?\.avatar\(\)\.attach\(\{"io" => File\.open\("avatar.png"\), "filename" => "avatar.png", "content_type" => "image\/png"\}\)/,
  /uploaded_signed_id(?:__hx\d+)? = uploaded_blob(?:__hx\d+)?\.signed_id\(\)/,
  /uploaded_filename(?:__hx\d+)? = uploaded_blob(?:__hx\d+)?\.filename\(\)\.to_s\(\)/,
  /uploaded_content_type(?:__hx\d+)? = uploaded_blob(?:__hx\d+)?\.content_type\(\)/,
  /direct_upload_url(?:__hx\d+)? = uploaded_blob(?:__hx\d+)?\.service_url_for_direct_upload\(\)/,
  /direct_upload_headers(?:__hx\d+)? = uploaded_blob(?:__hx\d+)?\.service_headers_for_direct_upload\(\)/,
  /profile(?:__hx\d+)?\.avatar\(\)\.attach\(uploaded_signed_id(?:__hx\d+)?\)/,
  /profile(?:__hx\d+)?\.avatar\(\)\.attach\(uploaded_blob(?:__hx\d+)?\)/,
  /profile(?:__hx\d+)?\.avatar\(\)\.purge\(\)/,
  /has_gallery(?:__hx\d+)? = profile(?:__hx\d+)?\.gallery\(\)\.attached\?\(\)/,
  /profile(?:__hx\d+)?\.gallery\(\)\.attach\(\["one.png", "two.png"\]\)/,
  /profile(?:__hx\d+)?\.gallery\(\)\.attach\(\[\{"io" => File\.open\("one.png"\), "filename" => "one.png", "content_type" => "image\/png"\}, \{"io" => File\.open\("two.png"\), "filename" => "two.png", "content_type" => "image\/png"\}\]\)/,
  /profile(?:__hx\d+)?\.gallery\(\)\.purge\(\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`ActiveStorage helper output missing expected call: ${expected}`);
    process.exit(1);
  }
}

const uploadFormErb = readFileSync(join(outputDir, "app", "views", "profiles", "_upload_form.html.erb"), "utf8");
for (const expected of [
  '<%= form_with url: "/profiles", scope: :profile, local: true, multipart: true, class: "profile-upload-form" do |form| %>',
  '<%= form.label :avatar, "Avatar" %>',
  '<%= form.file_field :avatar, direct_upload: true, accept: "image/png,image/jpeg" %>',
]) {
  if (!uploadFormErb.includes(expected)) {
    console.error(`ActiveStorage upload form output missing expected line: ${expected}`);
    process.exit(1);
  }
}

for (const file of ["app/models/profile.rb", "app/lib/railshx/generated/main.rb", "run.rb"]) {
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

writeInvalidAttachFixture();
const invalidAttach = compileActiveStorage(invalidAttachOutputDir, {
  classPath: invalidAttachSourceDir,
  main: "InvalidAttachMain",
  allowFailure: true,
});
if (invalidAttach.status === 0) {
  console.error("Expected invalid ActiveStorage attachable compile to fail.");
  process.exit(1);
}
if (!/String|Array<String>|Cannot unify/.test(invalidAttach.stderr + invalidAttach.stdout)) {
  process.stdout.write(invalidAttach.stdout);
  process.stderr.write(invalidAttach.stderr);
  console.error("Invalid ActiveStorage attachable failed for an unexpected reason.");
  process.exit(1);
}

stage("runtime materialization", materializeRuntimeRailsApp);
stage("runtime ruby syntax", () => syntaxCheck([
  "app/models/profile.rb",
  "app/models/application_record.rb",
  "config/application.rb",
  "config/environment.rb",
  "config/routes.rb",
  "db/migrate/20260101000000_create_profiles.rb",
  "test/models/profile_attachment_test.rb",
]));

const bundleProbe = stage("runtime bundle probe", () => run("bundle", ["check"], {
  cwd: runtimeAppDir,
  allowFailure: true,
}));
if (bundleProbe.status !== 0) {
  if (requireRails) {
    assertRuntimeRubySupportsRails();
    process.stdout.write("[active-storage] Rails bundle missing; running bundle install because REQUIRE_RAILS=1.\n");
    stage("runtime bundle install", () => run("bundle", ["install"], { cwd: runtimeAppDir }));
  } else {
    process.stdout.write("[active-storage] Rails bundle is not available for the generated ActiveStorage app; skipped runtime Rails test pass.\n");
    process.stdout.write("[active-storage] Set REQUIRE_RAILS=1 to install app gems and make this lane mandatory.\n");
    process.exit(0);
  }
}

stage("active storage install", () => run("bundle", ["exec", "rails", "active_storage:install"], {
  cwd: runtimeAppDir,
  env: { ...process.env, RAILS_ENV: "test" },
}));
stage("runtime migration", () => run("bundle", ["exec", "rails", "db:migrate"], {
  cwd: runtimeAppDir,
  env: { ...process.env, RAILS_ENV: "test" },
}));
stage("runtime storage tests", () => run("bundle", ["exec", "rails", "test"], {
  cwd: runtimeAppDir,
  env: { ...process.env, RAILS_ENV: "test" },
}));

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

function writeInvalidAttachFixture() {
  mkdirSync(invalidAttachSourceDir, { recursive: true });
  writeFileSync(
    join(invalidAttachSourceDir, "InvalidAttachMain.hx"),
    [
      "import models.Profile;",
      "",
      "class InvalidAttachMain {",
      "\tstatic function main():Void {",
      "\t\tvar profile = new Profile();",
      "\t\tProfile.attachments.avatar.attach(profile, {io: \"raw\", filename: \"avatar.png\"});",
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
gem "sqlite3", "~> 2.9", ">= 2.9.5"
`);

  writeFile("config/application.rb", `require "rails"
require "active_record/railtie"
require "active_storage/engine"

module HXRubyActiveStorage
  class Application < Rails::Application
    config.load_defaults 7.0
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
    config.active_storage.service = :test
  end
end
`);

  writeFile("config/environment.rb", `require_relative "application"

Rails.application.initialize!
`);

  writeFile("config/database.yml", `test:
  adapter: sqlite3
  database: db/test.sqlite3
`);

  writeFile("config/storage.yml", `test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>
`);

  writeFile("config/routes.rb", `Rails.application.routes.draw do
end
`);

  writeFile("app/models/application_record.rb", `class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
`);

  writeFile("db/migrate/20260101000000_create_profiles.rb", `class CreateProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :profiles do |t|
      t.string :name, null: false
    end
  end
end
`);

  writeFile("test/test_helper.rb", `ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Migration.maintain_test_schema!
`);

  writeFile("test/models/profile_attachment_test.rb", `require "test_helper"
require "digest/md5"
require "stringio"
require Rails.root.join("app/models/profile")

class ProfileAttachmentTest < ActiveSupport::TestCase
  setup do
    FileUtils.rm_rf(Rails.root.join("tmp/storage"))
  end

  test "attaches reads and purges a typed one attachment by signed id" do
    profile = Profile.create!(name: "Ada")
    avatar = blob("avatar.txt", "avatar-body")

    profile.avatar.attach(avatar.signed_id)

    assert profile.avatar.attached?
    assert_equal "avatar.txt", profile.avatar.filename.to_s
    assert_equal "avatar-body", profile.avatar.download

    profile.avatar.purge

    assert_not profile.avatar.attached?
  end

  test "attaches reads and purges typed many attachments by signed ids" do
    profile = Profile.create!(name: "Grace")
    first = blob("one.txt", "one-body")
    second = blob("two.txt", "two-body")

    profile.gallery.attach([first.signed_id, second.signed_id])

    assert profile.gallery.attached?
    assert_equal ["one.txt", "two.txt"], profile.gallery.attachments.map { |attachment| attachment.filename.to_s }
    assert_equal ["one-body", "two-body"], profile.gallery.attachments.map(&:download)

    profile.gallery.purge

    assert_not profile.gallery.attached?
  end

  test "attaches a typed io filename content type hash" do
    profile = Profile.create!(name: "Katherine")

    profile.avatar.attach(
      io: StringIO.new("hash-avatar-body"),
      filename: "hash-avatar.txt",
      content_type: "text/plain"
    )

    assert profile.avatar.attached?
    assert_equal "hash-avatar.txt", profile.avatar.filename.to_s
    assert_equal "text/plain", profile.avatar.content_type
    assert_equal "hash-avatar-body", profile.avatar.download
  end

  test "direct upload blob helpers attach through signed ids" do
    profile = Profile.create!(name: "Dorothy")
    body = "direct-upload-body"
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: "direct.txt",
      byte_size: body.bytesize,
      checksum: Digest::MD5.base64digest(body),
      content_type: "text/plain"
    )

    assert blob.signed_id
    assert_equal "direct.txt", blob.filename.to_s
    assert_equal "text/plain", blob.content_type
    assert_match(/rails\\/active_storage\\/disk/, blob.service_url_for_direct_upload)
    assert_equal({"Content-Type" => "text/plain"}, blob.service_headers_for_direct_upload)

    profile.avatar.attach(blob.signed_id)

    assert profile.avatar.attached?
    assert_equal "direct.txt", profile.avatar.filename.to_s
  end

  test "direct upload file field renders through Rails helpers" do
    profile = Profile.create!(name: "Mary")
    html = ApplicationController.render(partial: "profiles/upload_form", locals: { profile: profile })

    assert_includes html, "type=\\"file\\""
    assert_includes html, "name=\\"profile[avatar]\\""
    assert_includes html, "data-direct-upload-url="
    assert_includes html, "/rails/active_storage/direct_uploads"
  end

  private

  def blob(filename, content)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(content),
      filename: filename,
      content_type: "text/plain"
    )
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
  process.stdout.write(`[active-storage] stage: ${name}\n`);
  return callback();
}

function assertRuntimeRubySupportsRails() {
  const rubyVersion = run("ruby", ["-e", "print RUBY_VERSION"], { allowFailure: true }).stdout.trim();
  if (!rubyAtLeast(rubyVersion, "3.3.0")) {
    console.error(`[active-storage] REQUIRE_RAILS=1 requires Ruby >= 3.3.0 for the supported RailsHx runtime; current ruby is ${rubyVersion || "unknown"}.`);
    console.error("[active-storage] Activate the repo .ruby-version Ruby before running npm run test:rails-runtime.");
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
