#!/usr/bin/env node

const {
  copyFileSync,
  chmodSync,
  existsSync,
  mkdirSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} = require("node:fs");
const { dirname, join, relative, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const compiledDir = join(root, "test", ".generated", "todoapp_rails");
const compiledClientDir = join(root, "test", ".generated", "todoapp_rails_client");
const appDir = join(root, "test", ".generated", "rails_integration");
const releaseArchive = join(root, "test", ".generated", "rails_integration_release.tgz");
const exampleDir = join(root, "examples", "todoapp_rails");
const port = process.env.PORT ?? "3000";
const bind = process.env.BIND ?? "127.0.0.1";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

const command = process.argv[2] ?? "help";

switch (command) {
  case "compile":
    compileAndMaterialize();
    break;
  case "prepare":
    compileAndMaterialize();
    bundleInstall();
    rails(["db:prepare"]);
    rails(["db:seed"]);
    printReady();
    break;
  case "server":
    ensureApp();
    runStreaming("bundle", ["exec", "ruby", "bin/rails", "server", "-b", bind, "-p", port], { cwd: appDir });
    break;
  case "watch":
    watch();
    break;
  case "test":
    compileAndMaterialize();
    bundleInstall();
    rails(["db:prepare"], { env: { ...process.env, RAILS_ENV: "test" } });
    rails(["test"], { env: { ...process.env, RAILS_ENV: "test" } });
    break;
  case "production-smoke":
    productionSmoke();
    break;
  case "help":
  case "--help":
  case "-h":
    usage();
    break;
  default:
    console.error(`Unknown todoapp command: ${command}`);
    usage();
    process.exit(1);
}

function compileAndMaterialize() {
  compileHaxe();
  compileClientHaxe();
  materializeRailsApp();
  console.log(`[todoapp] Rails app materialized at ${relative(root, appDir)}`);
}

function compileHaxe() {
  rmSync(compiledDir, { force: true, recursive: true });
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }

    const result = run("haxe", [
      "-D",
      `ruby_output=${compiledDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      exampleDir,
      "-cp",
      join(exampleDir, "src_haxe"),
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "Main",
    ], { allowFailure: true });

    if (result.status === 0) {
      console.log(`[todoapp] Haxe compiled with ${relative(root, reflaxeSrc)}`);
      return;
    }

    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
  }

  console.error("Unable to compile todoapp_rails through Reflaxe.");
  process.exit(1);
}

function compileClientHaxe() {
  rmSync(compiledClientDir, { force: true, recursive: true });
  mkdirSync(compiledClientDir, { recursive: true });
  run("haxe", [join(exampleDir, "build-client.hxml")]);
  console.log("[todoapp] Haxe client JS compiled.");
}

function materializeRailsApp() {
  for (const path of [
    join(appDir, "app", "haxe_gen"),
    join(appDir, "app", "assets", "stylesheets"),
    join(appDir, "app", "javascript"),
    join(appDir, "app", "views", "controllers", "todos"),
    join(appDir, "config", "initializers", "hxruby_autoload.rb"),
  ]) {
    rmSync(path, { force: true, recursive: true });
  }

  copyTree(join(compiledDir, "app"), join(appDir, "app"));
  copyTree(join(compiledDir, "config"), join(appDir, "config"));

  copyTree(join(compiledDir, "db", "migrate"), join(appDir, "db", "migrate"));

  writeFile("Gemfile", `source "https://rubygems.org"

gem "rails", ">= 7.0", "< 8.0"
gem "sqlite3", "~> 1.4"
gem "puma", ">= 5.0"
gem "propshaft", ">= 0.9"
gem "importmap-rails", ">= 2.0"
gem "turbo-rails", ">= 2.0"
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
require "active_record/railtie"
require "action_dispatch/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "propshaft"
require "importmap-rails"
require "turbo-rails"

module HXRubyTodoapp
  class Application < Rails::Application
    config.load_defaults 7.0
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
    config.paths.add "app/haxe_gen", eager_load: true
    config.assets.paths << Rails.root.join("app/javascript")
    config.action_controller.allow_forgery_protection = false
  end
end
`);

  writeFile("config/initializers/hxruby_autoload.rb", `# Generated by reflaxe.ruby.
hxruby_root = Rails.root.join("app/haxe_gen")
hxruby_runtime_root = hxruby_root.join("hxruby")
Rails.autoloaders.main.ignore(hxruby_runtime_root) if defined?(Rails.autoloaders) && hxruby_runtime_root.exist?
Dir[hxruby_runtime_root.join("*.rb")].sort.each { |path| require path }
`);

  writeFile("config/environment.rb", `require_relative "application"

Rails.application.initialize!
`);

  writeFile("bin/rails", `#!/usr/bin/env ruby
APP_PATH = File.expand_path("../config/application", __dir__)
require_relative "../config/boot"
require "rails/commands"
`);
  chmodSync(join(appDir, "bin", "rails"), 0o755);

  writeFile("config/database.yml", `development:
  adapter: sqlite3
  database: db/development.sqlite3

test:
  adapter: sqlite3
  database: db/test.sqlite3

production:
  adapter: sqlite3
  database: db/production.sqlite3
`);

  writeFile("config/environments/production.rb", `Rails.application.configure do
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = true
  config.assets.compile = false
  config.active_support.report_deprecations = false
end
`);

  writeFile("config/routes.rb", `Rails.application.routes.draw do
  root "controllers/todos#index"
  resources :todos, controller: "controllers/todos", only: [:index, :create]
end
`);

  writeFile("config/importmap.rb", `pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "railshx/todo_client", to: "railshx/todo_client.js"
`);

  copyFileSync(
    join(exampleDir, "assets", "stylesheets", "application.css"),
    writeTargetPath("app/assets/stylesheets/application.css")
  );
  writeFile("app/javascript/application.js", `import "@hotwired/turbo-rails"
import "railshx/todo_client"
`);
  copyFileSync(
    join(compiledClientDir, "_todo_client_tmp.js"),
    writeTargetPath("app/javascript/railshx/todo_client.js")
  );
  if (existsSync(join(compiledClientDir, "_todo_client_tmp.js.map"))) {
    copyFileSync(
      join(compiledClientDir, "_todo_client_tmp.js.map"),
      writeTargetPath("app/javascript/railshx/todo_client.js.map")
    );
  }

  writeFile("db/seeds.rb", `owner = Models::User.find_or_create_by!(name: "RailsHx Owner")

Models::Todo.find_or_create_by!(title: "Ship typed Rails templates", user: owner) do |todo|
  todo.notes = "HHX stays typed in Haxe; ERB is generated for Rails."
  todo.is_completed = false
end

Models::Todo.find_or_create_by!(title: "Wire the Rails dev loop", user: owner) do |todo|
  todo.notes = "Compile Haxe, run Rails, keep the watcher nearby."
  todo.is_completed = false
end
`);

  writeFile("app/models/application_record.rb", `class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
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

function ensureApp() {
  if (!existsSync(join(appDir, "Gemfile")) || !existsSync(join(appDir, "config", "environment.rb"))) {
    console.log("[todoapp] Generated Rails app missing; running prepare first.");
    compileAndMaterialize();
    bundleInstall();
    rails(["db:prepare"]);
    rails(["db:seed"]);
  }
}

function bundleInstall() {
  const check = run("bundle", ["check"], { cwd: appDir, allowFailure: true });
  if (check.status === 0) {
    console.log("[todoapp] Bundle is ready.");
    return;
  }
  runStreaming("bundle", ["install"], { cwd: appDir });
}

function rails(args, options = {}) {
  runStreaming("bundle", ["exec", "ruby", "bin/rails", ...args], {
    cwd: appDir,
    env: options.env ?? process.env,
  });
}

function productionSmoke() {
  ensureSupportedRuby();
  compileAndMaterialize();
  bundleInstall();
  rails(["db:prepare"], { env: { ...process.env, RAILS_ENV: "test" } });
  rails(["test"], { env: { ...process.env, RAILS_ENV: "test" } });
  rails(["zeitwerk:check"], { env: { ...process.env, RAILS_ENV: "production", SECRET_KEY_BASE_DUMMY: "1" } });
  rails(["assets:precompile"], { env: { ...process.env, RAILS_ENV: "production", SECRET_KEY_BASE_DUMMY: "1" } });
  buildReleaseArchive();
  assertReleaseArchive();
  console.log(`[todoapp] Production smoke passed; release archive: ${relative(root, releaseArchive)}`);
}

function watch() {
  compileAndMaterialize();
  console.log("[todoapp] Watching Haxe/RailsHx sources. Run `npm run todoapp:server` in another terminal.");

  let lastSnapshot = snapshot();
  let compiling = false;
  setInterval(() => {
    const nextSnapshot = snapshot();
    if (nextSnapshot === lastSnapshot || compiling) {
      return;
    }
    lastSnapshot = nextSnapshot;
    compiling = true;
    console.log("[todoapp] Change detected; recompiling Haxe and refreshing generated Rails files.");
    try {
      compileAndMaterialize();
    } catch (error) {
      console.error(error.stack ?? error.message ?? String(error));
    } finally {
      compiling = false;
    }
  }, Number(process.env.HXRUBY_WATCH_INTERVAL ?? "1000"));
}

function snapshot() {
  const roots = [
    join(root, "src"),
    join(root, "std"),
    exampleDir,
  ];
  const entries = [];
  for (const sourceRoot of roots) {
    collectSnapshot(sourceRoot, entries);
  }
  return entries.sort().join("\n");
}

function collectSnapshot(path, entries) {
  if (!existsSync(path)) {
    return;
  }
  const stat = statSync(path);
  if (stat.isDirectory()) {
    for (const entry of readdirSync(path)) {
      if (entry === ".git" || entry === "node_modules" || entry === ".generated") {
        continue;
      }
      collectSnapshot(join(path, entry), entries);
    }
    return;
  }
  if (!/\.(css|hx|hxml|rb|json|md)$/.test(path)) {
    return;
  }
  entries.push(`${relative(root, path)}:${stat.mtimeMs}:${stat.size}`);
}

function ensureSupportedRuby() {
  const result = run("ruby", ["-e", "print RUBY_VERSION"], { allowFailure: true });
  if (result.status !== 0) {
    process.stderr.write(result.stderr);
    console.error("[todoapp] Ruby must be available on PATH.");
    process.exit(result.status ?? 1);
  }
  const version = result.stdout.trim();
  const [major, minor] = version.split(".").map((part) => Number(part));
  if (Number.isNaN(major) || Number.isNaN(minor) || major < 3 || (major === 3 && minor < 2)) {
    console.error(`[todoapp] Production smoke requires Ruby >= 3.2; current Ruby is ${version}.`);
    process.exit(1);
  }
}

function buildReleaseArchive() {
  rmSync(releaseArchive, { force: true });
  runStreaming("tar", ["-czf", releaseArchive, "-C", appDir, "."]);
}

function assertReleaseArchive() {
  const list = run("tar", ["-tzf", releaseArchive]).stdout.split("\n").filter(Boolean);
  for (const expected of [
    "./app/haxe_gen/models/todo.rb",
    "./app/haxe_gen/controllers/todos_controller.rb",
    "./app/views/controllers/todos/index.html.erb",
    "./app/views/layouts/application.html.erb",
    "./app/javascript/railshx/todo_client.js",
    "./db/migrate/20260101000000_create_todos.rb",
    "./config/initializers/hxruby_autoload.rb",
  ]) {
    if (!list.includes(expected)) {
      console.error(`[todoapp] Release archive missing generated file: ${expected}`);
      process.exit(1);
    }
  }
  if (!list.some((entry) => entry.startsWith("./public/assets/") && entry.includes("application"))) {
    console.error("[todoapp] Release archive missing precompiled application asset.");
    process.exit(1);
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
  const fullPath = writeTargetPath(relativePath);
  writeFileSync(fullPath, content);
}

function writeTargetPath(relativePath) {
  const fullPath = join(appDir, relativePath);
  mkdirSync(dirname(fullPath), { recursive: true });
  return fullPath;
}

function run(commandName, args, options = {}) {
  const result = spawnSync(commandName, args, {
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

function runStreaming(commandName, args, options = {}) {
  const result = spawnSync(commandName, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
    stdio: "inherit",
  });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

function printReady() {
  console.log("");
  console.log("[todoapp] Ready.");
  console.log(`[todoapp] Run: npm run todoapp:server`);
  console.log(`[todoapp] Visit: http://${bind}:${port}/`);
  console.log("[todoapp] Optional watcher: npm run todoapp:watch");
}

function usage() {
  console.log(`Usage: node scripts/rails/todoapp.js <command>

Commands:
  compile   Compile Haxe/HHX and refresh generated Rails files.
  prepare   Compile, bundle, prepare the SQLite DB, and seed demo data.
  server    Start Rails at http://${bind}:${port}/.
  watch     Recompile Haxe/HHX when source files change.
  test      Compile, materialize, and run the Rails test suite.
  production-smoke
           Compile, test, zeitwerk-check, precompile assets, and archive.

Environment:
  PORT=3001 BIND=0.0.0.0 HXRUBY_WATCH_INTERVAL=750 npm run todoapp:server
`);
}
