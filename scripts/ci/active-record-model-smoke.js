#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "active_record_model");
const invalidSourceDir = join(root, "test", ".generated", "active_record_model_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "active_record_model_invalid_out");
const invalidWhereSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_src");
const invalidWhereOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_out");
const invalidWhereTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_where_type_src");
const invalidWhereTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_where_type_out");
const invalidRelationWhereSourceDir = join(root, "test", ".generated", "active_record_model_invalid_relation_where_src");
const invalidRelationWhereOutputDir = join(root, "test", ".generated", "active_record_model_invalid_relation_where_out");
const invalidAssignedRelationSourceDir = join(root, "test", ".generated", "active_record_model_invalid_assigned_relation_src");
const invalidAssignedRelationOutputDir = join(root, "test", ".generated", "active_record_model_invalid_assigned_relation_out");
const invalidAssociationSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_src");
const invalidAssociationOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_out");
const invalidMissingFkSourceDir = join(root, "test", ".generated", "active_record_model_invalid_missing_fk_src");
const invalidMissingFkOutputDir = join(root, "test", ".generated", "active_record_model_invalid_missing_fk_out");
const invalidFkTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_fk_type_src");
const invalidFkTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_fk_type_out");
const invalidAssociationTargetSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_target_src");
const invalidAssociationTargetOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_target_out");
const invalidAssociationOptionSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_option_src");
const invalidAssociationOptionOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_option_out");
const invalidAssociationDependentSourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_dependent_src");
const invalidAssociationDependentOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_dependent_out");
const invalidAssociationForeignKeySourceDir = join(root, "test", ".generated", "active_record_model_invalid_association_foreign_key_src");
const invalidAssociationForeignKeyOutputDir = join(root, "test", ".generated", "active_record_model_invalid_association_foreign_key_out");
const invalidValidationTargetSourceDir = join(root, "test", ".generated", "active_record_model_invalid_validation_target_src");
const invalidValidationTargetOutputDir = join(root, "test", ".generated", "active_record_model_invalid_validation_target_out");
const invalidValidationOptionSourceDir = join(root, "test", ".generated", "active_record_model_invalid_validation_option_src");
const invalidValidationOptionOutputDir = join(root, "test", ".generated", "active_record_model_invalid_validation_option_out");
const invalidValidationShapeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_validation_shape_src");
const invalidValidationShapeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_validation_shape_out");
const invalidValidationTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_validation_type_src");
const invalidValidationTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_validation_type_out");
const invalidEnumShapeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_enum_shape_src");
const invalidEnumShapeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_enum_shape_out");
const invalidEnumValueSourceDir = join(root, "test", ".generated", "active_record_model_invalid_enum_value_src");
const invalidEnumValueOutputDir = join(root, "test", ".generated", "active_record_model_invalid_enum_value_out");
const invalidEnumTypeSourceDir = join(root, "test", ".generated", "active_record_model_invalid_enum_type_src");
const invalidEnumTypeOutputDir = join(root, "test", ".generated", "active_record_model_invalid_enum_type_out");
const invalidCallbackStaticSourceDir = join(root, "test", ".generated", "active_record_model_invalid_callback_static_src");
const invalidCallbackStaticOutputDir = join(root, "test", ".generated", "active_record_model_invalid_callback_static_out");
const invalidCallbackArgsSourceDir = join(root, "test", ".generated", "active_record_model_invalid_callback_args_src");
const invalidCallbackArgsOutputDir = join(root, "test", ".generated", "active_record_model_invalid_callback_args_out");
const invalidCallbackNameSourceDir = join(root, "test", ".generated", "active_record_model_invalid_callback_name_src");
const invalidCallbackNameOutputDir = join(root, "test", ".generated", "active_record_model_invalid_callback_name_out");
const invalidCallbackFieldSourceDir = join(root, "test", ".generated", "active_record_model_invalid_callback_field_src");
const invalidCallbackFieldOutputDir = join(root, "test", ".generated", "active_record_model_invalid_callback_field_out");
const invalidFindSourceDir = join(root, "test", ".generated", "active_record_model_invalid_find_src");
const invalidFindOutputDir = join(root, "test", ".generated", "active_record_model_invalid_find_out");
const invalidFindBySourceDir = join(root, "test", ".generated", "active_record_model_invalid_find_by_src");
const invalidFindByOutputDir = join(root, "test", ".generated", "active_record_model_invalid_find_by_out");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
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
rmSync(invalidWhereSourceDir, { force: true, recursive: true });
rmSync(invalidWhereOutputDir, { force: true, recursive: true });
rmSync(invalidWhereTypeSourceDir, { force: true, recursive: true });
rmSync(invalidWhereTypeOutputDir, { force: true, recursive: true });
rmSync(invalidRelationWhereSourceDir, { force: true, recursive: true });
rmSync(invalidRelationWhereOutputDir, { force: true, recursive: true });
rmSync(invalidAssignedRelationSourceDir, { force: true, recursive: true });
rmSync(invalidAssignedRelationOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationOutputDir, { force: true, recursive: true });
rmSync(invalidMissingFkSourceDir, { force: true, recursive: true });
rmSync(invalidMissingFkOutputDir, { force: true, recursive: true });
rmSync(invalidFkTypeSourceDir, { force: true, recursive: true });
rmSync(invalidFkTypeOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationTargetSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationTargetOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationOptionSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationOptionOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationDependentSourceDir, { force: true, recursive: true });
rmSync(invalidAssociationDependentOutputDir, { force: true, recursive: true });
rmSync(invalidAssociationForeignKeySourceDir, { force: true, recursive: true });
rmSync(invalidAssociationForeignKeyOutputDir, { force: true, recursive: true });
rmSync(invalidValidationTargetSourceDir, { force: true, recursive: true });
rmSync(invalidValidationTargetOutputDir, { force: true, recursive: true });
rmSync(invalidValidationOptionSourceDir, { force: true, recursive: true });
rmSync(invalidValidationOptionOutputDir, { force: true, recursive: true });
rmSync(invalidValidationShapeSourceDir, { force: true, recursive: true });
rmSync(invalidValidationShapeOutputDir, { force: true, recursive: true });
rmSync(invalidValidationTypeSourceDir, { force: true, recursive: true });
rmSync(invalidValidationTypeOutputDir, { force: true, recursive: true });
rmSync(invalidEnumShapeSourceDir, { force: true, recursive: true });
rmSync(invalidEnumShapeOutputDir, { force: true, recursive: true });
rmSync(invalidEnumValueSourceDir, { force: true, recursive: true });
rmSync(invalidEnumValueOutputDir, { force: true, recursive: true });
rmSync(invalidEnumTypeSourceDir, { force: true, recursive: true });
rmSync(invalidEnumTypeOutputDir, { force: true, recursive: true });
rmSync(invalidCallbackStaticSourceDir, { force: true, recursive: true });
rmSync(invalidCallbackStaticOutputDir, { force: true, recursive: true });
rmSync(invalidCallbackArgsSourceDir, { force: true, recursive: true });
rmSync(invalidCallbackArgsOutputDir, { force: true, recursive: true });
rmSync(invalidCallbackNameSourceDir, { force: true, recursive: true });
rmSync(invalidCallbackNameOutputDir, { force: true, recursive: true });
rmSync(invalidCallbackFieldSourceDir, { force: true, recursive: true });
rmSync(invalidCallbackFieldOutputDir, { force: true, recursive: true });
rmSync(invalidFindSourceDir, { force: true, recursive: true });
rmSync(invalidFindOutputDir, { force: true, recursive: true });
rmSync(invalidFindBySourceDir, { force: true, recursive: true });
rmSync(invalidFindByOutputDir, { force: true, recursive: true });

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile active_record_model through Reflaxe.");
  process.exit(1);
}

