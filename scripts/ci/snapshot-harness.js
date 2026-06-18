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
    name: "ruby_extensions",
    files: [
      "hxruby/core.rb",
      "haxe_authored_class_methods.rb",
      "haxe_authored_decorated.rb",
      "haxe_module_post.rb",
      "haxe_only_library.rb",
      "haxe_owned_post.rb",
      "haxe_raw_backed_post.rb",
      "main.rb",
      "run.rb",
    ],
  },
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
      "app/haxe_gen/models/audit_log.rb",
      "app/haxe_gen/models/todo.rb",
      "app/haxe_gen/models/user.rb",
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
    name: "action_mailer",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/mailers/user_mailer.rb",
      "app/haxe_gen/views/welcome_email_html_view.rb",
      "app/haxe_gen/views/welcome_email_text_view.rb",
      "app/views/mailers/user_mailer/welcome.html.erb",
      "app/views/mailers/user_mailer/welcome.text.erb",
      "app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "active_job",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/jobs/retry_probe_job.rb",
      "app/haxe_gen/jobs/send_welcome_email_job.rb",
      "app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "active_storage",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/models/profile.rb",
      "app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "action_cable",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/channels/todos_channel.rb",
      "app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "components",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/main.rb",
      "app/haxe_gen/shared/card_slots.rb",
      "app/haxe_gen/views/component_card_view.rb",
      "app/haxe_gen/views/component_shell_view.rb",
      "app/views/components/_card.html.erb",
      "app/views/components/show.html.erb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "turbo_streams",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/main.rb",
      "app/haxe_gen/views/todo_row_view.rb",
      "app/views/todos/_todo.html.erb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "instrumentation",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "engine_plugin",
    defines: ["reflaxe_ruby_rails", "reflaxe_ruby_rails_output_root=engines/blog/app/haxe_gen"],
    files: [
      "engines/blog/app/haxe_gen/blog_engine/services/engine_greeting.rb",
      "engines/blog/app/haxe_gen/hxruby/core.rb",
      "engines/blog/app/haxe_gen/main.rb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "rails_interop_app",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "app/haxe_gen/controllers/mixed_controller.rb",
      "app/haxe_gen/services/typed_stats.rb",
      "app/haxe_gen/views/application_layout_view.rb",
      "app/haxe_gen/views/haxe_shell_view.rb",
      "app/haxe_gen/views/typed_widget_view.rb",
      "app/views/layouts/application.html.erb",
      "app/views/mixed/haxe_shell.html.erb",
      "app/views/typed_widgets/_summary.html.erb",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
  {
    name: "rails_routes_dsl",
    defines: ["reflaxe_ruby_rails"],
    files: [
      "config/routes.rb",
      ".railshx/routes.haxe.json",
    ],
  },
  {
    name: "todoapp_rails",
    defines: ["reflaxe_ruby_rails"],
    extraClassPaths: ["examples/todoapp_rails/src_haxe"],
    files: [
      "app/haxe_gen/models/todo.rb",
      "app/haxe_gen/models/user.rb",
      "app/haxe_gen/shared/component_slot.rb",
      "app/haxe_gen/shared/content_slot.rb",
      "app/haxe_gen/shared/css_class.rb",
      "app/haxe_gen/shared/data_attr.rb",
      "app/haxe_gen/shared/dom_id.rb",
      "app/haxe_gen/shared/href.rb",
      "app/haxe_gen/shared/meta_content.rb",
      "app/haxe_gen/shared/meta_name.rb",
      "app/haxe_gen/shared/selector.rb",
      "app/haxe_gen/shared/storage_key.rb",
      "app/haxe_gen/shared/todo_hooks.rb",
      "app/haxe_gen/controllers/todo_index_locals.rb",
      "app/haxe_gen/controllers/todos_controller.rb",
      "app/haxe_gen/controllers/chat_messages_controller.rb",
      "app/haxe_gen/migrations/create_chat_messages.rb",
      "app/haxe_gen/migrations/create_todos.rb",
      "app/haxe_gen/migrations/update_todos.rb",
      "app/haxe_gen/views/application_layout_view.rb",
      "app/haxe_gen/views/chat_panel_locals.rb",
      "app/haxe_gen/views/chat_panel_view.rb",
      "app/haxe_gen/views/todo_card_locals.rb",
      "app/haxe_gen/views/todo_card_view.rb",
      "app/haxe_gen/views/todo_composer_locals.rb",
      "app/haxe_gen/views/todo_composer_view.rb",
      "app/haxe_gen/views/todo_dashboard_view.rb",
      "app/haxe_gen/views/todo_form_locals.rb",
      "app/haxe_gen/views/todo_form_view.rb",
      "app/haxe_gen/views/todo_index_view.rb",
      "app/haxe_gen/views/todo_list_locals.rb",
      "app/haxe_gen/views/todo_list_view.rb",
      "app/haxe_gen/views/todo_summary_locals.rb",
      "app/haxe_gen/views/todo_summary_view.rb",
      "app/views/controllers/todos/index.html.erb",
      "app/views/controllers/todos/_card.html.erb",
      "app/views/controllers/todos/_chat_panel.html.erb",
      "app/views/controllers/todos/_composer.html.erb",
      "app/views/controllers/todos/_dashboard.html.erb",
      "app/views/controllers/todos/_list.html.erb",
      "app/views/controllers/todos/_summary.html.erb",
      "app/views/controllers/todos/_typed_form.html.erb",
      "app/views/layouts/application.html.erb",
      "db/migrate/20260101000000_create_todos.rb",
      "db/migrate/20260101000001_update_todos.rb",
      "db/migrate/20260101000003_create_chat_messages.rb",
      "test/generated/models/todo_haxe_test.rb",
      "app/haxe_gen/main.rb",
      "config/routes.rb",
      ".railshx/routes.haxe.json",
      "config/initializers/hxruby_autoload.rb",
      "run.rb",
    ],
  },
];

