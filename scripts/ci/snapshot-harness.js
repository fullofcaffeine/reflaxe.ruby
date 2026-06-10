#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const update = process.env.UPDATE_SNAPSHOTS === "1";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

const cases = [
  { name: "core_subset", files: ["hxruby/core.rb", "main.rb", "run.rb"] },
  { name: "class_members", files: ["hxruby/core.rb", "counter.rb", "main.rb", "run.rb"] },
  { name: "lambda_values", files: ["hxruby/core.rb", "main.rb", "run.rb"] },
  { name: "enum_adt", files: ["hxruby/core.rb", "hxruby/data_define.rb", "maybe_int.rb", "main.rb", "run.rb"] },
  { name: "switch_cases", files: ["hxruby/core.rb", "hxruby/data_define.rb", "color.rb", "main.rb", "run.rb"] },
  { name: "exception_flow", files: ["hxruby/core.rb", "hxruby/hx_exception.rb", "main.rb", "run.rb"] },
  { name: "stdlib_mvp", files: ["hxruby/core.rb", "main.rb", "run.rb"] },
  { name: "require_metadata", files: ["hxruby/core.rb", "main.rb", "run.rb"] },
  { name: "native_mapping", files: ["hxruby/core.rb", "main.rb", "run.rb"] },
  { name: "ruby_call_shapes", files: ["hxruby/core.rb", "main.rb", "run.rb"] },
  { name: "ruby_interop", files: ["hxruby/core.rb", "main.rb", "run.rb"] },
  {
    name: "rails_autoload",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/admin/todo_item.rb",
      "app/haxe_gen/hxruby/core.rb",
      "app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "active_record_model",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/models/todo.rb",
      "app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "action_controller_params",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/controllers/todos_controller.rb",
      "app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "todoapp_rails",
    defines: ["reflaxe_ruby_rails"],
    extraClassPaths: ["examples/todoapp_rails/src_haxe"],
    files: [
      "app/haxe_gen/models/todo.rb",
      "app/haxe_gen/models/user.rb",
      "app/haxe_gen/controllers/todos_controller.rb",
      "app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
];

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for snapshots.");
  process.exit(1);
}

for (const testCase of cases) {
  const outputDir = join(root, "test", ".generated", "snapshots", testCase.name);
  const stabilityOutputDir = join(root, "test", ".generated", "snapshots_stability", testCase.name);
  rmSync(outputDir, { force: true, recursive: true });
  rmSync(stabilityOutputDir, { force: true, recursive: true });
  compileCase(testCase, outputDir);

  for (const relativeFile of testCase.files) {
    compareSnapshot(testCase.name, relativeFile, outputDir);
  }

  if (!update) {
    compileCase(testCase, stabilityOutputDir);
    for (const relativeFile of testCase.files) {
      compareStableOutput(testCase.name, relativeFile, outputDir, stabilityOutputDir);
    }
  }
}

function compileCase(testCase, outputDir) {
  const args = [
    "-D",
    `ruby_output=${outputDir}`,
    "-D",
    "reflaxe_runtime",
    "-D",
    "reflaxe_ruby_strict_examples",
  ];
  for (const define of testCase.defines ?? []) {
    args.push("-D", define);
  }
  for (const extraClassPath of testCase.extraClassPaths ?? []) {
    args.push("-cp", join(root, extraClassPath));
  }
  args.push(
    "-cp",
    join(root, "src"),
    "-cp",
    join(root, "examples", testCase.name),
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  );
  run("haxe", args);
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

function compareSnapshot(caseName, relativeFile, outputDir) {
  const actualPath = join(outputDir, relativeFile);
  const snapshotPath = join(root, "test", "snapshots", "m1", caseName, relativeFile);
  if (!existsSync(actualPath)) {
    console.error(`Missing generated snapshot file: ${actualPath}`);
    process.exit(1);
  }

  const actual = readFileSync(actualPath, "utf8");
  assertStableText(`${caseName}/${relativeFile}`, actual);
  if (update) {
    mkdirSync(dirname(snapshotPath), { recursive: true });
    writeFileSync(snapshotPath, actual);
    return;
  }

  if (!existsSync(snapshotPath)) {
    console.error(`Missing snapshot: ${snapshotPath}`);
    console.error("Run UPDATE_SNAPSHOTS=1 npm run test:snapshots to create it.");
    process.exit(1);
  }

  const expected = readFileSync(snapshotPath, "utf8");
  if (actual !== expected) {
    console.error(`Snapshot mismatch: ${caseName}/${relativeFile}`);
    console.error("Run UPDATE_SNAPSHOTS=1 npm run test:snapshots if this change is intentional.");
    process.exit(1);
  }
}

function compareStableOutput(caseName, relativeFile, firstOutputDir, secondOutputDir) {
  const firstPath = join(firstOutputDir, relativeFile);
  const secondPath = join(secondOutputDir, relativeFile);
  if (!existsSync(secondPath)) {
    console.error(`Missing second-pass generated snapshot file: ${secondPath}`);
    process.exit(1);
  }

  const first = readFileSync(firstPath, "utf8");
  const second = readFileSync(secondPath, "utf8");
  assertStableText(`${caseName}/${relativeFile} second pass`, second);
  if (first !== second) {
    console.error(`Non-deterministic snapshot output: ${caseName}/${relativeFile}`);
    process.exit(1);
  }
}

function assertStableText(label, content) {
  if (content.includes("\r")) {
    console.error(`Snapshot contains CRLF/CR line endings: ${label}`);
    process.exit(1);
  }
  if (!content.endsWith("\n")) {
    console.error(`Snapshot is missing trailing newline: ${label}`);
    process.exit(1);
  }
  if (content.includes(root)) {
    console.error(`Snapshot contains workspace-local absolute path: ${label}`);
    process.exit(1);
  }
}
