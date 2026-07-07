#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "migration_generator");
const collisionDir = join(root, "test", ".generated", "migration_generator_collision");
const timestampCollisionDir = join(root, "test", ".generated", "migration_generator_timestamp_collision");
const classCollisionDir = join(root, "test", ".generated", "migration_generator_class_collision");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
rmSync(collisionDir, { force: true, recursive: true });
rmSync(timestampCollisionDir, { force: true, recursive: true });
rmSync(classCollisionDir, { force: true, recursive: true });

mkdirSync(join(outputDir, "db"), { recursive: true });
writeFileSync(join(outputDir, "db", "schema.rb"), [
  "ActiveRecord::Schema[7.2].define(version: 2026_01_01_010100) do",
  '  create_table "todos", force: :cascade do |t|',
  '    t.string "title", null: false',
  '    t.boolean "completed"',
  '    t.decimal "price", precision: 10, scale: 2',
  '    t.bigint "user_id"',
  '    t.index ["completed"], name: "index_todos_on_completed"',
  "  end",
  "end",
  "",
].join("\n"));

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "CreateTodos",
  "title:string!",
  "completed:boolean:index",
  "price:decimal{10,2}",
  "user:references",
  "--timestamp",
  "20260101010101",
  "--migration-version",
  "8.1",
  "--output",
  outputDir,
]);

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddStatusToTodos",
  "status:string:index",
  "--timestamp",
  "20260101010102",
  "--known-models",
  "models.Todo",
  "--output",
  outputDir,
]);

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "RemoveStatusFromTodos",
  "status:string",
  "--timestamp",
  "20260101010103",
  "--external-table",
  "todos",
  "--output",
  outputDir,
]);

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddPriorityToTodos",
  "priority:integer",
  "--timestamp",
  "20260101010109",
  "--from-schema",
  "db/schema.rb",
  "--output",
  outputDir,
]);

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "RemoveTitleFromTodos",
  "title:string!",
  "--timestamp",
  "20260101010110",
  "--from-schema",
  "db/schema.rb",
  "--output",
  outputDir,
]);

writeFileSync(join(outputDir, "src_haxe", "Main.hx"), [
  "import migrations.CreateTodos;",
  "import migrations.AddStatusToTodos;",
  "import migrations.RemoveStatusFromTodos;",
  "import migrations.AddPriorityToTodos;",
  "import migrations.RemoveTitleFromTodos;",
  "",
  "class Main {",
  "\tstatic function main() {",
  "\t\tvar create:Class<CreateTodos> = CreateTodos;",
  "\t\tvar add:Class<AddStatusToTodos> = AddStatusToTodos;",
  "\t\tvar remove:Class<RemoveStatusFromTodos> = RemoveStatusFromTodos;",
  "\t\tvar schemaAdd:Class<AddPriorityToTodos> = AddPriorityToTodos;",
  "\t\tvar schemaRemove:Class<RemoveTitleFromTodos> = RemoveTitleFromTodos;",
  "\t\tSys.println(create != null && add != null && remove != null && schemaAdd != null && schemaRemove != null);",
  "\t}",
  "}",
  "",
].join("\n"));
mkdirSync(join(outputDir, "src_haxe", "models"), { recursive: true });
writeFileSync(join(outputDir, "src_haxe", "models", "Todo.hx"), [
  "package models;",
  "",
  "@:railsModel(\"todos\")",
  "class Todo extends rails.active_record.Base<Todo> {",
  "\t@:railsColumn public var title:String;",
  "\t@:railsColumn public var completed:Bool;",
  "\t@:railsColumn public var price:Float;",
  "\t@:railsColumn public var userId:Int;",
  "}",
  "",
].join("\n"));

assertIncludes("src_haxe/migrations/CreateTodos.hx", [
  "class CreateTodos extends Migration",
  'timestamp: "20260101010101"',
  'version: "8.1"',
  'CreateTable("todos", {',
  'Column("title", StringColumn({nullable: false})),',
  'Column("completed", BooleanColumn({})),',
  'Index(["completed"], {}),',
  'Column("price", DecimalColumn({precision: 10, scale: 2})),',
  'Reference("user", {foreignKey: true}),',
]);
assertIncludes("src_haxe/migrations/AddStatusToTodos.hx", [
  'knownModels: ["models.Todo"]',
  'AddColumn("todos", "status", StringColumn({}))',
  'AddIndex("todos", "status", {})',
]);
assertIncludes("src_haxe/migrations/RemoveStatusFromTodos.hx", [
  'externalTables: ["todos"]',
  'Reversible([RemoveColumn("todos", "status")], [AddColumn("todos", "status", StringColumn({}))])',
]);
assertIncludes("src_haxe/migrations/AddPriorityToTodos.hx", [
  'models: []',
  'AddColumn("todos", "priority", IntegerColumn({}))',
]);
assertNotIncludes("src_haxe/migrations/AddPriorityToTodos.hx", [
  "externalTables",
  "knownModels",
]);
assertIncludes("src_haxe/migrations/RemoveTitleFromTodos.hx", [
  'models: []',
  'Reversible([RemoveColumn("todos", "title")], [AddColumn("todos", "title", StringColumn({nullable: false}))])',
]);
assertNotIncludes("src_haxe/migrations/RemoveTitleFromTodos.hx", [
  "externalTables",
  "knownModels",
]);

