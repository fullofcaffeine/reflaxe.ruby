#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "rails_adopt_generator");
const existingErb = join(outputDir, "app", "views", "legacy", "_badge.html.erb");
const reflaxeSrc = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
].find((candidate) => existsSync(join(candidate, "reflaxe", "ReflectCompiler.hx")));

if (!reflaxeSrc) {
  fail("Unable to find vendored Reflaxe source for Rails adoption generator smoke.");
}

rmSync(outputDir, { force: true, recursive: true });
mkdirSync(join(outputDir, "app", "views", "legacy"), { recursive: true });
mkdirSync(join(outputDir, "app", "services"), { recursive: true });
mkdirSync(join(outputDir, "app", "models", "concerns"), { recursive: true });
mkdirSync(join(outputDir, "config", "initializers"), { recursive: true });
mkdirSync(join(outputDir, "db"), { recursive: true });
mkdirSync(join(outputDir, "db", "migrate"), { recursive: true });
mkdirSync(join(outputDir, "sig"), { recursive: true });
mkdirSync(join(outputDir, "vendor", "demo_auth", "lib", "demo_auth"), { recursive: true });
mkdirSync(join(outputDir, "vendor", "devise", "lib", "devise"), { recursive: true });
mkdirSync(join(outputDir, "src_haxe", "models"), { recursive: true });
writeFileSync(existingErb, "<strong><%= label %></strong>\n");
writeFileSync(join(outputDir, "Gemfile"), [
  'source "https://rubygems.org"',
  'gem "demo_auth", path: "vendor/demo_auth"',
  'gem "devise", path: "vendor/devise"',
  "",
].join("\n"));
writeFileSync(join(outputDir, "vendor", "demo_auth", "demo_auth.gemspec"), [
  "Gem::Specification.new do |s|",
  '  s.name = "demo_auth"',
  '  s.version = "0.1.0"',
  '  s.summary = "Demo auth gem for RailsHx adoption smoke"',
  '  s.authors = ["RailsHx"]',
  '  s.files = Dir["lib/**/*.rb"]',
  '  s.require_paths = ["lib"]',
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "vendor", "demo_auth", "lib", "demo_auth.rb"), [
  'raise "gem source was executed"',
  "",
  "module DemoAuth",
  "  class SessionManager",
  '    def initialize(scope = "user")',
  "      @scope = scope",
  "    end",
  "",
  "    def current_user(controller)",
  "      nil",
  "    end",
  "",
  "    def self.enabled?(scope)",
  "      true",
  "    end",
  "  end",
  "",
  "  module ControllerHelpers",
  "    def authenticate_user!",
  "      true",
  "    end",
  "  end",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "vendor", "devise", "devise.gemspec"), [
  "Gem::Specification.new do |s|",
  '  s.name = "devise"',
  '  s.version = "5.0.0"',
  '  s.summary = "Devise fixture for RailsHx adoption smoke"',
  '  s.authors = ["RailsHx"]',
  '  s.files = Dir["lib/**/*.rb"]',
  '  s.require_paths = ["lib"]',
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "vendor", "devise", "lib", "devise.rb"), [
  'raise "devise source was executed"',
  "",
  "module Devise",
  "  class Mapping",
  "    def self.find_scope!(resource)",
  "      :user",
  "    end",
  "  end",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "config", "routes.rb"), [
  "Rails.application.routes.draw do",
  "  devise_for :users",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "config", "initializers", "devise.rb"), [
  "Devise.setup do |config|",
  "  config.sign_out_via = :delete",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "app", "models", "user.rb"), [
  "class User < ApplicationRecord",
  "  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :confirmable, :lockable, :validatable",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "db", "schema.rb"), [
  "ActiveRecord::Schema[7.2].define(version: 2026_01_01_000001) do",
  '  create_table "users", force: :cascade do |t|',
  '    t.string "email", null: false',
  '    t.string "encrypted_password", null: false',
  '    t.string "reset_password_token"',
  '    t.datetime "reset_password_sent_at"',
  '    t.datetime "remember_created_at"',
  '    t.string "confirmation_token"',
  '    t.datetime "confirmed_at"',
  '    t.datetime "confirmation_sent_at"',
  '    t.integer "failed_attempts"',
  '    t.string "unlock_token"',
  '    t.datetime "locked_at"',
  '    t.datetime "created_at", null: false',
  '    t.datetime "updated_at", null: false',
  "  end",
  '  create_table "todos", force: :cascade do |t|',
  '    t.string "title", null: false',
  '    t.boolean "is_completed", default: false, null: false',
  '    t.decimal "estimate", precision: 10, scale: 2',
  '    t.text "notes"',
  '    t.bigint "user_id", null: false',
  '    t.references "category", null: false, index: true, foreign_key: true',
  '    t.datetime "created_at", null: false',
  '    t.datetime "updated_at", null: false',
  '    t.index ["user_id"], name: "index_todos_on_user_id"',
  "  end",
  '  add_foreign_key "todos", "users"',
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "db", "migrate", "20260101000000_create_users.rb"), [
  "class CreateUsers < ActiveRecord::Migration[7.2]",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "db", "migrate", "20260101000001_create_todos.rb"), [
  "# Generated by RailsHx.",
  "class CreateTodos < ActiveRecord::Migration[7.2]",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "db", "migrate", "20260101000001_create_members.rb"), [
  "class CreateMembers < ActiveRecord::Migration[7.2]",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "db", "migrate", "20260101000002_duplicate_users.rb"), [
  "class CreateUsers < ActiveRecord::Migration[7.2]",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "db", "migrate", "legacy_migration.rb"), [
  "class LegacyMigration < ActiveRecord::Migration[7.2]",
  "end",
  "",
].join("\n"));
writeFileSync(join(outputDir, "src_haxe", "models", "User.hx"), [
  "package models;",
  "",
  "class User extends rails.active_record.Base<User> implements devisehx.model.DeviseResource<User> {",
  "\tpublic var email:String;",
  "\tpublic var resetPasswordToken:Null<String>;",
  "}",
  "",
].join("\n"));
const serviceSource = join(outputDir, "app", "services", "legacy_price_formatter.rb");
writeFileSync(serviceSource, [
  "raise \"service source was executed\"",
  "",
  "class LegacyPriceFormatter",
  "  def initialize(currency = \"USD\")",
  "    @currency = currency",
  "  end",
  "",
  "  def badge_label(kind, cents = 0)",
  "    \"#{kind}:#{cents}\"",
  "  end",
  "",
  "  def ambiguous(*values)",
  "    values.join(',')",
  "  end",
  "",
  "  def self.call(cents, include_symbol = true)",
  "    cents.to_s",
  "  end",
  "end",
  "",
].join("\n"));
const extensionSource = join(outputDir, "app", "models", "concerns", "sluggable.rb");
writeFileSync(extensionSource, [
  "module Sluggable",
  "  def slug",
  "    title.downcase",
  "  end",
  "",
  "  def decorated_title(prefix, tone = nil)",
  "    \"#{prefix}:#{title}\"",
  "  end",
  "",
  "  def dynamic_tags(*tags)",
  "    tags.join(',')",
  "  end",
  "",
  "  module ClassMethods",
  "    def find_by_slug(slug)",
  "      nil",
  "    end",
  "  end",
  "end",
  "",
].join("\n"));
const rbsSource = join(outputDir, "sig", "rbs_price_formatter.rbs");
writeFileSync(rbsSource, [
  "class RbsPriceFormatter",
  "  def initialize: (?String currency) -> void",
  "  def label_for: (String kind, ?Integer cents) -> String",
  "  def maybe_label: (String? kind, ?Integer? cents) -> String?",
  "  def maybe_total: (Float? amount) -> Float?",
  "  def unknown_shape: (Money amount) -> Money",
  "  def unknown_optional: (Money? amount) -> Money?",
  "  def self.call: (Integer cents, ?bool include_symbol) -> String",
  "  def self.parse_flag: (bool? raw) -> bool?",
  "end",
  "",
].join("\n"));

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--package",
  "interop",
  "--service",
  "LegacyPriceFormatter",
  "--service",
  "RbsPriceFormatter",
  "--service-source",
  serviceSource,
  "--rbs",
  rbsSource,
  "--template",
  "legacy/badge",
  "--locals",
  "label:String,tone:String",
  "--extension-source",
  extensionSource,
  "--extension-module",
  "Sluggable",
]);

