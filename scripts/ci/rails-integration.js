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

run(process.execPath, [join(root, "scripts", "ci", "todoapp-rails-smoke.js")]);
materializeRailsApp();
syntaxCheck([
  "app/models/application_record.rb",
  "app/haxe_gen/models/todo.rb",
  "app/haxe_gen/models/user.rb",
  "app/haxe_gen/controllers/todos_controller.rb",
  "config/application.rb",
  "config/environment.rb",
  "config/routes.rb",
  "config/initializers/hxruby_autoload.rb",
  "db/migrate/20260101000000_create_todos.rb",
  "test/models/todo_test.rb",
  "test/controllers/todos_controller_test.rb",
]);
viewContentCheck("app/views/controllers/todos/index.html.erb", [
  "Typed Rails, polished Ruby.",
  "RailsHx sample",
  "form_with",
  "Models::Todo.__hx_rails_schema",
]);

const railsProbe = run("bundle", ["exec", "ruby", "-e", "require 'rails'; puts Rails.version"], {
  cwd: appDir,
  allowFailure: true,
});

if (railsProbe.status !== 0) {
  const message = "Rails gems are not available for the generated integration app; skipped runtime Rails test pass.";
  if (requireRails) {
    process.stderr.write(`${message}\n`);
    process.stderr.write(railsProbe.stderr);
    process.exit(1);
  }
  process.stdout.write(`[rails-integration] ${message}\n`);
  process.stdout.write("[rails-integration] Set REQUIRE_RAILS=1 after installing app gems to make this lane mandatory.\n");
  process.exit(0);
}

run("bundle", ["exec", "rails", "db:migrate"], {
  cwd: appDir,
  env: { ...process.env, RAILS_ENV: "test" },
});
run("bundle", ["exec", "rails", "test"], {
  cwd: appDir,
  env: { ...process.env, RAILS_ENV: "test" },
});

function materializeRailsApp() {
  rmSync(appDir, { force: true, recursive: true });
  copyTree(join(compiledDir, "app"), join(appDir, "app"));
  copyTree(join(root, "examples", "todoapp_rails", "app", "views"), join(appDir, "app", "views"));
  copyTree(join(compiledDir, "config"), join(appDir, "config"));
  mkdirSync(join(appDir, "db", "migrate"), { recursive: true });
  copyFileSync(
    join(root, "examples", "todoapp_rails", "db", "migrate", "20260101000000_create_todos.rb"),
    join(appDir, "db", "migrate", "20260101000000_create_todos.rb")
  );

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

  writeFile("test/models/todo_test.rb", `require "test_helper"

class TodoTest < ActiveSupport::TestCase
  test "incomplete returns incomplete todos" do
    user = Models::User.create!(name: "owner")
    Models::Todo.create!(title: "ship ruby", is_completed: false, user: user)
    Models::Todo.create!(title: "done", is_completed: true, user: user)

    assert_equal ["ship ruby"], Models::Todo.incomplete.map(&:title)
  end
end
`);

  writeFile("test/controllers/todos_controller_test.rb", `require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  test "index renders the polished RailsHx todo page" do
    user = Models::User.create!(name: "owner")
    Models::Todo.create!(title: "ship rails", is_completed: false, user: user)

    get "/todos"

    assert_response :success
    assert_includes @response.body, "Typed Rails, polished Ruby."
    assert_includes @response.body, "RailsHx sample"
    assert_includes @response.body, "ship rails"
    assert_includes @response.body, "typed columns"
  end

  test "create permits haxe-authored params and redirects through route helper" do
    user = Models::User.create!(name: "owner")

    post "/todos", params: { todo: { title: "from params", is_completed: false, user_id: user.id, ignored: "nope" } }

    assert_redirected_to "/todos"
    assert_equal "from params", Models::Todo.order(:id).last.title
  end
end
`);
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

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
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