const manifest = JSON.parse(readFileSync(join(outputDir, ".railshx", "manifest.json"), "utf8"));
for (const output of [
  "src_haxe/migrations/CreateTodos.hx",
  "src_haxe/migrations/AddStatusToTodos.hx",
  "src_haxe/migrations/RemoveStatusFromTodos.hx",
  "src_haxe/migrations/AddPriorityToTodos.hx",
  "src_haxe/migrations/RemoveTitleFromTodos.hx",
]) {
  const entry = manifest.outputs.find((candidate) => candidate.output === output);
  if (!entry || entry.kind !== "haxe_migration_source" || entry.source !== "hxruby:migration" || !entry.sha256) {
    console.error(`Migration generator manifest missing expected ${output} entry.`);
    process.exit(1);
  }
}

if (!compileWithFirstAvailableReflaxe(join(outputDir, "ruby"))) {
  console.error("Unable to compile generated migration Haxe through Reflaxe.");
  process.exit(1);
}

assertIncludes("ruby/db/migrate/20260101010101_create_todos.rb", [
  "class CreateTodos < ActiveRecord::Migration[8.1]",
  "create_table :todos do |t|",
  "t.string :title, null: false",
  "t.boolean :completed",
  "t.index [:completed]",
  "t.decimal :price, precision: 10, scale: 2",
  "t.references :user, foreign_key: true",
]);
assertIncludes("ruby/db/migrate/20260101010103_remove_status_from_todos.rb", [
  "reversible do |dir|",
  "dir.up do",
  "remove_column :todos, :status",
  "dir.down do",
  "add_column :todos, :status, :string",
]);
assertIncludes("ruby/db/migrate/20260101010109_add_priority_to_todos.rb", [
  "add_column :todos, :priority, :integer",
]);
assertIncludes("ruby/db/migrate/20260101010110_remove_title_from_todos.rb", [
  "remove_column :todos, :title",
  "add_column :todos, :title, :string, null: false",
]);

const pretend = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddRankToTodos",
  "rank:integer",
  "--timestamp",
  "20260101010104",
  "--output",
  outputDir,
  "--pretend",
]);
if (!pretend.stdout.includes("class AddRankToTodos extends Migration") || existsSync(join(outputDir, "src_haxe", "migrations", "AddRankToTodos.hx"))) {
  console.error("Migration generator --pretend did not print without writing.");
  process.exit(1);
}

const schemaUnknownTable = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddFlagToTodoss",
  "flag:boolean",
  "--timestamp",
  "20260101010111",
  "--from-schema",
  "db/schema.rb",
  "--output",
  outputDir,
], { allowFailure: true });
if (schemaUnknownTable.status === 0 || !schemaUnknownTable.stderr.includes('--from-schema db/schema.rb does not contain table "todoss"')) {
  process.stdout.write(schemaUnknownTable.stdout);
  process.stderr.write(schemaUnknownTable.stderr);
  console.error("Migration generator did not reject --from-schema unknown table.");
  process.exit(1);
}

const schemaExistingColumn = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddTitleToTodos",
  "title:string",
  "--timestamp",
  "20260101010112",
  "--from-schema",
  "db/schema.rb",
  "--output",
  outputDir,
], { allowFailure: true });
if (schemaExistingColumn.status === 0 || !schemaExistingColumn.stderr.includes('--from-schema db/schema.rb already contains column "title" on table "todos"')) {
  process.stdout.write(schemaExistingColumn.stdout);
  process.stderr.write(schemaExistingColumn.stderr);
  console.error("Migration generator did not reject --from-schema add of an existing column.");
  process.exit(1);
}

const schemaMissingColumn = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "RemoveMissingFromTodos",
  "missing:string",
  "--timestamp",
  "20260101010113",
  "--from-schema",
  "db/schema.rb",
  "--output",
  outputDir,
], { allowFailure: true });
if (schemaMissingColumn.status === 0 || !schemaMissingColumn.stderr.includes('--from-schema db/schema.rb does not contain column "missing" on table "todos"')) {
  process.stdout.write(schemaMissingColumn.stdout);
  process.stderr.write(schemaMissingColumn.stderr);
  console.error("Migration generator did not reject --from-schema remove of an unknown column.");
  process.exit(1);
}