assertIncludes("src_haxe/interop/LegacyPriceFormatter.hx", [
  "package interop;",
  "// Generated from app/services/legacy_price_formatter.rb.",
  "// Replace Dynamic placeholders with precise types as this boundary stabilizes.",
  '@:native("LegacyPriceFormatter")',
  "extern class LegacyPriceFormatter",
  "public function new(?currency:String):Void;",
  "public function badgeLabel(kind:Dynamic, ?cents:Int):Dynamic;",
  "TODO: ambiguous uses splat",
  "public static function call(cents:Dynamic, ?includeSymbol:Bool):Dynamic;",
]);
assertIncludes("src_haxe/interop/RbsPriceFormatter.hx", [
  "package interop;",
  "// Generated from sig/rbs_price_formatter.rbs.",
  "// Generated from deterministic RBS metadata.",
  "// TODO: Review any Dynamic placeholders from unsupported or application-specific RBS types.",
  '@:native("RbsPriceFormatter")',
  "extern class RbsPriceFormatter",
  "public function new(?currency:String):Void;",
  "public function labelFor(kind:String, ?cents:Int):String;",
  "public function maybeLabel(kind:Null<String>, ?cents:Null<Int>):Null<String>;",
  "public function maybeTotal(amount:Null<Float>):Null<Float>;",
  "public function unknownShape(amount:Dynamic):Dynamic;",
  "public function unknownOptional(amount:Dynamic):Dynamic;",
  "public static function call(cents:Int, ?includeSymbol:Bool):String;",
  "public static function parseFlag(raw:Null<Bool>):Null<Bool>;",
]);
assertIncludes("src_haxe/interop/templates/LegacyBadgeTemplate.hx", [
  "package interop.templates;",
  "import rails.action_view.Template;",
  "typedef LegacyBadgeLocals",
  "var label:String;",
  "var tone:String;",
  'Template.existing("legacy/badge")',
]);
assertIncludes("src_haxe/interop/extensions/SluggableInstance.hx", [
  "package interop.extensions;",
  "// Review required: Ruby source does not carry Haxe return/argument types.",
  '@:rubyMixin({module: "Sluggable"})',
  "extern interface SluggableInstance",
  "public function slug():Dynamic;",
  "public function decoratedTitle(prefix:Dynamic, ?tone:Dynamic):Dynamic;",
  "Skipped dynamic_tags",
]);
assertIncludes("src_haxe/interop/extensions/SluggableClassMethods.hx", [
  "package interop.extensions;",
  '@:rubyMixin({module: "Sluggable"})',
  "extern class SluggableClassMethods",
  "public static function findBySlug(slug:Dynamic):Dynamic;",
]);
assertManifest([
  ["src_haxe/interop/LegacyPriceFormatter.hx", "haxe_adopted_service"],
  ["src_haxe/interop/RbsPriceFormatter.hx", "haxe_adopted_service"],
  ["src_haxe/interop/templates/LegacyBadgeTemplate.hx", "haxe_adopted_template"],
  ["src_haxe/interop/extensions/SluggableInstance.hx", "haxe_adopted_extension"],
  ["src_haxe/interop/extensions/SluggableClassMethods.hx", "haxe_adopted_extension"],
]);

