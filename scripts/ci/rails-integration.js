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
const compiledDir = join(root, "test", ".generated", "todoapp_rails");
const appDir = join(root, "test", ".generated", "rails_integration");
const requireRails = process.env.REQUIRE_RAILS === "1" || process.env.CI_REQUIRE_RAILS === "1";
let currentStage = "startup";

stage("compiler", () => run(process.execPath, [join(root, "scripts", "ci", "todoapp-rails-smoke.js")]));
stage("materialization", materializeRailsApp);
stage("ruby syntax", () => syntaxCheck([
  "app/models/application_record.rb",
  "app/haxe_gen/controllers/todo_index_locals.rb",
  "app/haxe_gen/views/todo_index_view.rb",
  "app/haxe_gen/models/todo.rb",
  "app/haxe_gen/models/user.rb",
  "app/haxe_gen/controllers/todos_controller.rb",
  "config/application.rb",
  "config/environment.rb",
  "config/routes.rb",
  "config/initializers/hxruby_autoload.rb",
  "db/migrate/20260101000000_create_todos.rb",
  "db/migrate/20260101000001_update_todos.rb",
  "test/models/todo_test.rb",
  "test/models/user_test.rb",
  "test/controllers/todos_controller_test.rb",
]));
stage("template materialization", () => viewContentCheck("app/views/controllers/todos/index.html.erb", [
  "RailsHx sample",
  "Typed Rails, polished Ruby.",
  'render partial: "controllers/todos/composer"',
  'render partial: "controllers/todos/dashboard"',
  "typed_column_count",
]));
stage("template materialization", () => viewContentCheck("app/views/controllers/todos/_composer.html.erb", [
  "if sample_user != nil",
  'render partial: "controllers/todos/typed_form"',
  "sample_user_id",
]));

const railsProbe = stage("bundle probe", () => run("bundle", ["exec", "ruby", "-e", "require 'rails'; puts Rails.version"], {
  cwd: appDir,
  allowFailure: true,
}));

if (railsProbe.status !== 0) {
  const message = "Rails gems are not available for the generated integration app; skipped runtime Rails test pass.";
  if (requireRails) {
    process.stdout.write("[rails-integration] Rails gems missing; running bundle install because REQUIRE_RAILS=1.\n");
    stage("bundle install", () => run("bundle", ["install"], { cwd: appDir }));
  } else {
    process.stdout.write(`[rails-integration] ${message}\n`);
    process.stdout.write("[rails-integration] Set REQUIRE_RAILS=1 after installing app gems to make this lane mandatory.\n");
    process.exit(0);
  }
}

stage("migration", () => run("bundle", ["exec", "rails", "db:migrate"], {
  cwd: appDir,
  env: { ...process.env, RAILS_ENV: "test" },
}));
stage("request tests", () => run("bundle", ["exec", "rails", "test"], {
  cwd: appDir,
  env: { ...process.env, RAILS_ENV: "test" },
}));

function materializeRailsApp() {
  rmSync(appDir, { force: true, recursive: true });
  copyTree(join(compiledDir, "app"), join(appDir, "app"));
  copyTree(join(compiledDir, "config"), join(appDir, "config"));
  copyTree(join(compiledDir, "db", "migrate"), join(appDir, "db", "migrate"));

  writeFile("Gemfile", `source "https://rubygems.org"

gem "rails", ">= 7.0", "< 8.0"
gem "sqlite3", "~> 1.4"
`);

  writeFile("config/application.rb", `require "rails"
require "active_record/railtie"
require "action_controller/railtie"

module HXRubyTodoapp
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

  writeFile("config/database.yml", `test:
  adapter: sqlite3
  database: db/test.sqlite3
`);

  writeFile("app/models/application_record.rb", `class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
`);

  writeFile("config/routes.rb", `Rails.application.routes.draw do
  resources :todos, controller: "controllers/todos", only: [:index, :create]
end
`);

  writeFile("test/test_helper.rb", `ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Migration.maintain_test_schema!
`);
  copyTree(join(root, "examples", "todoapp_rails", "rails", "test"), join(appDir, "test"));
}

function syntaxCheck(relativeFiles) {
  for (const relativeFile of relativeFiles) {
    run("ruby", ["-c", join(appDir, relativeFile)]);
  }
}

function viewContentCheck(relativeFile, expectedLines) {
  const path = join(appDir, relativeFile);
  if (!existsSync(path)) {
    console.error(`Expected Rails view file missing: ${path}`);
    process.exit(1);
  }
  const content = readFileSync(path, "utf8");
  for (const expected of expectedLines) {
    if (!content.includes(expected)) {
      console.error(`Rails view file missing expected content: ${expected}`);
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
  process.stdout.write(`[rails-integration] stage: ${name}\n`);
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
    process.stderr.write(`[rails-integration] failed during ${currentStage}: ${command} ${args.join(" ")}\n`);
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}