const routeGeneratorCases = [
  {
    name: "routes_generator",
    input: "test/fixtures/rails_routes/routes.txt",
    output: "src_haxe/routes/Routes.hx",
    files: ["src_haxe/routes/Routes.hx"],
    className: "Routes",
  },
  {
    name: "routes_generator_complex",
    input: "test/fixtures/rails_routes/complex_routes.txt",
    output: "src_haxe/routes/ComplexRoutes.hx",
    files: ["src_haxe/routes/ComplexRoutes.hx"],
    className: "ComplexRoutes",
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

for (const testCase of routeGeneratorCases) {
  const outputDir = join(root, "test", ".generated", "snapshots", testCase.name);
  const stabilityOutputDir = join(root, "test", ".generated", "snapshots_stability", testCase.name);
  rmSync(outputDir, { force: true, recursive: true });
  rmSync(stabilityOutputDir, { force: true, recursive: true });
  runRouteGeneratorCase(testCase, outputDir);

  for (const relativeFile of testCase.files) {
    compareSnapshot(testCase.name, relativeFile, outputDir);
  }

  if (!update) {
    runRouteGeneratorCase(testCase, stabilityOutputDir);
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

function runRouteGeneratorCase(testCase, outputDir) {
  run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "generate-routes.rb"),
    "--input",
    join(root, testCase.input),
    "--output",
    join(outputDir, testCase.output),
    "--class",
    testCase.className,
    "--root",
    outputDir,
  ]);
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
  const globalLookingTemp = content.match(/__hx\d{4,}/);
  if (globalLookingTemp) {
    console.error(
      `Snapshot contains global-looking Haxe temp suffix ${globalLookingTemp[0]}: ${label}`
    );
    console.error("Temp locals should use deterministic per-scope suffixes like __hx0.");
    process.exit(1);
  }
}