const schemaDiscover = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--schema",
  "--discover",
]);
for (const expected of [
  "[rails:adopt:schema] db/schema.rb",
  "table: users -> models.User",
  "table: todos -> models.Todo",
  "columns: 8",
  "timestamps: true",
  "index: user_id",
  "foreign_key: user_id -> users",
  "review: Reference category from t.references generated category_id",
  "review: Foreign key user_id points to users",
  "next: bin/rails generate hxruby:adopt --schema --models User,Todo",
]) {
  if (!schemaDiscover.stdout.includes(expected)) {
    process.stdout.write(schemaDiscover.stdout);
    process.stderr.write(schemaDiscover.stderr);
    fail(`schema discovery missing ${expected}`);
  }
}

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--schema",
  "--models",
  "Todo",
]);
assertIncludes("src_haxe/models/Todo.hx", [
  "package models;",
  "// Rails-owned table adopted from db/schema.rb.",
  "// Runtime owner: Rails/database schema. Haxe owner: typed contract for",
  '@:railsModel("todos")',
  "@:railsTimestamps",
  "class Todo extends rails.active_record.Base<Todo>",
  '@:railsColumn({primaryKey: true, dbType: "bigint"})',
  "public var id:Int;",
  "@:railsColumn({nullable: false})",
  "public var title:String;",
  "@:railsColumn({nullable: false, defaultValue: false})",
  "public var isCompleted:Bool;",
  '@:railsColumn({dbType: "decimal", precision: 10, scale: 2})',
  "public var estimate:Null<Float>;",
  '@:railsColumn({dbType: "text"})',
  "public var notes:Null<String>;",
  '@:railsColumn({nullable: false, dbType: "bigint", index: true})',
  "public var userId:Int;",
  "TODO: Column user_id looks like a foreign key",
  "TODO: Reference category from t.references generated category_id",
  "TODO: Reference category declares foreign_key: true",
  '@:railsColumn({nullable: false, dbType: "bigint", index: true})',
  "public var categoryId:Int;",
  "TODO: Foreign key user_id points to users",
]);
assertManifest([
  ["src_haxe/models/Todo.hx", "haxe_adopted_schema_model"],
]);

expectGeneratorFailure("non-owned schema model collision", [
  "--output",
  outputDir,
  "--schema",
  "--models",
  "User",
], "Refusing to overwrite non-RailsHx-owned file");

writeFileSync(join(outputDir, "db", "schema_unknown.rb"), [
  "ActiveRecord::Schema[7.2].define(version: 2026_01_01_000002) do",
  '  create_table "widgets", force: :cascade do |t|',
  '    t.citext "slug", null: false',
  "  end",
  "end",
  "",
].join("\n"));
expectGeneratorFailure("unknown schema column type", [
  "--output",
  outputDir,
  "--schema",
  "--from",
  "db/schema_unknown.rb",
  "--discover",
], "Unsupported schema column type");

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--schema",
  "--from",
  "db/schema_unknown.rb",
  "--models",
  "Widget",
  "--allow-dynamic",
]);
assertIncludes("src_haxe/models/Widget.hx", [
  "package models;",
  '@:railsModel("widgets")',
  "class Widget extends rails.active_record.Base<Widget>",
  "TODO: Column slug used unsupported type citext; generated Dynamic because --allow-dynamic was explicit.",
  '@:railsColumn({nullable: false, dbType: "citext"})',
  "public var slug:Dynamic;",
]);
assertManifest([
  ["src_haxe/models/Widget.hx", "haxe_adopted_schema_model"],
]);

writeFileSync(join(outputDir, "db", "structure.sql"), [
  "CREATE TABLE widgets (",
  "  id bigint PRIMARY KEY,",
  "  slug citext NOT NULL",
  ");",
  "",
].join("\n"));
expectGeneratorFailure("structure.sql schema source", [
  "--output",
  outputDir,
  "--schema",
  "--from",
  "db/structure.sql",
  "--discover",
], "SQL/structure.sql schema adoption is not supported");

writeFileSync(join(outputDir, "db", "schema_unsafe_table.rb"), [
  "ActiveRecord::Schema[7.2].define(version: 2026_01_01_000003) do",
  '  create_table "legacy-items", force: :cascade do |t|',
  '    t.string "name"',
  "  end",
  "end",
  "",
].join("\n"));
expectGeneratorFailure("unsafe schema table name", [
  "--output",
  outputDir,
  "--schema",
  "--from",
  "db/schema_unsafe_table.rb",
  "--discover",
], "Unsupported schema table name");

writeFileSync(join(outputDir, "db", "schema_unsafe_column.rb"), [
  "ActiveRecord::Schema[7.2].define(version: 2026_01_01_000004) do",
  '  create_table "widgets", force: :cascade do |t|',
  '    t.string "display-name"',
  "  end",
  "end",
  "",
].join("\n"));
expectGeneratorFailure("unsafe schema column name", [
  "--output",
  outputDir,
  "--schema",
  "--from",
  "db/schema_unsafe_column.rb",
  "--discover",
], "Unsupported schema column name");

writeFileSync(join(outputDir, "db", "schema_haxe_field_collision.rb"), [
  "ActiveRecord::Schema[7.2].define(version: 2026_01_01_000005) do",
  '  create_table "widgets", force: :cascade do |t|',
  '    t.string "class"',
  '    t.string "class_value"',
  "  end",
  "end",
  "",
].join("\n"));
expectGeneratorFailure("schema Haxe field collision", [
  "--output",
  outputDir,
  "--schema",
  "--from",
  "db/schema_haxe_field_collision.rb",
  "--discover",
], "maps multiple columns to Haxe field classValue");

const migrationsDiscover = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--migrations",
  "--discover",
]);
for (const expected of [
  "[rails:adopt:migrations] db/migrate",
  "migration: 20260101000000 db/migrate/20260101000000_create_users.rb class=CreateUsers owner=rails",
  "migration: 20260101000001 db/migrate/20260101000001_create_todos.rb class=CreateTodos owner=railshx",
  "migration: no_timestamp db/migrate/legacy_migration.rb class=LegacyMigration owner=rails",
  "collision: duplicate timestamp 20260101000001",
  "collision: duplicate class CreateUsers",
  "next: prefer --schema adoption for current model contracts",
]) {
  if (!migrationsDiscover.stdout.includes(expected)) {
    process.stdout.write(migrationsDiscover.stdout);
    process.stderr.write(migrationsDiscover.stderr);
    fail(`migration discovery missing ${expected}`);
  }
}

