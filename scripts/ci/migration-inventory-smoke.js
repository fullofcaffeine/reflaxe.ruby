#!/usr/bin/env node

"use strict";

const { createHash } = require("node:crypto");
const { existsSync, lstatSync, mkdirSync, readdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const generatedRoot = join(root, "test", ".generated", "migration_inventory");

rmSync(generatedRoot, { force: true, recursive: true });
mkdirSync(generatedRoot, { recursive: true });

// These fixtures protect the report-only boundary. Ruby source is input data:
// discovery can describe it, but must never load, require, or execute it.
const safeRoot = fixtureRoot("safe");
const safeSource = [
  "# Historical reason retained in Rails-owned source.",
  "class AddStatusToWidgets < ActiveRecord::Migration[7.1]",
  "  def change",
  '    add_column :widgets, :status, :string, default: "pending", null: false',
  '    add_index :widgets, :status, name: "index_widgets_on_status"',
  "  end",
  "end",
  "",
].join("\n");
writeMigration(safeRoot, "20260824000000_add_status_to_widgets.rb", safeSource);
const maliciousSource = [
  'File.write("test/.generated/migration_inventory/EXECUTED", "bad")',
  "class UnsafeMigration < ActiveRecord::Migration[7.1]",
  "  disable_ddl_transaction!",
  "  def change",
  '    execute "UPDATE widgets SET status = \'bad\'"',
  "  end",
  "end",
  "",
].join("\n");
writeMigration(safeRoot, "20260824000001_unsafe_migration.rb", maliciousSource);
const unsupportedCallSource = [
  "class RunSqlMigration < ActiveRecord::Migration[7.1]",
  "  def change",
  '    execute "UPDATE widgets SET status = \'legacy\'"',
  "  end",
  "end",
  "",
].join("\n");
writeMigration(safeRoot, "20260824000002_run_sql_migration.rb", unsupportedCallSource);
const magicCommentSource = [
  "# frozen_string_literal: true",
  "class MagicCommentMigration < ActiveRecord::Migration[7.1]",
  "  def change",
  '    add_column :widgets, :code, :string',
  "  end",
  "end",
  "",
].join("\n");
writeMigration(safeRoot, "20260824000003_magic_comment_migration.rb", magicCommentSource);
const transactionSource = [
  "class ConcurrentIndexMigration < ActiveRecord::Migration[7.1]",
  "  disable_ddl_transaction!",
  "  def change",
  '    add_index :widgets, :status, name: "index_widgets_on_status"',
  "  end",
  "end",
  "",
].join("\n");
writeMigration(safeRoot, "20260824000004_concurrent_index_migration.rb", transactionSource);

const safeTreeBefore = treeSnapshot(safeRoot);
const safeResult = discover(safeRoot);
expectIncludes(safeResult.stdout, [
  "[rails:adopt:migrations] db/migrate",
  "migration: 20260824000000 db/migrate/20260824000000_add_status_to_widgets.rb class=AddStatusToWidgets owner=rails",
  `sha256=${sha256(safeSource)}`,
  "version=7.1 transaction=default body=change unsupported=none",
  "migration: 20260824000001 db/migrate/20260824000001_unsafe_migration.rb class=UnsafeMigration owner=rails",
  `sha256=${sha256(maliciousSource)}`,
  "version=7.1 transaction=disabled body=change unsupported=receiver_call@1:0",
  "migration: 20260824000002 db/migrate/20260824000002_run_sql_migration.rb class=RunSqlMigration owner=rails",
  "version=7.1 transaction=default body=change unsupported=call_execute@3:4",
  "migration: 20260824000003 db/migrate/20260824000003_magic_comment_migration.rb class=MagicCommentMigration owner=rails",
  "version=7.1 transaction=default body=change unsupported=magic_comment@1:0 comments=1",
  "migration: 20260824000004 db/migrate/20260824000004_concurrent_index_migration.rb class=ConcurrentIndexMigration owner=rails",
  "version=7.1 transaction=disabled body=change unsupported=disable_ddl_transaction@2:2",
]);
if (existsSync(join(generatedRoot, "EXECUTED"))) {
  fail("migration discovery executed hostile Ruby source");
}
if (treeSnapshot(safeRoot) !== safeTreeBefore) {
  fail("migration discovery changed its input tree");
}

const linkRoot = fixtureRoot("symlink");
const outsideSource = join(generatedRoot, "outside.rb");
writeFileSync(outsideSource, safeSource);
symlinkSync(outsideSource, join(linkRoot, "db", "migrate", "20260824000002_linked.rb"));
expectFailure(linkRoot, "must be a regular file and not a symbolic link");

const linkedRoot = join(generatedRoot, "linked_root");
const linkedMigrationDirectory = join(generatedRoot, "linked_migrations");
mkdirSync(join(linkedRoot, "db"), { recursive: true });
mkdirSync(linkedMigrationDirectory, { recursive: true });
writeFileSync(join(linkedMigrationDirectory, "20260824000007_outside.rb"), safeSource);
symlinkSync(linkedMigrationDirectory, join(linkedRoot, "db", "migrate"));
expectFailure(linkedRoot, "db/migrate must be a real directory and not a symbolic link");

const nonRegularRoot = fixtureRoot("non_regular");
mkdirSync(join(nonRegularRoot, "db", "migrate", "20260824000006_directory.rb"));
expectFailure(nonRegularRoot, "must be a regular file and not a symbolic link");

const oversizedRoot = fixtureRoot("oversized");
writeMigration(oversizedRoot, "20260824000003_oversized.rb", `#${"x".repeat((1024 * 1024) + 1)}\n`);
expectFailure(oversizedRoot, "exceeds the 1048576-byte migration inventory limit");

const nulRoot = fixtureRoot("nul");
writeMigration(nulRoot, "20260824000004_nul.rb", Buffer.from("class NulMigration\0 < ActiveRecord::Migration[7.1]\nend\n"));
expectFailure(nulRoot, "contains a NUL byte");

const invalidUtf8Root = fixtureRoot("invalid_utf8");
writeMigration(invalidUtf8Root, "20260824000005_invalid_utf8.rb", Buffer.from([0x63, 0x6c, 0x61, 0x73, 0x73, 0x20, 0xff, 0x0a]));
expectFailure(invalidUtf8Root, "is not valid UTF-8");

console.log("[migration-inventory] OK");

function fixtureRoot(name) {
  const output = join(generatedRoot, name);
  mkdirSync(join(output, "db", "migrate"), { recursive: true });
  return output;
}

function writeMigration(output, name, content) {
  writeFileSync(join(output, "db", "migrate", name), content);
}

function discover(output) {
  const result = spawnSync("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "adopt.rb"),
    "--output",
    output,
    "--migrations",
    "--discover",
  ], { cwd: root, encoding: "utf8" });
  if (result.status !== 0) {
    process.stdout.write(result.stdout || "");
    process.stderr.write(result.stderr || "");
    fail(`migration discovery failed with status ${result.status}`);
  }
  return result;
}

