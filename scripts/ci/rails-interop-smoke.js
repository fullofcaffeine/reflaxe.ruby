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
const exampleDir = join(root, "examples", "rails_interop_app");
const compiledDir = join(root, "test", ".generated", "rails_interop_compiled");
const appDir = join(root, "test", ".generated", "rails_interop");
const invalidSourceDir = join(root, "test", ".generated", "rails_interop_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "rails_interop_invalid_out");
const requireRails = process.env.REQUIRE_RAILS === "1" || process.env.CI_REQUIRE_RAILS === "1";
let currentStage = "startup";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(compiledDir, { force: true, recursive: true });
rmSync(appDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });

stage("compiler", () => compileWithFirstAvailableReflaxe(exampleDir, compiledDir, "Main"));
stage("compiler artifacts", assertCompiledArtifacts);
stage("typed external template validation", expectInvalidExternalTemplateLocalsFailure);
stage("missing existing template validation", expectMissingExistingTemplateFailure);
stage("materialization", materializeRailsApp);
stage("ruby syntax", () => syntaxCheck([
  "app/controllers/application_controller.rb",
  "app/controllers/legacy_controller.rb",
  "app/controllers/mixed_controller.rb",
  "app/lib/railshx/generated/services/typed_stats.rb",
  "app/services/legacy_price_formatter.rb",
  "config/application.rb",
  "config/environment.rb",
  "config/routes.rb",
  "test/controllers/interop_test.rb",
]));
stage("legacy fixture materialization", () => viewContentCheck("app/views/legacy/home.html.erb", [
  "Legacy ERB, typed Haxe inside.",
  'render partial: "typed_widgets/summary"',
  "Services::TypedStats.confidence_label",
  "Services::TypedStats.summary",
]));

const bundleProbe = stage("bundle probe", () => run("bundle", ["check"], { cwd: appDir, allowFailure: true }));
if (bundleProbe.status !== 0) {
  const message = "Rails bundle is not available for the mixed interop app; skipped runtime Rails test pass.";
  if (requireRails) {
    process.stdout.write("[rails-interop] Rails bundle missing; running bundle install because REQUIRE_RAILS=1.\n");
    stage("bundle install", () => run("bundle", ["install"], { cwd: appDir }));
  } else {
    process.stdout.write(`[rails-interop] ${message}\n`);
    process.stdout.write("[rails-interop] Set REQUIRE_RAILS=1 after installing app gems to make this lane mandatory.\n");
    process.exit(0);
  }
}

stage("request tests", () => run("bundle", ["exec", "rails", "test"], {
  cwd: appDir,
  env: { ...process.env, RAILS_ENV: "test" },
}));

function assertCompiledArtifacts() {
  // Generated RailsHx-owned output shape is covered by committed snapshots.
  // This smoke keeps the interop-specific checks: required generated files and
  // proof that Template.external does not emit or overwrite Rails-owned ERB.
  for (const file of [
    "app/controllers/mixed_controller.rb",
    "app/lib/railshx/generated/services/typed_stats.rb",
    "app/lib/railshx/runtime/hxruby/core.rb",
    "app/views/layouts/application.html.erb",
    "app/views/mixed/haxe_shell.html.erb",
    "app/views/typed_widgets/_summary.html.erb",
  ]) {
    if (!existsSync(join(compiledDir, file))) {
      console.error(`Expected Rails interop output file missing: ${file}`);
      process.exit(1);
    }
  }

  if (existsSync(join(compiledDir, "app", "views", "legacy", "_badge.html.erb"))) {
    console.error("Template.external must not emit or overwrite the external legacy ERB partial.");
    process.exit(1);
  }
}