expectGeneratorFailure("migrations without discovery", [
  "--output",
  outputDir,
  "--migrations",
], "--migrations is a discover-only adoption report");

const gemDiscover = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--gem",
  "demo_auth",
  "--discover",
]);
if (!gemDiscover.stdout.includes("[rails:adopt:gem] demo_auth 0.1.0") || !gemDiscover.stdout.includes("constant: DemoAuth::SessionManager")) {
  process.stdout.write(gemDiscover.stdout);
  process.stderr.write(gemDiscover.stderr);
  fail("gem discovery did not report deterministic Bundler inventory");
}

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--package",
  "interop",
  "--gem",
  "demo_auth",
  "--write",
  "contracts",
]);
assertIncludes("src_haxe/interop/gems/demo_auth/GemLayer.hx", [
  "package interop.gems.demo_auth;",
  "public static inline final gemName:String = \"demo_auth\";",
  "public static inline final version:String = \"0.1.0\";",
  "public static inline final reviewRequired:Bool = true;",
]);
assertIncludes("src_haxe/interop/gems/demo_auth/SessionManager.hx", [
  "package interop.gems.demo_auth;",
  "// Generated from Bundler gem demo_auth.",
  '@:native("DemoAuth::SessionManager")',
  "extern class SessionManager",
  "public function new(?scope:String):Void;",
  "public function currentUser(controller:Dynamic):Dynamic;",
  '@:native("enabled?")',
  "public static function enabled(scope:Dynamic):Dynamic;",
]);
assertIncludes("src_haxe/interop/gems/demo_auth/ControllerHelpers.hx", [
  "package interop.gems.demo_auth;",
  '@:native("DemoAuth::ControllerHelpers")',
  "extern class ControllerHelpers",
  '@:native("authenticate_user!")',
  "public function authenticateUser():Dynamic;",
]);
assertIncludes("docs/railshx/gems/demo_auth.md", [
  "# RailsHx Gem Layer: demo_auth",
  "- Gem: `demo_auth`",
  "- Version: `0.1.0`",
  "- `DemoAuth::SessionManager`",
  "Replace any generated `Dynamic` placeholders",
]);
assertManifest([
  ["src_haxe/interop/gems/demo_auth/GemLayer.hx", "haxe_adopted_gem_layer"],
  ["src_haxe/interop/gems/demo_auth/SessionManager.hx", "haxe_adopted_gem_contract"],
  ["src_haxe/interop/gems/demo_auth/ControllerHelpers.hx", "haxe_adopted_gem_contract"],
  ["docs/railshx/gems/demo_auth.md", "docs"],
]);

