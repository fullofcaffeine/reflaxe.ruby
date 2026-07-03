#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const sourceDir = join(root, "test", ".generated", "runtime_usage_src");
const outputDir = join(root, "test", ".generated", "runtime_usage");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

const allowedHelpers = new Set([
  "array_filter",
  "array_index_of",
  "array_insert",
  "array_join",
  "array_last_index_of",
  "array_map",
  "array_remove",
  "array_resize",
  "array_slice",
  "array_sort",
  "array_splice",
  "enum_eq",
  "enum_index",
  "enum_parameters",
  "enum_tag",
  "is_of_type",
  "iterator",
  "key_value_iterator",
  "math_binary",
  "math_divide",
  "math_fceil",
  "math_ffloor",
  "math_fround",
  "math_max",
  "math_min",
  "math_pow",
  "math_round",
  "math_unary",
  "method",
  "native_iterator",
  "parse_float",
  "parse_int",
  "reflect_call_method",
  "reflect_compare",
  "reflect_compare_methods",
  "reflect_copy",
  "reflect_delete_field",
  "reflect_field",
  "reflect_fields",
  "reflect_get_property",
  "reflect_has_field",
  "reflect_is_enum_value",
  "reflect_is_function",
  "reflect_is_object",
  "reflect_make_var_args",
  "reflect_set_field",
  "reflect_set_property",
  "string_char_at",
  "string_char_code_at",
  "string_compare",
  "string_index_of",
  "string_last_index_of",
  "string_split",
  "string_substr",
  "string_substring",
  "string_tools_fast_code_at",
  "string_tools_is_eof",
  "string_tools_is_space",
  "string_tools_lpad",
  "string_tools_rpad",
  "string_utf16_key_value_units",
  "string_utf16_units",
  "stringify",
  "type_all_enums",
  "type_class_fields",
  "type_class_name",
  "type_create_empty_instance",
  "type_create_enum",
  "type_create_enum_index",
  "type_create_instance",
  "type_enum_constructs",
  "type_enum_name",
  "type_get_class",
  "type_get_enum",
  "type_get_super_class",
  "type_instance_fields",
  "type_resolve_class",
  "type_resolve_enum",
  "typeof",
]);

const removedHelpers = new Set([
  "active_record_group_count",
  "active_record_projection",
  "array_contains",
  "array_copy",
  "array_push",
  "array_reverse",
  "hex",
  "html_escape",
  "html_unescape",
  "string_tools_replace",
  "url_decode",
  "url_encode",
]);

checkRuntimeAllowlist();
checkNoRuntimeFixture();

function checkRuntimeAllowlist() {
  const findings = [];
  for (const relativeFile of listFiles(join(root, "src")).concat(listFiles(join(root, "std")))) {
    if (!relativeFile.endsWith(".hx")) {
      continue;
    }
    const fullPath = join(root, relativeFile);
    const source = readFileSync(fullPath, "utf8");
    collectMatches(source, /hxrubyCall\("([A-Za-z0-9_?!]+)"/g, relativeFile, findings);
    collectMatches(source, /HXRuby\.([A-Za-z0-9_?!]+)/g, relativeFile, findings);
    collectMatches(source, /HXRuby::([A-Za-z0-9_?!]+)/g, relativeFile, findings);
  }
  const violations = findings.filter((finding) => !allowedHelpers.has(finding.helper) || removedHelpers.has(finding.helper));
  if (violations.length > 0) {
    console.error("[runtime-usage] Unexpected HXRuby helper references:");
    for (const violation of violations) {
      console.error(`  ${violation.file}: ${violation.helper}`);
    }
    console.error("Add a semantic reason and update scripts/ci/runtime-usage-check.js only if the helper is strictly necessary.");
    process.exit(1);
  }
}

function collectMatches(source, regex, file, findings) {
  for (const match of source.matchAll(regex)) {
    findings.push({ file, helper: match[1] });
  }
}

function checkNoRuntimeFixture() {
  rmSync(sourceDir, { force: true, recursive: true });
  rmSync(outputDir, { force: true, recursive: true });
  mkdirSync(sourceDir, { recursive: true });
  writeFileSync(join(sourceDir, "Main.hx"), [
    "class Main {",
    "\tpublic static function main():Void {",
    "\t\tvar answer:Int = 40 + 2;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  if (!compileWithFirstAvailableReflaxe()) {
    console.error("[runtime-usage] Unable to compile no-runtime fixture through Reflaxe.");
    process.exit(1);
  }

  assertMissing(join(outputDir, "hxruby", "core.rb"), "trivial output should not emit hxruby/core.rb");
  assertFileDoesNotContain(join(outputDir, "run.rb"), 'require_relative "hxruby/core"');
  for (const file of listFiles(outputDir)) {
    if (file.endsWith(".rb")) {
      assertFileDoesNotContain(join(root, file), "HXRuby.");
      assertFileDoesNotContain(join(root, file), "HXRuby::");
    }
  }

  const result = run("ruby", [join(outputDir, "run.rb")]);
  if (result.stdout !== "") {
    console.error("[runtime-usage] no-runtime fixture should not print output.");
    console.error(`actual: ${JSON.stringify(result.stdout)}`);
    process.exit(1);
  }
}

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
      "--macro",
      "haxe.macro.Compiler.keep(\"Main\")",
      "--dce",
      "full",
      "-main",
      "Main",
    ], { allowFailure: true });
    if (result.status === 0) {
      return true;
    }
  }
  return false;
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

function assertMissing(path, message) {
  if (existsSync(path)) {
    console.error(`[runtime-usage] ${message}: ${path}`);
    process.exit(1);
  }
}

function assertFileDoesNotContain(path, needle) {
  const content = readFileSync(path, "utf8");
  if (content.includes(needle)) {
    console.error(`[runtime-usage] Unexpected ${JSON.stringify(needle)} in ${path}`);
    process.exit(1);
  }
}

function listFiles(path) {
  const out = [];
  if (!existsSync(path)) {
    return out;
  }
  for (const entry of readdirSync(path, { withFileTypes: true })) {
    const fullPath = join(path, entry.name);
    if (entry.isDirectory()) {
      out.push(...listFiles(fullPath));
    } else {
      out.push(fullPath.slice(root.length + 1));
    }
  }
  return out;
}