for (const file of [
  "app/haxe_gen/models/todo.rb",
  "app/haxe_gen/models/user.rb",
  "app/haxe_gen/models/audit_log.rb",
  "app/haxe_gen/main.rb",
  "config/initializers/hxruby_autoload.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected ActiveRecord output file missing: ${fullPath}`);
    process.exit(1);
  }
}

const todoRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "todo.rb"), "utf8");
for (const expected of [
  'require "active_record"',
  "module Models",
  "class Todo < ::ApplicationRecord",
  'self.table_name = "todos"',
  "def self.__hx_rails_schema()",
  'table_name: "todos"',
  "timestamps: true",
  "{name: :id, haxe_name: \"id\", ruby_name: \"id\", haxe_type: \"Int\", rails_type: :bigint, nullable: false, default: nil, primary_key: true, index: false, unique: false, db_type: :bigint}",
  "{name: :title, haxe_name: \"title\", ruby_name: \"title\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "{name: :completed, haxe_name: \"completed\", ruby_name: \"completed\", haxe_type: \"Bool\", rails_type: :boolean, nullable: false, default: false, primary_key: false, index: false, unique: false, db_type: nil}",
  "{name: :status, haxe_name: \"status\", ruby_name: \"status\", haxe_type: \"String\", rails_type: :string, nullable: false, default: \"open\", primary_key: false, index: false, unique: false, db_type: nil}",
  "{name: :notes, haxe_name: \"notes\", ruby_name: \"notes\", haxe_type: \"String\", rails_type: :text, nullable: true, default: nil, primary_key: false, index: false, unique: false, db_type: :text}",
  "{name: :external_id, haxe_name: \"externalId\", ruby_name: \"external_id\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: false, unique: true, db_type: nil}",
  "{name: :user_id, haxe_name: \"userId\", ruby_name: \"user_id\", haxe_type: \"Int\", rails_type: :integer, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  'belongs_to :user, optional: false, foreign_key: "user_id", inverse_of: :todos',
  'enum :status, {open: "open", done: "done"}',
  "# haxe column id: Int",
  "# haxe column title: String",
  "# haxe column completed: Bool",
  "# haxe column status: String",
  "# haxe column notes: Null",
  "# haxe column external_id: String",
  "# haxe column user_id: Int",
  "def self.incomplete()",
  "Models::Todo.where(completed: false)",
  "before_validation :normalize_title",
  "after_commit :publish_lifecycle_event",
  "def normalize_title()",
  "def publish_lifecycle_event()",
]) {
  if (!todoRuby.includes(expected)) {
    console.error(`ActiveRecord model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const userRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "user.rb"), "utf8");
for (const expected of [
  "class User < ::ApplicationRecord",
  'self.table_name = "users"',
  "def self.__hx_rails_schema()",
  'table_name: "users"',
  "timestamps: true",
  "{name: :id, haxe_name: \"id\", ruby_name: \"id\", haxe_type: \"Int\", rails_type: :bigint, nullable: false, default: nil, primary_key: true, index: false, unique: false, db_type: :bigint}",
  "{name: :name, haxe_name: \"name\", ruby_name: \"name\", haxe_type: \"String\", rails_type: :string, nullable: false, default: nil, primary_key: false, index: true, unique: false, db_type: nil}",
  "has_many :todos, dependent: :destroy, inverse_of: :user",
  "# haxe column id: Int",
  "# haxe column name: String",
]) {
  if (!userRuby.includes(expected)) {
    console.error(`ActiveRecord user model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

for (const unexpected of ["def self.where", "def self.create"]) {
  if (todoRuby.includes(unexpected)) {
    console.error(`Typed interop stub should not be emitted into model Ruby: ${unexpected}`);
    process.exit(1);
  }
}

const auditLogRuby = readFileSync(join(outputDir, "app", "haxe_gen", "models", "audit_log.rb"), "utf8");
for (const expected of [
  "class AuditLog < ::ApplicationRecord",
  'self.table_name = "audit_logs"',
  "def self.__hx_rails_schema()",
  'table_name: "audit_logs"',
  "timestamps: false",
  "{name: :event_count, haxe_name: \"eventCount\", ruby_name: \"event_count\", haxe_type: \"Int\", rails_type: :integer, nullable: false, default: 0, primary_key: false, index: false, unique: false, db_type: nil}",
]) {
  if (!auditLogRuby.includes(expected)) {
    console.error(`ActiveRecord inferred model output missing expected line: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "app", "haxe_gen", "main.rb"), "utf8");
for (const expected of [
  'Models::Todo.includes(:user).where(title: "ship", status: "open").where(completed: false).joins(:user).order(title: :asc).limit(10)',
  "Models::Todo.incomplete().includes(:user).limit(5)",
  'Models::User.includes(:todos).joins(:todos).where(name: "owner")',
  'Models::Todo.create(title: "ship", user_id: 1)',
  "Models::AuditLog.where(event_count: 1).order(event_count: :desc)",
  "Models::Todo.find(1)",
  'Models::Todo.find_by(external_id: "ship-1")',
  'Models::Todo.where(title: "ship").find_by(completed: false)',
  'Models::Todo.where(title: "assigned").order(title: :asc).limit(5)',
  'assigned__hx',
  'find_by(external_id: "assigned-1")',
  "first__hx",
  ".first()",
]) {
  if (!mainRuby.includes(expected)) {
    console.error(`ActiveRecord call shape missing from main.rb: ${expected}`);
    process.exit(1);
  }
}

expectInvalidColumnDefaultFailure();
expectInvalidWhereFieldFailure();
expectInvalidWhereValueTypeFailure();
expectInvalidRelationWhereFieldFailure();
expectInvalidAssignedRelationFieldFailure();
expectInvalidAssociationOwnerFailure();
expectInvalidMissingBelongsToForeignKeyFailure();
expectInvalidBelongsToForeignKeyTypeFailure();
expectInvalidAssociationTargetFailure();
expectInvalidAssociationOptionFailure();
expectInvalidAssociationDependentFailure();
expectInvalidAssociationForeignKeyFailure();
expectInvalidValidationTargetFailure();
expectInvalidValidationOptionFailure();
expectInvalidValidationShapeFailure();
expectInvalidValidationTypeFailure();
expectInvalidEnumShapeFailure();
expectInvalidEnumValueFailure();
expectInvalidEnumTypeFailure();
expectInvalidCallbackStaticFailure();
expectInvalidCallbackArgsFailure();
expectInvalidCallbackNameFailure();
expectInvalidCallbackFieldFailure();
expectInvalidFindValueTypeFailure();
expectInvalidFindByFieldFailure();

function compileWithFirstAvailableReflaxe() {
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
      join(root, "examples", "active_record_model"),
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
      return result;
    }
  }
  return null;
}

function expectInvalidWhereFieldFailure() {
  mkdirSync(invalidWhereSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereSourceDir,
    invalidWhereOutputDir,
    "Invalid ActiveRecord where field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidWhereValueTypeFailure() {
  mkdirSync(invalidWhereTypeSourceDir, { recursive: true });
  writeFileSync(join(invalidWhereTypeSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({completed: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidWhereTypeSourceDir,
    invalidWhereTypeOutputDir,
    "Invalid ActiveRecord where value type compiled successfully.",
    "String should be Null<Bool>"
  );
}

function expectInvalidRelationWhereFieldFailure() {
  mkdirSync(invalidRelationWhereSourceDir, { recursive: true });
  writeFileSync(join(invalidRelationWhereSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.where({title: \"ship\"}).where({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidRelationWhereSourceDir,
    invalidRelationWhereOutputDir,
    "Invalid ActiveRecord relation where field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidAssignedRelationFieldFailure() {
  mkdirSync(invalidAssignedRelationSourceDir, { recursive: true });
  writeFileSync(join(invalidAssignedRelationSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar relation = Todo.where({title: \"ship\"}).order(Todo.f.title.asc()).limit(10);",
    "\t\tvar bad = relation.where({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssignedRelationSourceDir,
    invalidAssignedRelationOutputDir,
    "Invalid assigned ActiveRecord relation where field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidAssociationOwnerFailure() {
  mkdirSync(invalidAssociationSourceDir, { recursive: true });
  writeFileSync(join(invalidAssociationSourceDir, "Main.hx"), [
    "import models.Todo;",
    "import models.User;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.includes(User.a.todos);",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationSourceDir,
    invalidAssociationOutputDir,
    "Invalid ActiveRecord association owner compiled successfully.",
    "Association<models.User"
  );
}

function expectInvalidMissingBelongsToForeignKeyFailure() {
  mkdirSync(join(invalidMissingFkSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidMissingFkSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.user == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidMissingFkSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "import models.User;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:belongsTo public var user:rails.ActiveRecord.BelongsTo<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidMissingFkSourceDir,
    invalidMissingFkOutputDir,
    "Invalid belongsTo without foreign key compiled successfully.",
    "@:belongsTo field user requires a @:railsColumn foreign key named userId"
  );
}

function expectInvalidBelongsToForeignKeyTypeFailure() {
  mkdirSync(join(invalidFkTypeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidFkTypeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.user == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidFkTypeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "import models.User;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var userId:String;",
    "\t@:belongsTo public var user:rails.ActiveRecord.BelongsTo<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidFkTypeSourceDir,
    invalidFkTypeOutputDir,
    "Invalid belongsTo foreign key type compiled successfully.",
    "@:belongsTo foreign key userId must be Int"
  );
}

function expectInvalidAssociationTargetFailure() {
  mkdirSync(join(invalidAssociationTargetSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationTargetSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.owner == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationTargetSourceDir, "invalid", "PlainOwner.hx"), [
    "package invalid;",
    "",
    "class PlainOwner {}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationTargetSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var ownerId:Int;",
    "\t@:belongsTo public var owner:rails.ActiveRecord.BelongsTo<PlainOwner>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationTargetSourceDir,
    invalidAssociationTargetOutputDir,
    "Invalid association target compiled successfully.",
    ":belongsTo target invalid.PlainOwner must be a @:railsModel class"
  );
}

function expectInvalidAssociationOptionFailure() {
  mkdirSync(join(invalidAssociationOptionSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationOptionSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.user == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationOptionSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "import models.User;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var userId:Int;",
    "\t@:belongsTo({magic: true}) public var user:rails.ActiveRecord.BelongsTo<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationOptionSourceDir,
    invalidAssociationOptionOutputDir,
    "Invalid association option compiled successfully.",
    "@:association unknown option magic"
  );
}

function expectInvalidAssociationDependentFailure() {
  mkdirSync(join(invalidAssociationDependentSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationDependentSourceDir, "Main.hx"), [
    "import invalid.BadUser;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadUser.associations.todos == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationDependentSourceDir, "invalid", "BadUser.hx"), [
    "package invalid;",
    "",
    "import models.Todo;",
    "",
    "@:railsModel(\"bad_users\")",
    "class BadUser extends rails.active_record.Base<BadUser> {",
    "\t@:hasMany({dependent: \"explode\"}) public var todos:rails.ActiveRecord.HasMany<Todo>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationDependentSourceDir,
    invalidAssociationDependentOutputDir,
    "Invalid association dependent value compiled successfully.",
    "@:association option dependent has unsupported value explode"
  );
}

function expectInvalidAssociationForeignKeyFailure() {
  mkdirSync(join(invalidAssociationForeignKeySourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidAssociationForeignKeySourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo.associations.user == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidAssociationForeignKeySourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "import models.User;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var userId:Int;",
    "\t@:belongsTo({foreignKey: \"ownerId\"}) public var user:rails.ActiveRecord.BelongsTo<User>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidAssociationForeignKeySourceDir,
    invalidAssociationForeignKeyOutputDir,
    "Invalid association foreign key compiled successfully.",
    "@:belongsTo field user requires a @:railsColumn foreign key named ownerId"
  );
}

function expectInvalidValidationTargetFailure() {
  mkdirSync(join(invalidValidationTargetSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidValidationTargetSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidValidationTargetSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:validates({presence: true})",
    "\tpublic var missingValidation:rails.ActiveRecord.Validation<String>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidValidationTargetSourceDir,
    invalidValidationTargetOutputDir,
    "Invalid validation target compiled successfully.",
    "@:validates target missing must match a @:railsColumn field"
  );
}

function expectInvalidValidationOptionFailure() {
  mkdirSync(join(invalidValidationOptionSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidValidationOptionSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidValidationOptionSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:validates({present: true})",
    "\tpublic var titleValidation:rails.ActiveRecord.Validation<String>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidValidationOptionSourceDir,
    invalidValidationOptionOutputDir,
    "Invalid validation option compiled successfully.",
    "@:validates unknown option present"
  );
}

function expectInvalidValidationShapeFailure() {
  mkdirSync(join(invalidValidationShapeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidValidationShapeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidValidationShapeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:validates({length: true})",
    "\tpublic var titleValidation:rails.ActiveRecord.Validation<String>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidValidationShapeSourceDir,
    invalidValidationShapeOutputDir,
    "Invalid validation option shape compiled successfully.",
    "@:validates option length must be an options object"
  );
}

function expectInvalidValidationTypeFailure() {
  mkdirSync(join(invalidValidationTypeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidValidationTypeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidValidationTypeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn public var title:String;",
    "\t@:validates({presence: true})",
    "\tpublic var titleValidation:rails.ActiveRecord.Validation<Int>;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidValidationTypeSourceDir,
    invalidValidationTypeOutputDir,
    "Invalid validation generic type compiled successfully.",
    "@:validates field titleValidation must use Validation<String> for target title"
  );
}

function expectInvalidEnumShapeFailure() {
  mkdirSync(join(invalidEnumShapeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidEnumShapeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidEnumShapeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn",
    "\t@:railsEnum(\"open\")",
    "\tpublic var status:String;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidEnumShapeSourceDir,
    invalidEnumShapeOutputDir,
    "Invalid enum shape compiled successfully.",
    "@:railsEnum expects one options object"
  );
}

function expectInvalidEnumValueFailure() {
  mkdirSync(join(invalidEnumValueSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidEnumValueSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidEnumValueSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn",
    "\t@:railsEnum({open: true})",
    "\tpublic var status:String;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidEnumValueSourceDir,
    invalidEnumValueOutputDir,
    "Invalid enum value compiled successfully.",
    "@:railsEnum value open must be a String or Int literal"
  );
}

function expectInvalidEnumTypeFailure() {
  mkdirSync(join(invalidEnumTypeSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidEnumTypeSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidEnumTypeSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsColumn",
    "\t@:railsEnum({open: \"open\"})",
    "\tpublic var status:Int;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidEnumTypeSourceDir,
    invalidEnumTypeOutputDir,
    "Invalid enum field type compiled successfully.",
    "@:railsEnum status values are String literals, so the field must be String"
  );
}

function expectInvalidCallbackStaticFailure() {
  mkdirSync(join(invalidCallbackStaticSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidCallbackStaticSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidCallbackStaticSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:beforeSave public static function normalizeTitle():Void {}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidCallbackStaticSourceDir,
    invalidCallbackStaticOutputDir,
    "Invalid static callback compiled successfully.",
    ":beforeSave callback methods must be instance methods"
  );
}

function expectInvalidCallbackArgsFailure() {
  mkdirSync(join(invalidCallbackArgsSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidCallbackArgsSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidCallbackArgsSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:beforeSave public function normalizeTitle(value:String):Void {}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidCallbackArgsSourceDir,
    invalidCallbackArgsOutputDir,
    "Invalid callback with args compiled successfully.",
    ":beforeSave callback methods must not declare arguments"
  );
}

function expectInvalidCallbackNameFailure() {
  mkdirSync(join(invalidCallbackNameSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidCallbackNameSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidCallbackNameSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:railsCallback(\"before_magic\") public function normalizeTitle():Void {}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidCallbackNameSourceDir,
    invalidCallbackNameOutputDir,
    "Invalid callback name compiled successfully.",
    "@:railsCallback unknown callback before_magic"
  );
}

function expectInvalidCallbackFieldFailure() {
  mkdirSync(join(invalidCallbackFieldSourceDir, "invalid"), { recursive: true });
  writeFileSync(join(invalidCallbackFieldSourceDir, "Main.hx"), [
    "import invalid.BadTodo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(BadTodo == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidCallbackFieldSourceDir, "invalid", "BadTodo.hx"), [
    "package invalid;",
    "",
    "@:railsModel(\"bad_todos\")",
    "class BadTodo extends rails.active_record.Base<BadTodo> {",
    "\t@:beforeSave public var title:String;",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidCallbackFieldSourceDir,
    invalidCallbackFieldOutputDir,
    "Invalid callback field compiled successfully.",
    ":beforeSave can only be used on model methods"
  );
}

function expectInvalidFindValueTypeFailure() {
  mkdirSync(invalidFindSourceDir, { recursive: true });
  writeFileSync(join(invalidFindSourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.find(\"nope\");",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidFindSourceDir,
    invalidFindOutputDir,
    "Invalid ActiveRecord find id type compiled successfully.",
    "String should be Int"
  );
}

function expectInvalidFindByFieldFailure() {
  mkdirSync(invalidFindBySourceDir, { recursive: true });
  writeFileSync(join(invalidFindBySourceDir, "Main.hx"), [
    "import models.Todo;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad = Todo.findBy({missing: \"nope\"});",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  expectInvalidCompile(
    invalidFindBySourceDir,
    invalidFindByOutputDir,
    "Invalid ActiveRecord findBy field compiled successfully.",
    "has extra field missing"
  );
}

function expectInvalidCompile(sourceDir, rubyOutputDir, successMessage, expectedDiagnostic) {
  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
    const result = run("haxe", [
      "-D",
      `ruby_output=${rubyOutputDir}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      join(root, "examples", "active_record_model"),
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
      console.error(successMessage);
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes(expectedDiagnostic)) {
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      console.error(`Invalid ActiveRecord compile failed without expected diagnostic: ${expectedDiagnostic}`);
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to find Reflaxe source for invalid ActiveRecord compile check.");
    process.exit(1);
  }
}

function expectInvalidColumnDefaultFailure() {
  mkdirSync(join(invalidSourceDir, "models"), { recursive: true });
  writeFileSync(join(invalidSourceDir, "Main.hx"), [
    "import models.BadModel;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar bad:BadModel = null;",
    "\t\tSys.println(bad == null);",
    "\t}",
    "}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "models", "BadModel.hx"), [
    "package models;",
    "",
    "@:railsModel",
    "class BadModel extends rails.active_record.Base<BadModel> {",
    "\t@:railsColumn({defaultValue: \"not_bool\"})",
    "\tpublic var enabled:Bool;",
    "}",
    "",
  ].join("\n"));

  let sawCandidate = false;
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    sawCandidate = true;
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
      invalidSourceDir,
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
      console.error("Expected invalid ActiveRecord column defaultValue compile to fail.");
      process.exit(1);
    }
    const output = `${result.stdout}\n${result.stderr}`;
    if (!output.includes("@:railsColumn defaultValue for Bool fields must be a Bool literal.")) {
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      console.error("Invalid ActiveRecord column defaultValue failed without the expected diagnostic.");
      process.exit(1);
    }
    return;
  }
  if (!sawCandidate) {
    console.error("Unable to find Reflaxe source for invalid ActiveRecord compile check.");
    process.exit(1);
  }
}