const deviseDiscover = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--gem",
  "devise",
  "--discover",
]);
if (
  !deviseDiscover.stdout.includes("[rails:adopt:devise] devise 5.0.0")
  || !deviseDiscover.stdout.includes("scope: user model=User resource=users")
  || !deviseDiscover.stdout.includes("schema: ok")
) {
  process.stdout.write(deviseDiscover.stdout);
  process.stderr.write(deviseDiscover.stderr);
  fail("Devise discovery did not report deterministic app inventory");
}

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--package",
  "interop",
  "--gem",
  "devise",
  "--write",
  "contracts",
  "--devise-hhx-views",
]);
assertIncludes("src_haxe/app/auth/UserAuth.hx", [
  "package app.auth;",
  "// Generated by DeviseHx from deterministic Bundler, route, model, and schema metadata.",
  "final class UserAuth",
  "routeAuthorable: true",
  "public static final scope:DeviseScope<User> = DeviseScope.of(",
  'ScopeName.named("user")',
  'RouteResource.named("users")',
  "public static final authenticate:AuthFilter<User> = Auth.require(scope);",
  "public static inline function current(controller:Base):Null<User>",
  "public static inline function signIn(controller:Base, resource:User):Void",
]);
assertIncludes("src_haxe/views/devise/users/SessionsNewView.hx", [
  "package views.devise.users;",
  "// Generated DeviseHx HHX session view skeleton.",
  '@:railsTemplate("devise/sessions/new")',
  "class SessionsNewView",
  "<form_with url=${AuthLinks.sessionPath(UserAuth.scope)} scope=\"user\" local class=\"devisehx-auth-form\">",
  "import devisehx.hhx.DeviseFormFields;",
  "<password_field name=${DeviseFormFields.password} autocomplete=\"current-password\" required />",
  "<devise_sign_up_link scope=${UserAuth.scope} class=\"devisehx-secondary-link\">Create an account</devise_sign_up_link>",
]);
assertIncludes("src_haxe/views/devise/users/RegistrationsNewView.hx", [
  "package views.devise.users;",
  "// Generated DeviseHx HHX registration view skeleton.",
  '@:railsTemplate("devise/registrations/new")',
  "class RegistrationsNewView",
  "<if ${DeviseErrors.hasAny(locals.resource)}>",
  "<form_with url=${AuthLinks.registrationPath(UserAuth.scope)} scope=\"user\" local class=\"devisehx-auth-form\">",
  "<password_field name=${DeviseFormFields.passwordConfirmation} autocomplete=\"new-password\" required />",
]);
assertIncludes("src_haxe/views/devise/users/PasswordsNewView.hx", [
  "package views.devise.users;",
  "// Generated DeviseHx HHX password reset request view skeleton.",
  '@:railsTemplate("devise/passwords/new")',
  "class PasswordsNewView",
  "<form_with url=${AuthLinks.passwordPath(UserAuth.scope)} scope=\"user\" local class=\"devisehx-auth-form\">",
  "<email_field name=${DeviseFormFields.email} autocomplete=\"email\" required />",
  "<devise_sign_in_link scope=${UserAuth.scope} class=\"devisehx-secondary-link\">Back to sign in</devise_sign_in_link>",
]);
assertIncludes("src_haxe/views/devise/users/PasswordsEditView.hx", [
  "package views.devise.users;",
  "// Generated DeviseHx HHX password edit view skeleton.",
  '@:railsTemplate("devise/passwords/edit")',
  "class PasswordsEditView",
  "<form_with url=${AuthLinks.passwordPath(UserAuth.scope)} scope=\"user\" method=\"patch\" local class=\"devisehx-auth-form\">",
  "<hidden_field name=${DeviseFormFields.resetPasswordToken} value=${locals.resource.resetPasswordToken} />",
  "<password_field name=${DeviseFormFields.passwordConfirmation} autocomplete=\"new-password\" required />",
]);
assertIncludes("src_haxe/views/devise/users/ConfirmationsNewView.hx", [
  "package views.devise.users;",
  "// Generated DeviseHx HHX confirmation request view skeleton.",
  '@:railsTemplate("devise/confirmations/new")',
  "class ConfirmationsNewView",
  "<form_with url=${AuthLinks.confirmationPath(UserAuth.scope)} scope=\"user\" local class=\"devisehx-auth-form\">",
  "<email_field name=${DeviseFormFields.email} autocomplete=\"email\" required />",
  "<devise_sign_in_link scope=${UserAuth.scope} class=\"devisehx-secondary-link\">Back to sign in</devise_sign_in_link>",
]);
assertIncludes("src_haxe/views/devise/users/UnlocksNewView.hx", [
  "package views.devise.users;",
  "// Generated DeviseHx HHX unlock request view skeleton.",
  '@:railsTemplate("devise/unlocks/new")',
  "class UnlocksNewView",
  "<form_with url=${AuthLinks.unlockPath(UserAuth.scope)} scope=\"user\" local class=\"devisehx-auth-form\">",
  "<email_field name=${DeviseFormFields.email} autocomplete=\"email\" required />",
  "<devise_sign_in_link scope=${UserAuth.scope} class=\"devisehx-secondary-link\">Back to sign in</devise_sign_in_link>",
]);
assertIncludes(".railshx/gems/devise/inventory.json", [
  '"kind": "devise_inventory"',
  '"name": "devise"',
  '"version_string": "5.0.0"',
  '"scope": "user"',
  '"route_resource": "users"',
  '"model": "User"',
  '"database_authenticatable"',
  '"confirmable"',
  '"encrypted_password"',
  '"lockable"',
]);
assertIncludes(".railshx/gems/devise/diagnostics.json", [
  '"kind": "devise_diagnostics"',
  '"status": "ok"',
  '"diagnostics": [',
]);
assertIncludes("docs/railshx/gems/devise.md", [
  "# DeviseHx Adoption",
  "- Runtime owner: Devise, Warden, Rails routes, Rails controllers, and Bundler.",
  "- Haxe owner: app-local typed auth contracts under `src_haxe/app/auth`.",
  "Generated contract: `app.auth.UserAuth`",
  "Run `bundle exec rake hxruby:routes` after changing Devise routes",
]);
assertSnapshot("src_haxe/app/auth/UserAuth.hx");
assertSnapshot("src_haxe/views/devise/users/SessionsNewView.hx");
assertSnapshot("src_haxe/views/devise/users/RegistrationsNewView.hx");
assertSnapshot("src_haxe/views/devise/users/PasswordsNewView.hx");
assertSnapshot("src_haxe/views/devise/users/PasswordsEditView.hx");
assertSnapshot("src_haxe/views/devise/users/ConfirmationsNewView.hx");
assertSnapshot("src_haxe/views/devise/users/UnlocksNewView.hx");
assertSnapshot(".railshx/gems/devise/inventory.json");
assertSnapshot(".railshx/gems/devise/diagnostics.json");
assertSnapshot("docs/railshx/gems/devise.md");
assertManifest([
  [".railshx/gems/devise/inventory.json", "devise_inventory"],
  [".railshx/gems/devise/diagnostics.json", "devise_diagnostics"],
  ["src_haxe/app/auth/UserAuth.hx", "devise_auth_contract"],
  ["src_haxe/views/devise/users/SessionsNewView.hx", "devise_hhx_view"],
  ["src_haxe/views/devise/users/RegistrationsNewView.hx", "devise_hhx_view"],
  ["src_haxe/views/devise/users/PasswordsNewView.hx", "devise_hhx_view"],
  ["src_haxe/views/devise/users/PasswordsEditView.hx", "devise_hhx_view"],
  ["src_haxe/views/devise/users/ConfirmationsNewView.hx", "devise_hhx_view"],
  ["src_haxe/views/devise/users/UnlocksNewView.hx", "devise_hhx_view"],
  ["docs/railshx/gems/devise.md", "docs"],
]);

// A second run should be able to rewrite manifest-owned Devise HHX skeletons.
// This proves `--devise-hhx-views` participates in the same ownership model as
// other RailsHx adoption outputs instead of treating generated views as one-off
// files.
run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--package",
  "interop",
  "--gem",
  "devise",
  "--write",
  "contracts",
  "--devise-hhx-views",
]);
assertSnapshot("src_haxe/views/devise/users/SessionsNewView.hx");

const erbAfter = readFileSync(existingErb, "utf8");
if (erbAfter !== "<strong><%= label %></strong>\n") {
  fail("adoption generator overwrote Rails-owned ERB source");
}