function expectInvalidExternalTemplateLocalsFailure() {
  mkdirSync(join(invalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(invalidSourceDir, "InvalidInteropMain.hx"), [
    "import views.BadLegacyPartialUse;",
    "",
    "class InvalidInteropMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<BadLegacyPartialUse> = BadLegacyPartialUse;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "views", "BadLegacyPartialUse.hx"), [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Template;",
    "import views.HaxeShellView.LegacyBadgeLocals;",
    "",
    "@:railsTemplate(\"mixed/bad_external_partial\")",
    "@:railsTemplateAst(\"render\")",
    "class BadLegacyPartialUse {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.partial((Template.external(\"legacy/badge\") : Template<LegacyBadgeLocals>), {label: \"missing tone\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));

  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${invalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      invalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "InvalidInteropMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Invalid Template.external locals compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("LegacyBadgeLocals") && !output.includes("tone") && !output.includes("Object requires field tone")) {
      console.error("Invalid Template.external locals failed, but not with the expected typed locals error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  console.error("Unable to run invalid Template.external locals check; no Reflaxe candidate found.");
  process.exit(1);
}

function expectMissingExistingTemplateFailure() {
  mkdirSync(join(invalidSourceDir, "views"), { recursive: true });
  writeFileSync(join(invalidSourceDir, "MissingExistingTemplateMain.hx"), [
    "import views.MissingExistingPartialUse;",
    "",
    "class MissingExistingTemplateMain {",
    "\tstatic function main() {",
    "\t\tvar view:Class<MissingExistingPartialUse> = MissingExistingPartialUse;",
    "\t\tSys.println(view != null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "views", "MissingExistingPartialUse.hx"), [
    "package views;",
    "",
    "import rails.action_view.H;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Template;",
    "import views.HaxeShellView.LegacyBadgeLocals;",
    "",
    "@:railsTemplate(\"mixed/missing_existing_partial\")",
    "@:railsTemplateAst(\"render\")",
    "class MissingExistingPartialUse {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn H.partial((Template.existing(\"legacy/does_not_exist\") : Template<LegacyBadgeLocals>), {label: \"Missing\", tone: \"warm\"});",
    "\t}",
    "}",
    "",
  ].join("\n"));

  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${invalidOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      invalidSourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "MissingExistingTemplateMain",
    ], { allowFailure: true });
    if (result.status === 0) {
      console.error("Missing Template.existing file compiled successfully.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("Template.existing could not find a Rails ERB template")) {
      console.error("Missing Template.existing file failed, but not with the expected filesystem error.");
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(1);
    }
    return;
  }
  console.error("Unable to run missing Template.existing file check; no Reflaxe candidate found.");
  process.exit(1);
}

function materializeRailsApp() {
  copyTree(join(compiledDir, "app"), join(appDir, "app"));
  copyTree(join(exampleDir, "rails", "app"), join(appDir, "app"));

  writeFile("Gemfile", `source "https://rubygems.org"

gem "rails", ">= 7.0"
gem "sqlite3", "~> 2.9", ">= 2.9.5"
gem "propshaft", ">= 0.9"
`);

  writeFile("config.ru", `require_relative "config/environment"

run Rails.application
Rails.application.load_server
`);

  writeFile("Rakefile", `require_relative "config/application"

Rails.application.load_tasks
`);

  writeFile("config/boot.rb", `ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"
`);

  writeFile("config/application.rb", `require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "propshaft"

module HXRubyInterop
  class Application < Rails::Application
    config.load_defaults 7.0
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
    config.autoload_paths << Rails.root.join("app/lib/railshx/generated")
    config.eager_load_paths << Rails.root.join("app/lib/railshx/generated")
    config.assets.paths << Rails.root.join("app/assets/stylesheets")
    config.action_controller.allow_forgery_protection = false
  end
end
`);

  writeFile("config/environment.rb", `require_relative "application"

Rails.application.initialize!
`);

  writeFile("config/routes.rb", `Rails.application.routes.draw do
  root "mixed#haxe_shell"
  get "/haxe-shell", to: "mixed#haxe_shell"
  get "/legacy-shell", to: "legacy#home"
end
`);

  writeFile("app/controllers/application_controller.rb", `class ApplicationController < ActionController::Base
end
`);

  writeFile("test/test_helper.rb", `ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
`);

  writeFile("test/controllers/interop_test.rb", `require "test_helper"

class InteropTest < ActionDispatch::IntegrationTest
  test "haxe shell renders legacy ruby and erb boundaries" do
    get "/haxe-shell"

    assert_response :success
    assert_includes @response.body, "Haxe shell, legacy Rails parts."
    assert_includes @response.body, "POC priced by legacy Ruby at $12.99"
    assert_includes @response.body, "Legacy ERB partial"
    assert_includes @response.body, "HHX island rendered from Haxe"
  end

  test "legacy erb shell consumes generated haxe service and partial" do
    get "/legacy-shell"

    assert_response :success
    assert_includes @response.body, "Legacy ERB, typed Haxe inside."
    assert_includes @response.body, "HHX island rendered from ERB"
    assert_includes @response.body, "Ruby called a generated Haxe service with no adapter."
    assert_includes @response.body, "Typed Haxe summarized 2 Rails surfaces."
  end
end
`);
}

function compileWithFirstAvailableReflaxe(sourceDir, outputDir, mainClass) {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${outputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      sourceDir,
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      mainClass,
    ], { allowFailure: true });
    if (result.status === 0) {
      return result;
    }
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
  }
  console.error("Unable to compile rails_interop_app through Reflaxe.");
  process.exit(1);
}

function syntaxCheck(relativeFiles) {
  for (const relativeFile of relativeFiles) {
    run("ruby", ["-c", join(appDir, relativeFile)]);
  }
}

function viewContentCheck(relativeFile, expectedLines) {
  const path = join(appDir, relativeFile);
  if (!existsSync(path)) {
    console.error(`Expected Rails interop view file missing: ${path}`);
    process.exit(1);
  }
  const content = readFileSync(path, "utf8");
  for (const expected of expectedLines) {
    if (!content.includes(expected)) {
      console.error(`Rails interop view file missing expected content: ${expected}`);
      process.exit(1);
    }
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
  const fullPath = join(appDir, relativePath);
  mkdirSync(dirname(fullPath), { recursive: true });
  writeFileSync(fullPath, content);
}

function stage(name, callback) {
  currentStage = name;
  process.stdout.write(`[rails-interop] stage: ${name}\n`);
  return callback();
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stderr.write(`[rails-interop] failed during ${currentStage}: ${command} ${args.join(" ")}\n`);
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}