writeFileSync(join(outputDir, "db", "structure.sql"), [
  "CREATE TABLE todos (",
  "  id bigint PRIMARY KEY,",
  "  title varchar(255) NOT NULL",
  ");",
  "",
].join("\n"));
const schemaSql = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddScoreToTodos",
  "score:integer",
  "--timestamp",
  "20260101010114",
  "--from-schema",
  "db/structure.sql",
  "--output",
  outputDir,
], { allowFailure: true });
if (schemaSql.status === 0 || !schemaSql.stderr.includes("SQL/structure.sql schema adoption is not supported")) {
  process.stdout.write(schemaSql.stdout);
  process.stderr.write(schemaSql.stderr);
  console.error("Migration generator did not reject SQL --from-schema input.");
  process.exit(1);
}

run("ruby", [
  "-e",
  `require 'fileutils'; FileUtils.mkdir_p(${JSON.stringify(join(collisionDir, "db", "migrate"))}); File.write(${JSON.stringify(join(collisionDir, "db", "migrate", "20260101010105_add_name_to_users.rb"))}, "# hand-written migration\\n")`,
]);
const collision = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddNameToUsers",
  "name:string",
  "--timestamp",
  "20260101010105",
  "--output",
  collisionDir,
], { allowFailure: true });
if (collision.status === 0 || !collision.stderr.includes("already exists and is not RailsHx-owned")) {
  process.stdout.write(collision.stdout);
  process.stderr.write(collision.stderr);
  console.error("Migration generator did not protect a non-owned db/migrate collision.");
  process.exit(1);
}

run("ruby", [
  "-e",
  `require 'fileutils'; FileUtils.mkdir_p(${JSON.stringify(join(timestampCollisionDir, "db", "migrate"))}); File.write(${JSON.stringify(join(timestampCollisionDir, "db", "migrate", "20260101010106_existing_name.rb"))}, "class ExistingName < ActiveRecord::Migration[7.1]\\nend\\n")`,
]);
const timestampCollision = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddAgeToUsers",
  "age:integer",
  "--timestamp",
  "20260101010106",
  "--output",
  timestampCollisionDir,
], { allowFailure: true });
if (timestampCollision.status === 0 || !timestampCollision.stderr.includes("Migration timestamp 20260101010106 is already used by db/migrate/20260101010106_existing_name.rb")) {
  process.stdout.write(timestampCollision.stdout);
  process.stderr.write(timestampCollision.stderr);
  console.error("Migration generator did not reject an existing timestamp with a different filename.");
  process.exit(1);
}

run("ruby", [
  "-e",
  `require 'fileutils'; FileUtils.mkdir_p(${JSON.stringify(join(classCollisionDir, "db", "migrate"))}); File.write(${JSON.stringify(join(classCollisionDir, "db", "migrate", "20260101010107_existing_email.rb"))}, "class AddEmailToUsers < ActiveRecord::Migration[7.1]\\nend\\n")`,
]);
const classCollision = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddEmailToUsers",
  "email:string",
  "--timestamp",
  "20260101010108",
  "--output",
  classCollisionDir,
], { allowFailure: true });
if (classCollision.status === 0 || !classCollision.stderr.includes("Migration class AddEmailToUsers is already used by db/migrate/20260101010107_existing_email.rb")) {
  process.stdout.write(classCollision.stdout);
  process.stderr.write(classCollision.stderr);
  console.error("Migration generator did not reject an existing migration class.");
  process.exit(1);
}

const unsafePath = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "migration.rb"),
  "AddNameToUsers",
  "name:string",
  "--haxe-dir",
  "../outside",
  "--output",
  outputDir,
], { allowFailure: true });
if (unsafePath.status === 0 || !unsafePath.stderr.includes("--haxe-dir must be a safe relative path")) {
  process.stdout.write(unsafePath.stdout);
  process.stderr.write(unsafePath.stderr);
  console.error("Migration generator did not reject unsafe --haxe-dir.");
  process.exit(1);
}

function assertIncludes(relativeFile, expectedLines) {
  const content = readFileSync(join(outputDir, relativeFile), "utf8");
  for (const expected of expectedLines) {
    if (!content.includes(expected)) {
      console.error(`${relativeFile} missing expected line: ${expected}`);
      process.exit(1);
    }
  }
}

function assertNotIncludes(relativeFile, unexpectedLines) {
  const content = readFileSync(join(outputDir, relativeFile), "utf8");
  for (const unexpected of unexpectedLines) {
    if (content.includes(unexpected)) {
      console.error(`${relativeFile} contained unexpected line: ${unexpected}`);
      process.exit(1);
    }
  }
}

function compileWithFirstAvailableReflaxe(rubyOutput) {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${rubyOutput}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
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
    ], { allowFailure: true });
    if (result.status === 0) {
      return result;
    }
  }
  return null;
}

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