writeFileSync(join(outputDir, "src_haxe", "Main.hx"), [
  "import app.auth.UserAuth;",
  "import interop.LegacyPriceFormatter;",
  "import interop.RbsPriceFormatter;",
  "import interop.extensions.SluggableClassMethods;",
  "import interop.extensions.SluggableInstance;",
  "import interop.gems.demo_auth.GemLayer;",
  "import interop.gems.demo_auth.SessionManager;",
  "import interop.templates.LegacyBadgeTemplate;",
  "import models.Todo;",
  "import models.User;",
  "import rails.action_controller.Base;",
  "import rails.action_view.HtmlNode;",
  "import views.devise.users.ConfirmationsNewView;",
  "import views.devise.users.PasswordsEditView;",
  "import views.devise.users.PasswordsNewView;",
  "import views.devise.users.RegistrationsNewView;",
  "import views.devise.users.SessionsNewView;",
  "import views.devise.users.UnlocksNewView;",
  "",
  "class Main {",
  "\tstatic function main() {",
  "\t\tvar controller = new Base();",
  "\t\tvar service:Class<LegacyPriceFormatter> = LegacyPriceFormatter;",
  "\t\tvar rbsService:Class<RbsPriceFormatter> = RbsPriceFormatter;",
  "\t\tvar classMethods:Class<SluggableClassMethods> = SluggableClassMethods;",
  "\t\tvar gemLayer:Class<GemLayer> = GemLayer;",
  "\t\tvar sessionManager:Class<SessionManager> = SessionManager;",
  "\t\tvar todoModel:Class<Todo> = Todo;",
  "\t\tvar userAuth:Class<UserAuth> = UserAuth;",
  "\t\tvar instanceContract:Dynamic = (null : SluggableInstance);",
  "\t\tif (false) {",
  "\t\t\tvar formatter = new LegacyPriceFormatter();",
  "\t\t\tformatter.badgeLabel(\"ok\", 1);",
  "\t\t\tLegacyPriceFormatter.call(100);",
  "\t\t\tvar rbsFormatter = new RbsPriceFormatter(\"USD\");",
  "\t\t\trbsFormatter.labelFor(\"ok\", 1);",
  "\t\t\trbsFormatter.maybeLabel(null, null);",
  "\t\t\trbsFormatter.maybeTotal(null);",
  "\t\t\tRbsPriceFormatter.call(100);",
  "\t\t\tRbsPriceFormatter.parseFlag(null);",
  "\t\t\tvar user = new User();",
  "\t\t\tvar todo = new Todo();",
  "\t\t\ttodo.title = \"typed\";",
  "\t\t\ttodo.userId = 1;",
  "\t\t\tTodo.where({title: \"typed\"}).order(Todo.f.title.asc()).limit(1).toArray();",
  "\t\t\tUserAuth.signIn(controller, user);",
  "\t\t\tUserAuth.signOut(controller);",
  "\t\t\tvar current:Null<User> = UserAuth.current(controller);",
  "\t\t\tvar required:User = UserAuth.currentRequired(controller);",
  "\t\t\tvar sessionView:HtmlNode = SessionsNewView.render({resource: user});",
  "\t\t\tvar registrationView:HtmlNode = RegistrationsNewView.render({resource: user});",
  "\t\t\tvar passwordNewView:HtmlNode = PasswordsNewView.render({resource: user});",
  "\t\t\tvar passwordEditView:HtmlNode = PasswordsEditView.render({resource: user});",
  "\t\t\tvar confirmationView:HtmlNode = ConfirmationsNewView.render({resource: user});",
  "\t\t\tvar unlockView:HtmlNode = UnlocksNewView.render({resource: user});",
  "\t\t\tSys.println(UserAuth.signedIn(controller));",
  "\t\t}",
  "\t\tSys.println(service != null);",
  "\t\tSys.println(rbsService != null);",
  "\t\tSys.println(classMethods != null);",
  "\t\tSys.println(gemLayer != null);",
  "\t\tSys.println(sessionManager != null);",
  "\t\tSys.println(todoModel != null);",
  "\t\tSys.println(userAuth != null);",
  "\t\tSys.println(instanceContract == null);",
  "\t\tSys.println(LegacyBadgeTemplate.template.templatePath);",
  "\t}",
  "}",
  "",
].join("\n"));

const compiledOut = join(outputDir, ".compiled");
rmSync(compiledOut, { force: true, recursive: true });
run("haxe", [
  "-D",
  `ruby_output=${compiledOut}`,
  "-D",
  "reflaxe_ruby_rails",
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  join(root, "std"),
  "-cp",
  join(outputDir, "src_haxe"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "-main",
  "Main",
]);
for (const file of [
  "app/views/devise/sessions/new.html.erb",
  "app/views/devise/registrations/new.html.erb",
  "app/views/devise/passwords/new.html.erb",
  "app/views/devise/passwords/edit.html.erb",
  "app/views/devise/confirmations/new.html.erb",
  "app/views/devise/unlocks/new.html.erb",
]) {
  if (!existsSync(join(compiledOut, file))) {
    fail(`generated DeviseHx HHX compile output missing ${file}`);
  }
}

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--service",
  "LegacyPriceFormatter",
]);

const collisionOutput = join(root, "test", ".generated", "rails_adopt_generator_collision");
rmSync(collisionOutput, { force: true, recursive: true });
mkdirSync(join(collisionOutput, "src_haxe", "interop"), { recursive: true });
writeFileSync(join(collisionOutput, "src_haxe", "interop", "LegacyPriceFormatter.hx"), "// hand-written wrapper\n");
const overwrite = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  collisionOutput,
  "--service",
  "LegacyPriceFormatter",
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (overwrite.status === 0 || !overwrite.stderr.includes("Refusing to overwrite non-RailsHx-owned file")) {
  process.stdout.write(overwrite.stdout);
  process.stderr.write(overwrite.stderr);
  fail("adoption generator did not protect non-owned wrapper files");
}

const deviseHhxCollisionOutput = createDeviseFailureFixture("rails_adopt_generator_devise_hhx_collision");
mkdirSync(join(deviseHhxCollisionOutput, "src_haxe", "views", "devise", "users"), { recursive: true });
writeFileSync(
  join(deviseHhxCollisionOutput, "src_haxe", "views", "devise", "users", "SessionsNewView.hx"),
  "// hand-written Devise HHX session view\n"
);
const deviseHhxOverwrite = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  deviseHhxCollisionOutput,
  "--gem",
  "devise",
  "--write",
  "contracts",
  "--devise-hhx-views",
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (deviseHhxOverwrite.status === 0 || !deviseHhxOverwrite.stderr.includes("Refusing to overwrite non-RailsHx-owned file")) {
  process.stdout.write(deviseHhxOverwrite.stdout);
  process.stderr.write(deviseHhxOverwrite.stderr);
  fail("DeviseHx HHX view generation did not protect non-owned view source");
}