function expectFailure(output, expected) {
  const result = spawnSync("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "adopt.rb"),
    "--output",
    output,
    "--migrations",
    "--discover",
  ], { cwd: root, encoding: "utf8" });
  const combined = `${result.stdout || ""}\n${result.stderr || ""}`;
  if (result.status === 0 || !combined.includes(expected)) {
    process.stdout.write(result.stdout || "");
    process.stderr.write(result.stderr || "");
    fail(`expected migration discovery failure containing ${JSON.stringify(expected)}`);
  }
}

function expectIncludes(actual, expectedValues) {
  for (const expected of expectedValues) {
    if (!actual.includes(expected)) {
      process.stdout.write(actual);
      fail(`migration inventory output missing ${JSON.stringify(expected)}`);
    }
  }
}

function sha256(content) {
  return createHash("sha256").update(content).digest("hex");
}

function treeSnapshot(directory, relative = "") {
  const entries = [];
  for (const name of readdirSync(join(directory, relative)).sort()) {
    const childRelative = join(relative, name);
    const child = join(directory, childRelative);
    const stat = lstatSync(child);
    if (stat.isDirectory()) {
      entries.push(`directory:${childRelative}`);
      entries.push(treeSnapshot(directory, childRelative));
    } else if (stat.isFile()) {
      entries.push(`file:${childRelative}:${sha256(readFileSync(child))}`);
    } else {
      entries.push(`other:${childRelative}`);
    }
  }
  return entries.filter(Boolean).join("\n");
}

function fail(message) {
  console.error(`[migration-inventory] ERROR: ${message}`);
  process.exit(1);
}
