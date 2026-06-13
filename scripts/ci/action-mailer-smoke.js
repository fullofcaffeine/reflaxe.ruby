#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "action_mailer");
const invalidSourceDir = join(root, "test", ".generated", "action_mailer_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "action_mailer_invalid_out");
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
  /self\.mail\(to: email__hx\d+, from: "team@example.test", subject: "Welcome to typed RailsHx mail"\) do \|format__hx\d+\|/,
  /format__hx\d+\.html\(\) \{/,
  /render\(template: "mailers\/user_mailer\/welcome", locals: \{message: locals_message__hx\d+, name: locals_name__hx\d+, product_name: locals_product_name__hx\d+\}\)/,
  /format__hx\d+\.text\(\) \{/,
  /render\(template: "mailers\/user_mailer\/welcome.text", locals: \{message: locals_message__hx\d+, name: locals_name__hx\d+, product_name: locals_product_name__hx\d+\}\)/,
]) {
  if (!expected.test(mailerRuby)) {
    console.error(`ActionMailer output missing expected line: ${expected}`);
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
}