const missingSource = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--extension-source",
  join(outputDir, "app", "models", "concerns", "missing.rb"),
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (missingSource.status === 0 || !missingSource.stderr.includes("Extension source does not exist")) {
  process.stdout.write(missingSource.stdout);
  process.stderr.write(missingSource.stderr);
  fail("adoption generator did not fail closed for missing extension source");
}

const missingRbs = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--service",
  "RbsPriceFormatter",
  "--rbs",
  join(outputDir, "sig", "missing.rbs"),
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (missingRbs.status === 0 || !missingRbs.stderr.includes("RBS source does not exist")) {
  process.stdout.write(missingRbs.stdout);
  process.stderr.write(missingRbs.stderr);
  fail("adoption generator did not fail closed for missing RBS source");
}

expectGeneratorFailure("unsafe package", [
  "--output",
  outputDir,
  "--package",
  "interop;bad",
  "--template",
  "legacy/badge",
], "--package must be a safe Haxe package path");

expectGeneratorFailure("unsafe local name", [
  "--output",
  outputDir,
  "--template",
  "legacy/badge",
  "--locals",
  "class:String",
], "Invalid local name");

expectGeneratorFailure("unsafe local type", [
  "--output",
  outputDir,
  "--template",
  "legacy/badge",
  "--locals",
  "label:String);trace('bad')",
], "Invalid local type");

expectGeneratorFailure("unsafe template path", [
  "--output",
  outputDir,
  "--template",
  "../legacy/badge",
], "--template must be a safe relative path");

expectGeneratorFailure("backslash template path", [
  "--output",
  outputDir,
  "--template",
  "legacy\\badge",
], "--template must use forward-slash relative paths");

expectGeneratorFailure("unsafe service constant", [
  "--output",
  outputDir,
  "--service",
  "legacy_price_formatter",
], "--service must be a safe Ruby constant path");

expectGeneratorFailure("source outside app root", [
  "--output",
  outputDir,
  "--service",
  "LegacyPriceFormatter",
  "--service-source",
  join(root, "README.md"),
], "--service-source must stay inside the generator output/app root");

expectGeneratorFailure("missing gem", [
  "--output",
  outputDir,
  "--gem",
  "missing_auth",
  "--discover",
], "Gem missing_auth is not installed");

expectGeneratorFailure("unsafe gem name", [
  "--output",
  outputDir,
  "--gem",
  "../demo_auth",
  "--discover",
], "--gem must be a safe Bundler gem name");

expectGeneratorFailure("gem without mode", [
  "--output",
  outputDir,
  "--gem",
  "demo_auth",
], "--gem requires --discover or --write contracts");

const missingDeviseModelOutput = createDeviseFailureFixture("rails_adopt_devise_missing_model", { model: false });
expectGeneratorFailure("missing Devise model", [
  "--output",
  missingDeviseModelOutput,
  "--gem",
  "devise",
  "--write",
  "contracts",
], "maps to missing model file");

const missingDeviseSchemaOutput = createDeviseFailureFixture("rails_adopt_devise_missing_schema", { schema: false });
expectGeneratorFailure("missing Devise schema", [
  "--output",
  missingDeviseSchemaOutput,
  "--gem",
  "devise",
  "--write",
  "contracts",
], "db/schema.rb not found");

const missingConfirmableColumnsOutput = createDeviseFailureFixture("rails_adopt_devise_missing_confirmable_columns", {
  modules: ["database_authenticatable", "confirmable"],
});
expectGeneratorFailure("missing Devise confirmable columns", [
  "--output",
  missingConfirmableColumnsOutput,
  "--gem",
  "devise",
  "--write",
  "contracts",
], "confirmation_token");

const missingLockableColumnsOutput = createDeviseFailureFixture("rails_adopt_devise_missing_lockable_columns", {
  modules: ["database_authenticatable", "lockable"],
});
expectGeneratorFailure("missing Devise lockable columns", [
  "--output",
  missingLockableColumnsOutput,
  "--gem",
  "devise",
  "--write",
  "contracts",
], "failed_attempts");

const ambiguousDeviseOutput = createDeviseFailureFixture("rails_adopt_devise_ambiguous", { duplicateRoutes: true });
expectGeneratorFailure("ambiguous Devise scopes", [
  "--output",
  ambiguousDeviseOutput,
  "--gem",
  "devise",
  "--discover",
], "ambiguous duplicate devise_for scope");

assertDeviseRouteAuthorability(
  "rails_adopt_devise_string_resource",
  ["Rails.application.routes.draw do", '  devise_for "users"', "end", ""],
  true
);

for (const [name, routeLine] of [
  ["class_name", '  devise_for :users, class_name: "User"'],
  ["singular", "  devise_for :users, singular: :member"],
  ["path", '  devise_for :users, path: "accounts"'],
  ["controllers", '  devise_for :users, controllers: { sessions: "users/sessions" }'],
  ["only", "  devise_for :users, only: [:sessions]"],
]) {
  assertDeviseRouteAuthorability(
    `rails_adopt_devise_non_authorable_${name}`,
    ["Rails.application.routes.draw do", routeLine, "end", ""],
    false,
    "existing devise_for uses unsupported options"
  );
}

assertDeviseRouteAuthorability(
  "rails_adopt_devise_non_authorable_block",
  ["Rails.application.routes.draw do", "  devise_for :users do", "  end", "end", ""],
  false,
  "existing devise_for uses a block"
);

assertDeviseRouteAuthorability(
  "rails_adopt_devise_non_authorable_nested",
  ["Rails.application.routes.draw do", '  scope "/auth" do', "    devise_for :users", "  end", "end", ""],
  false,
  "existing devise_for is nested in another routes block or scope"
);

