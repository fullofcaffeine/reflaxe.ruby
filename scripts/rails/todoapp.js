#!/usr/bin/env node

const {
  copyFileSync,
  chmodSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} = require("node:fs");
const { dirname, join, relative, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const exampleDir = join(root, "examples", "todoapp_rails");
const sourceDir = join(exampleDir, "src");
const buildDir = join(exampleDir, "build");
const tmpDir = join(exampleDir, "tmp");
const compiledDir = join(tmpDir, "compiler");
const compiledClientDir = join(tmpDir, "client");
const appDir = join(buildDir, "rails");
const releaseArchive = join(buildDir, "release", "todoapp_rails_release.tgz");
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
    resetDevelopmentDatabaseIfRequested();
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
      sourceDir,
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
    join(appDir, "app", "lib", "railshx"),
    join(appDir, "app", "controllers"),
    join(appDir, "app", "models"),
    join(appDir, "app", "assets", "stylesheets"),
    join(appDir, "app", "javascript"),
    join(appDir, "app", "views", "todos"),
    join(appDir, "app", "views", "users"),
    join(appDir, "app", "views", "controllers"),
    join(appDir, "app", "views", "controllers", "todos"),
    join(appDir, "app", "views", "controllers", "users"),
    join(appDir, "config", "initializers", "hxruby_autoload.rb"),
    join(appDir, "public", "assets"),
    join(appDir, "test", "generated"),
  ]) {
    rmSync(path, { force: true, recursive: true });
  }

  copyTree(join(compiledDir, "app"), join(appDir, "app"));
  copyTree(join(compiledDir, "config"), join(appDir, "config"));
  spliceRailsOwnedRouteSnippet();

  copyTree(join(compiledDir, "db", "migrate"), join(appDir, "db", "migrate"));
  if (existsSync(join(compiledDir, "test"))) {
    copyTree(join(compiledDir, "test"), join(appDir, "test"));
  }

  writeFile("Gemfile", `source "https://rubygems.org"

gem "rails", ">= 7.0", "< 8.0"
gem "sqlite3", "~> 1.4"
gem "puma", ">= 5.0"
gem "propshaft", ">= 0.9"
gem "importmap-rails", ">= 2.0"
gem "turbo-rails", ">= 2.0"
gem "devise", ">= 4.9"
gem "mutex_m"
gem "ostruct"
`);

  writeFile("config.ru", `require_relative "config/environment"

run Rails.application
Rails.application.load_server
`);

  writeFile("Rakefile", `require_relative "config/application"

Rails.application.load_tasks
`);

  writeFile("AGENTS.md", `# Generated Rails App Instructions

This Rails app is generated from the RailsHx todoapp source in \`examples/todoapp_rails/src/**\`.

- Treat Haxe/HHX in \`../../src/**\` as the source of truth for controllers, models, routes, views, migrations, Haxe-authored tests, and Haxe-authored client/browser code.
- Treat this directory as deployable Rails output: inspect it freely, but make durable behavior changes in \`../../src/**\` or the RailsHx compiler/materializer.
- Generated Ruby/Rails files should look like idiomatic hand-written Rails code. Visible Haxe/compiler scaffolding, synthetic temp names, duplicated metadata, or \`__hx_*\` methods are bugs unless there is a very specific semantic/runtime reason.
- If generated scaffolding is genuinely unavoidable, the generated file must include a concise inline comment explaining why that code exists and what RailsHx feature owns or consumes it.
- Runtime files such as SQLite databases, logs, tmp files, storage, local bundles, and precompiled assets are local state and should not be committed.
- If generated Rails output looks wrong, update the Haxe source, compiler, or materializer, then run \`npm run todoapp:compile\` from the repository root.
`);

  writeFile("config/boot.rb", `ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"
`);

  writeFile("config/application.rb", `require "rails"
require "active_record/railtie"
require "action_dispatch/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "propshaft"
require "importmap-rails"
require "turbo-rails"
require "devise"
require "devise/orm/active_record"

module HXRubyTodoapp
  class Application < Rails::Application
    config.load_defaults 7.0
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
    config.autoload_paths << Rails.root.join("app/lib")
    config.eager_load_paths << Rails.root.join("app/lib")
    config.assets.paths << Rails.root.join("app/javascript")
    config.action_controller.allow_forgery_protection = false
  end
end
`);

  writeFile("config/initializers/devise.rb", `Devise.setup do |config|
  config.mailer_sender = "railshx@example.test"
  config.secret_key = "railshx-todoapp-devise-secret-key-for-generated-fixture-only"
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
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

  writeFile("config/cable.yml", `development:
  adapter: async

test:
  adapter: test

production:
  adapter: async
`);

  writeFile("config/environments/production.rb", `Rails.application.configure do
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = true
  config.assets.compile = false
  config.active_support.report_deprecations = false
end
`);

  writeFile("config/importmap.rb", `pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "railshx/todo_client", to: "railshx/todo_client.js"
pin_all_from "app/javascript/railshx", under: "railshx"
`);

  copyFileSync(
    join(sourceDir, "assets", "stylesheets", "application.css"),
    writeTargetPath("app/assets/stylesheets/application.css")
  );
  writeFile("app/javascript/application.js", `import "@hotwired/turbo-rails"
import("railshx/todo_client")
`);
  copyClientModuleGraph();

writeFile("db/seeds.rb", `owner = User.find_or_create_by!(email: "owner@example.test") do |user|
  user.name = "RailsHx Owner"
  user.role = "admin"
  user.password = "password123"
  user.password_confirmation = "password123"
end

maintainer = User.find_or_create_by!(email: "maintainer@example.test") do |user|
  user.name = "Template Maintainer"
  user.role = "maintainer"
  user.password = "password123"
  user.password_confirmation = "password123"
end

member = User.find_or_create_by!(email: "member@example.test") do |user|
  user.name = "Product Member"
  user.role = "member"
  user.password = "password123"
  user.password_confirmation = "password123"
end

guest = User.find_or_create_by!(email: "guest@example.test") do |user|
  user.name = "Guest Workspace"
  user.role = "guest"
  user.password = "password123"
  user.password_confirmation = "password123"
end

Todo.find_or_create_by!(title: "Ship typed Rails templates", user: owner) do |todo|
  todo.notes = "HHX stays typed in Haxe; ERB is generated for Rails."
  todo.is_completed = false
end

Todo.find_or_create_by!(title: "Wire the Rails dev loop", user: maintainer) do |todo|
  todo.notes = "Compile Haxe, run Rails, keep the watcher nearby."
  todo.is_completed = false
end

Todo.find_or_create_by!(title: "Model a typed session seam", user: member) do |todo|
  todo.notes = "Use Rails session and flash stores through typed Haxe facades."
  todo.is_completed = false
end

ChatMessage.find_or_create_by!(body: "Routes, params, and HHX are all typed for this room.", user: owner)
ChatMessage.find_or_create_by!(body: "Turbo gets normal Rails streams; Haxe owns the safer authoring layer.", user: maintainer)
ChatMessage.find_or_create_by!(body: "Turbo Streams carry typed room updates between browsers.", user: member)
ChatMessage.find_or_create_by!(body: "Guest mode is Devise-backed; Haxe just makes the happy path typed.", user: guest)
`);

  writeFile("app/models/application_record.rb", `class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
`);

  rmSync(writeTargetPath("test"), { force: true, recursive: true });
writeFile("test/test_helper.rb", `ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Migration.maintain_test_schema!

class ActiveSupport::TestCase
  USER_PASSWORD = "password123"

  setup do
    ChatMessage.delete_all
    Todo.delete_all
    User.delete_all
  end

  def create_user!(name:, email:, role: "member")
    User.create!(
      name: name,
      email: email,
      role: role,
      password: USER_PASSWORD,
      password_confirmation: USER_PASSWORD
    )
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
`);
  copyTree(join(sourceDir, "rails", "test"), join(appDir, "test"));
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

function resetDevelopmentDatabaseIfRequested() {
  if (process.env.RAILSHX_TODOAPP_RESET_DB !== "1") {
    return;
  }
  for (const file of [
    "development.sqlite3",
    "development.sqlite3-shm",
    "development.sqlite3-wal",
  ]) {
    rmSync(join(appDir, "db", file), { force: true });
  }
  console.log("[todoapp] Reset development SQLite DB for deterministic browser test data.");
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
  console.log("[todoapp] Watching Haxe/RailsHx sources. Run `rake todoapp:server` in another terminal, or use `rake todoapp:start:watch` to run both.");

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
    sourceDir,
    join(exampleDir, "build-client.hxml"),
    join(exampleDir, "build-e2e.hxml"),
    join(exampleDir, "README.md"),
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
  mkdirSync(dirname(releaseArchive), { recursive: true });
  runStreaming("tar", ["-czf", releaseArchive, "-C", appDir, "."]);
}

function assertReleaseArchive() {
  const list = run("tar", ["-tzf", releaseArchive]).stdout.split("\n").filter(Boolean);
  for (const expected of [
    "./app/models/todo.rb",
    "./app/controllers/application_controller.rb",
    "./app/controllers/todos_controller.rb",
    "./app/views/todos/index.html.erb",
    "./app/views/layouts/application.html.erb",
    "./app/javascript/railshx/todo_client.js",
    "./app/javascript/railshx/client/TodoClient.js",
    "./app/javascript/railshx/rails/turbo/Turbo.js",
    "./db/migrate/20260101000000_create_todos.rb",
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
  if (list.some((entry) => entry.startsWith("./app/haxe_gen/") || entry.includes("/app/haxe_gen/"))) {
    console.error("[todoapp] Release archive still contains legacy app/haxe_gen output.");
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

function copyClientModuleGraph() {
  const entry = join(compiledClientDir, "_todo_client_tmp.js");
  if (!existsSync(entry)) {
    console.error("[todoapp] Haxe client output did not include _todo_client_tmp.js.");
    process.exit(1);
  }

  const targetRoot = writeTargetPath("app/javascript/railshx/.keep");
  rmSync(dirname(targetRoot), { force: true, recursive: true });
  copyTree(compiledClientDir, dirname(targetRoot));

  copyFileSync(entry, writeTargetPath("app/javascript/railshx/todo_client.js"));
  rmSync(writeTargetPath("app/javascript/railshx/_todo_client_tmp.js"), { force: true });

  const sourceMap = join(compiledClientDir, "_todo_client_tmp.js.map");
  if (existsSync(sourceMap)) {
    copyFileSync(sourceMap, writeTargetPath("app/javascript/railshx/todo_client.js.map"));
    rmSync(writeTargetPath("app/javascript/railshx/_todo_client_tmp.js.map"), { force: true });
  }

  rewriteImportmapModuleImports(dirname(targetRoot), "railshx");
}

function rewriteImportmapModuleImports(moduleRoot, importRoot) {
  for (const file of collectJsFiles(moduleRoot)) {
    const original = readFileSync(file, "utf8");
    const rewritten = original.replace(/(from\s+["']|import\s+["']|import\s*\(\s*["'])(\.[^"']+\.js)(["'])/g, (_match, prefix, specifier, suffix) => {
      const target = resolve(dirname(file), specifier);
      const modulePath = relative(moduleRoot, target).replace(/\\/g, "/").replace(/\.js$/, "");
      return `${prefix}${importRoot}/${modulePath}${suffix}`;
    });
    if (rewritten !== original) {
      writeFileSync(file, rewritten);
    }
  }
}

function collectJsFiles(path) {
  const files = [];
  if (!existsSync(path)) {
    return files;
  }
  for (const entry of readdirSync(path, { withFileTypes: true })) {
    const fullPath = join(path, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectJsFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith(".js")) {
      files.push(fullPath);
    }
  }
  return files;
}

function spliceRailsOwnedRouteSnippet() {
  const routesPath = writeTargetPath("config/routes.rb");
  const snippetPath = join(sourceDir, "rails", "config", "routes_rails_owned.rb");
  const routes = readFileSync(routesPath, "utf8");
  const snippet = readFileSync(snippetPath, "utf8").trimEnd();
  const insertionPoint = "\nend\n";

  if (!routes.includes(insertionPoint)) {
    console.error("[todoapp] Generated config/routes.rb did not have the expected Rails draw terminator.");
    process.exit(1);
  }

  // This is intentionally a materializer-only mixed-ownership seam for the
  // todoapp. Greenfield RailsHx routes still come from AppRoutes.hx; this
  // snippet models an existing Rails app route that remains Rails-owned but is
  // consumed from Haxe through the generated typed Routes.hx extern.
  writeFileSync(routesPath, routes.replace(insertionPoint, `\n${snippet}\nend\n`));
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
  console.log(`[todoapp] Run: rake todoapp:start`);
  console.log(`[todoapp] Visit: http://${bind}:${port}/`);
  console.log("[todoapp] Watch mode: rake todoapp:start:watch");
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
  PORT=3001 BIND=0.0.0.0 HXRUBY_WATCH_INTERVAL=750 rake todoapp:server
`);
}
