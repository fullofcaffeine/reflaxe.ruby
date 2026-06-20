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
const outputDir = join(root, "test", ".generated", "action_mailer");
const runtimeAppDir = join(root, "test", ".generated", "action_mailer_runtime");
const invalidSourceDir = join(root, "test", ".generated", "action_mailer_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "action_mailer_invalid_out");
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
    process.stderr.write(`[action-mailer] failed during ${currentStage}: ${command} ${args.join(" ")}\n`);
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

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for ActionMailer smoke.");
  process.exit(1);
}

compileActionMailer(outputDir);

for (const file of [
  "app/haxe_gen/mailers/user_mailer.rb",
  "app/haxe_gen/views/welcome_email_html_view.rb",
  "app/haxe_gen/views/welcome_email_text_view.rb",
  "app/views/mailers/user_mailer/welcome.html.erb",
  "app/views/mailers/user_mailer/welcome.text.erb",
  "test/mailers/previews/user_mailer_preview.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected ActionMailer output file missing: ${fullPath}`);
    process.exit(1);
  }
}

const mailerRuby = readFileSync(join(outputDir, "app", "haxe_gen", "mailers", "user_mailer.rb"), "utf8");
for (const expected of [
  /require "action_mailer\/railtie"/,
  /module Mailers/,
  /class UserMailer < ActionMailer::Base/,
  /def welcome\(email__hx\d+, name__hx\d+, message__hx\d+\)/,
  /self\.attachments\(\)/,
  /self\.attachments\(\)\["welcome\.txt"\] = message__hx\d+/,
  /self\.attachments\(\)\.inline\(\)\["welcome\.csv"\] = \{content: .*name,message\\n.*name__hx\d+.*message__hx\d+.*mime_type: "text\/csv"\}/,
  /self\.mail\(to: email__hx\d+, from: "team@example.test", cc: \["ops@example.test"\], reply_to: "reply@example.test", subject: "Welcome to typed RailsHx mail", layout: false\) do \|format__hx\d+\|/,
  /format__hx\d+\.html\(\) \{/,
  /render\(template: "mailers\/user_mailer\/welcome", locals: \{message: locals_message__hx\d+, name: locals_name__hx\d+, product_name: locals_product_name__hx\d+\}\)/,
  /format__hx\d+\.text\(\) \{/,
  /render\(template: "mailers\/user_mailer\/welcome.text", locals: \{message: locals_message__hx\d+, name: locals_name__hx\d+, product_name: locals_product_name__hx\d+\}\)/,
  /def welcome_from_params\(\)/,
  /email__hx\d+ = params\[:email\]/,
  /name__hx\d+ = params\[:name\]/,
  /message__hx\d+ = params\[:message\]/,
  /subject: "Welcome to typed RailsHx parameterized mail"/,
]) {
  if (!expected.test(mailerRuby)) {
    console.error(`ActionMailer output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "app", "haxe_gen", "main.rb"), "utf8");
if (!/Mailers::UserMailer\.with\(email: "reader@example.test", name: "Ada", message: "Typed parameterized RailsHx mailers are ready\."\)\.welcome_from_params\(\)\.deliver_later\(\)/.test(mainRuby)) {
  console.error("ActionMailer main output missing typed parameterized .with(...).deliver_later call.");
  process.exit(1);
}

const previewRuby = readFileSync(join(outputDir, "test", "mailers", "previews", "user_mailer_preview.rb"), "utf8");
for (const expected of [
  /class UserMailerPreview < ActionMailer::Preview/,
  /def welcome\(\)/,
  /Mailers::UserMailer\.with\(email: "preview@example.test", name: "Preview Ada", message: "Previewed through typed RailsHx params\."\)\.welcome_from_params\(\)/,
]) {
  if (!expected.test(previewRuby)) {
    console.error(`ActionMailer preview output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const htmlErb = readFileSync(join(outputDir, "app", "views", "mailers", "user_mailer", "welcome.html.erb"), "utf8");
for (const expected of [
  '<section class="email-shell">',
  "<%= name %>",
  "<%= product_name %>",
  "<%= message %>",
]) {
  if (!htmlErb.includes(expected)) {
    console.error(`ActionMailer HTML template missing expected output: ${expected}`);
    process.exit(1);
  }
}

const textErb = readFileSync(join(outputDir, "app", "views", "mailers", "user_mailer", "welcome.text.erb"), "utf8");
for (const expected of ["Hello <%= name %>", "<%= product_name %> mailers are typed.", "<%= message %>"]) {
  if (!textErb.includes(expected)) {
    console.error(`ActionMailer text template missing expected output: ${expected}`);
    process.exit(1);
  }
}

for (const file of [
  "app/haxe_gen/mailers/user_mailer.rb",
  "app/haxe_gen/views/welcome_email_html_view.rb",
  "app/haxe_gen/views/welcome_email_text_view.rb",
  "test/mailers/previews/user_mailer_preview.rb",
  "app/haxe_gen/main.rb",
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
const invalid = compileActionMailer(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidMain",
  allowFailure: true,
});
if (invalid.status === 0) {
  console.error("Expected invalid ActionMailer locals compile to fail.");
  process.exit(1);
}
if (!/locals do not match the Template<TLocals> contract|has no field message|has no field productName/.test(invalid.stderr + invalid.stdout)) {
  process.stdout.write(invalid.stdout);
  process.stderr.write(invalid.stderr);
  console.error("Invalid ActionMailer locals compile failed for an unexpected reason.");
  process.exit(1);
}

const invalidOptions = compileActionMailer(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidMailOptionsMain",
  allowFailure: true,
});
if (invalidOptions.status === 0) {
  console.error("Expected invalid ActionMailer mail options compile to fail.");
  process.exit(1);
}
if (!/MailAddress|Cannot unify|should be rails\.action_mailer\.MailAddress/.test(invalidOptions.stderr + invalidOptions.stdout)) {
  process.stdout.write(invalidOptions.stdout);
  process.stderr.write(invalidOptions.stderr);
  console.error("Invalid ActionMailer mail options compile failed for an unexpected reason.");
  process.exit(1);
}

const invalidAttachment = compileActionMailer(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidAttachmentMain",
  allowFailure: true,
});
if (invalidAttachment.status === 0) {
  console.error("Expected invalid ActionMailer attachment compile to fail.");
  process.exit(1);
}
if (!/String|Cannot unify/.test(invalidAttachment.stderr + invalidAttachment.stdout)) {
  process.stdout.write(invalidAttachment.stdout);
  process.stderr.write(invalidAttachment.stderr);
  console.error("Invalid ActionMailer attachment compile failed for an unexpected reason.");
  process.exit(1);
}

const invalidParams = compileActionMailer(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidMailerParamsMain",
  allowFailure: true,
});
if (invalidParams.status === 0) {
  console.error("Expected invalid ActionMailer parameterized params compile to fail.");
  process.exit(1);
}
if (!/WelcomeMailerParams|has no field message|requires field message|String|Cannot unify/.test(invalidParams.stderr + invalidParams.stdout)) {
  process.stdout.write(invalidParams.stdout);
  process.stderr.write(invalidParams.stderr);
  console.error("Invalid ActionMailer parameterized params compile failed for an unexpected reason.");
  process.exit(1);
}

stage("runtime materialization", materializeRuntimeRailsApp);
stage("runtime ruby syntax", () => syntaxCheck([
  "app/haxe_gen/mailers/user_mailer.rb",
  "app/haxe_gen/views/welcome_email_html_view.rb",
  "app/haxe_gen/views/welcome_email_text_view.rb",
  "config/application.rb",
  "config/environment.rb",
  "test/mailers/user_mailer_test.rb",
  "test/mailers/previews/user_mailer_preview.rb",
]));

const bundleProbe = stage("runtime bundle probe", () => run("bundle", ["check"], {
  cwd: runtimeAppDir,
  allowFailure: true,
}));
if (bundleProbe.status !== 0) {
  if (requireRails) {
    assertRuntimeRubySupportsRails();
    process.stdout.write("[action-mailer] Rails bundle missing; running bundle install because REQUIRE_RAILS=1.\n");
    stage("runtime bundle install", () => run("bundle", ["install"], { cwd: runtimeAppDir }));
  } else {
    process.stdout.write("[action-mailer] Rails bundle is not available for the generated ActionMailer app; skipped runtime Rails test pass.\n");
    process.stdout.write("[action-mailer] Set REQUIRE_RAILS=1 to install app gems and make this lane mandatory.\n");
    process.exit(0);
  }
}

stage("runtime mailer tests", () => run("bundle", ["exec", "rails", "test"], {
  cwd: runtimeAppDir,
  env: { ...process.env, RAILS_ENV: "test" },
}));

function compileActionMailer(targetDir, options = {}) {
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
    options.classPath ?? join(root, "examples", "action_mailer"),
    "-cp",
    join(root, "examples", "action_mailer"),
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "--macro",
    'include("previews")',
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
      "import mailers.UserMailer;",
      "import rails.action_view.Template;",
      "import rails.macros.MailerMacro;",
      "import views.WelcomeEmailHtmlView;",
      "import views.WelcomeEmailView.WelcomeEmailLocals;",
      "",
      "class InvalidMain {",
      "\tstatic function main():Void {",
      "\t\tMailerMacro.mailHtml(new UserMailer(), {to: \"reader@example.test\", subject: \"Broken\"},",
      "\t\t\t(Template.of(WelcomeEmailHtmlView) : Template<WelcomeEmailLocals>), {name: \"Ada\"});",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
  writeFileSync(
    join(invalidSourceDir, "InvalidMailOptionsMain.hx"),
    [
      "import mailers.UserMailer;",
      "import rails.action_view.Template;",
      "import rails.macros.MailerMacro;",
      "import views.WelcomeEmailHtmlView;",
      "import views.WelcomeEmailView.WelcomeEmailLocals;",
      "",
      "class InvalidMailOptionsMain {",
      "\tstatic function main():Void {",
      "\t\tvar locals:WelcomeEmailLocals = {name: \"Ada\", message: \"Hi\", productName: \"RailsHx\"};",
      "\t\tMailerMacro.mailHtml(new UserMailer(), {to: {address: \"reader@example.test\"}, subject: \"Broken\"},",
      "\t\t\t(Template.of(WelcomeEmailHtmlView) : Template<WelcomeEmailLocals>), locals);",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
  writeFileSync(
    join(invalidSourceDir, "InvalidAttachmentMain.hx"),
    [
      "import mailers.UserMailer;",
      "",
      "class InvalidAttachmentMain {",
      "\tstatic function main():Void {",
      "\t\tvar mailer = new UserMailer();",
      "\t\tmailer.attachments().add(\"bad.txt\", {raw: \"bad\"});",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
  writeFileSync(
    join(invalidSourceDir, "InvalidMailerParamsMain.hx"),
    [
      "import mailers.UserMailer;",
      "",
      "class InvalidMailerParamsMain {",
      "\tstatic function main():Void {",
      "\t\tUserMailer.withParams({email: \"reader@example.test\", name: \"Ada\"}).welcomeFromParams();",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
}

function materializeRuntimeRailsApp() {
  mkdirSync(runtimeAppDir, { recursive: true });
  copyTree(join(outputDir, "app"), join(runtimeAppDir, "app"));
  copyTree(join(outputDir, "config"), join(runtimeAppDir, "config"));
  copyTree(join(outputDir, "test", "mailers", "previews"), join(runtimeAppDir, "test", "mailers", "previews"));
  copyGeneratedSupportIntoHaxeGen();

  writeFile("Gemfile", `source "https://rubygems.org"

gem "rails", "7.2.3.1"
`);

  writeFile("config/application.rb", `require "rails"
require "action_mailer/railtie"

module HXRubyActionMailer
  class Application < Rails::Application
    config.load_defaults 7.0
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
    config.action_mailer.delivery_method = :test
    config.action_mailer.perform_deliveries = true
  end
end
`);

  writeFile("config/environment.rb", `require_relative "application"

Rails.application.initialize!
`);

  writeFile("test/test_helper.rb", `ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
`);

  writeFile("test/mailers/user_mailer_test.rb", `require "test_helper"
require Rails.root.join("app/haxe_gen/mailers/user_mailer")
require Rails.root.join("test/mailers/previews/user_mailer_preview")

class UserMailerTest < ActiveSupport::TestCase
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "builds typed multipart mail with headers and attachment" do
    mail = Mailers::UserMailer.welcome("reader@example.test", "Ada", "Typed RailsHx mailers are ready.")

    assert_equal "Welcome to typed RailsHx mail", mail.subject
    assert_equal ["reader@example.test"], mail.to
    assert_equal ["team@example.test"], mail.from
    assert_equal ["ops@example.test"], mail.cc
    assert_equal ["reply@example.test"], mail.reply_to
    assert mail.multipart?
    assert_includes mail.html_part.body.decoded, "Hello Ada"
    assert_includes mail.html_part.body.decoded, "RailsHx mailers are typed."
    assert_includes mail.html_part.body.decoded, "Typed RailsHx mailers are ready."
    assert_includes mail.text_part.body.decoded, "Hello Ada"
    assert_includes mail.text_part.body.decoded, "RailsHx mailers are typed."
    assert_includes mail.text_part.body.decoded, "Typed RailsHx mailers are ready."

    attachment = mail.attachments["welcome.txt"]
    assert attachment
    assert_equal "Typed RailsHx mailers are ready.", attachment.body.decoded

    inline_attachment = mail.attachments["welcome.csv"]
    assert inline_attachment
    assert_equal "inline", inline_attachment.content_disposition
    assert_equal "text/csv", inline_attachment.mime_type
    assert_includes inline_attachment.body.decoded, "Ada,Typed RailsHx mailers are ready."
  end

  test "deliver_now uses the Rails test delivery collection" do
    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      Mailers::UserMailer.welcome("reader@example.test", "Ada", "Typed RailsHx mailers are ready.").deliver_now
    end

    delivered = ActionMailer::Base.deliveries.last
    assert_equal "Welcome to typed RailsHx mail", delivered.subject
    assert_equal ["reader@example.test"], delivered.to
  end

  test "builds typed parameterized mail through ActionMailer with params" do
    mail = Mailers::UserMailer.with(
      email: "reader@example.test",
      name: "Ada",
      message: "Typed RailsHx parameterized mailers are ready."
    ).welcome_from_params

    assert_equal "Welcome to typed RailsHx parameterized mail", mail.subject
    assert_equal ["reader@example.test"], mail.to
    assert_includes mail.html_part.body.decoded, "Hello Ada"
    assert_includes mail.html_part.body.decoded, "Typed RailsHx parameterized mailers are ready."
    assert_includes mail.text_part.body.decoded, "Typed RailsHx parameterized mailers are ready."
    assert_equal "Typed RailsHx parameterized mailers are ready.", mail.attachments["welcome.txt"].body.decoded
    assert_equal "text/csv", mail.attachments["welcome.csv"].mime_type
  end

  test "loads typed ActionMailer preview artifact" do
    mail = UserMailerPreview.new.welcome

    assert_equal "Welcome to typed RailsHx parameterized mail", mail.subject
    assert_equal ["preview@example.test"], mail.to
    assert_includes mail.html_part.body.decoded, "Previewed through typed RailsHx params."
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
  process.stdout.write(`[action-mailer] stage: ${name}\n`);
  return callback();
}

function assertRuntimeRubySupportsRails() {
  const rubyVersion = run("ruby", ["-e", "print RUBY_VERSION"], { allowFailure: true }).stdout.trim();
  if (!rubyAtLeast(rubyVersion, "3.1.0")) {
    console.error(`[action-mailer] REQUIRE_RAILS=1 requires Ruby >= 3.1.0 for Rails 7.2.3.1; current ruby is ${rubyVersion || "unknown"}.`);
    console.error("[action-mailer] Activate the repo .ruby-version Ruby before running npm run test:rails-runtime.");
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