console.log("[rails-adopt-generator] OK");

function assertIncludes(relativeFile, expectedLines) {
  const fullPath = join(outputDir, relativeFile);
  if (!existsSync(fullPath)) {
    fail(`missing generated file: ${relativeFile}`);
  }
  const content = readFileSync(fullPath, "utf8");
  for (const expected of expectedLines) {
    if (!content.includes(expected)) {
      fail(`${relativeFile} missing expected line: ${expected}`);
    }
  }
}

function assertManifest(entries) {
  const manifest = JSON.parse(readFileSync(join(outputDir, ".railshx", "manifest.json"), "utf8"));
  if (manifest.version !== 1) {
    fail(`unexpected manifest version: ${manifest.version}`);
  }
  for (const [output, kind] of entries) {
    const entry = manifest.outputs.find((candidate) => candidate.output === output);
    if (!entry || entry.kind !== kind || entry.source !== "hxruby:adopt" || !entry.sha256) {
      fail(`manifest missing expected ${output} ${kind} entry`);
    }
  }
}

function assertSnapshot(relativeFile) {
  const actualPath = join(outputDir, relativeFile);
  const snapshotPath = join(root, "test", "snapshots", "m1", "rails_adopt_devise", relativeFile);
  if (!existsSync(actualPath)) {
    fail(`missing generated snapshot source: ${relativeFile}`);
  }
  const actual = readFileSync(actualPath, "utf8");
  if (!existsSync(snapshotPath)) {
    fail(`missing DeviseHx adoption snapshot: ${snapshotPath}`);
  }
  const expected = readFileSync(snapshotPath, "utf8");
  if (actual !== expected) {
    fail(`DeviseHx adoption snapshot mismatch: ${relativeFile}`);
  }
}

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

function createDeviseFailureFixture(name, options = {}) {
  const target = join(root, "test", ".generated", name);
  rmSync(target, { force: true, recursive: true });
  mkdirSync(join(target, "vendor", "devise", "lib"), { recursive: true });
  mkdirSync(join(target, "config"), { recursive: true });
  mkdirSync(join(target, "app", "models"), { recursive: true });
  if (options.schema !== false) {
    mkdirSync(join(target, "db"), { recursive: true });
  }
  writeFileSync(join(target, "Gemfile"), [
    'source "https://rubygems.org"',
    'gem "devise", path: "vendor/devise"',
    "",
  ].join("\n"));
  writeFileSync(join(target, "vendor", "devise", "devise.gemspec"), [
    "Gem::Specification.new do |s|",
    '  s.name = "devise"',
    '  s.version = "5.0.0"',
    '  s.summary = "Devise fixture"',
    '  s.authors = ["RailsHx"]',
    '  s.files = Dir["lib/**/*.rb"]',
    '  s.require_paths = ["lib"]',
    "end",
    "",
  ].join("\n"));
  writeFileSync(join(target, "vendor", "devise", "lib", "devise.rb"), "module Devise; end\n");
  const routesLines = options.routesLines || [
    "Rails.application.routes.draw do",
    "  devise_for :users",
    ...(options.duplicateRoutes ? ["  devise_for :users"] : []),
    "end",
    "",
  ];
  writeFileSync(join(target, "config", "routes.rb"), routesLines.join("\n"));
  if (options.model !== false) {
    const modules = options.modules || ["database_authenticatable"];
    writeFileSync(join(target, "app", "models", "user.rb"), [
      "class User < ApplicationRecord",
      `  devise ${modules.map((mod) => `:${mod}`).join(", ")}`,
      "end",
      "",
    ].join("\n"));
  }
  if (options.schema !== false) {
    writeFileSync(join(target, "db", "schema.rb"), [
      "ActiveRecord::Schema[7.2].define(version: 2026_01_01_000001) do",
      '  create_table "users", force: :cascade do |t|',
      '    t.string "email", null: false',
      '    t.string "encrypted_password", null: false',
      "  end",
      "end",
      "",
    ].join("\n"));
  }
  return target;
}

function assertDeviseRouteAuthorability(name, routesLines, expectedAuthorable, expectedReason = "") {
  const fixtureOutput = createDeviseFailureFixture(name, { routesLines });
  run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "adopt.rb"),
    "--output",
    fixtureOutput,
    "--gem",
    "devise",
    "--write",
    "contracts",
  ]);

  const auth = readFileSync(join(fixtureOutput, "src_haxe", "app", "auth", "UserAuth.hx"), "utf8");
  const expectedFlag = `routeAuthorable: ${expectedAuthorable}`;
  if (!auth.includes(expectedFlag)) {
    fail(`${name} generated auth contract missing ${expectedFlag}`);
  }
  if (expectedReason && !auth.includes(expectedReason)) {
    fail(`${name} generated auth contract missing non-authorable reason ${expectedReason}`);
  }

  const diagnostics = JSON.parse(readFileSync(join(fixtureOutput, ".railshx", "gems", "devise", "diagnostics.json"), "utf8"));
  if (expectedAuthorable && diagnostics.status !== "ok") {
    fail(`${name} expected ok diagnostics, got ${diagnostics.status}`);
  }
  if (!expectedAuthorable) {
    const message = diagnostics.diagnostics.map((diagnostic) => diagnostic.message).join("\n");
    if (diagnostics.status !== "review" || !message.includes(expectedReason)) {
      fail(`${name} expected review diagnostic ${expectedReason}`);
    }
  }
}

function expectGeneratorFailure(label, args, expectedMessage) {
  const result = spawnSync("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "adopt.rb"),
    ...args,
  ], {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status === 0 || !(`${result.stdout}\n${result.stderr}`).includes(expectedMessage)) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    fail(`adoption generator did not fail closed for ${label}`);
  }
}

function fail(message) {
  console.error(`[rails-adopt-generator] ERROR: ${message}`);
  process.exit(1);
}
