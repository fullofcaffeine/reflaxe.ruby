#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "unitstd_ruby");
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

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile upstream unitstd Ruby parity lane through Reflaxe.");
  process.exit(1);
}

for (const file of [
  "e_reg.rb",
  "haxe/ds/enum_value_map.rb",
  "haxe/ds/int_map.rb",
  "haxe/ds/object_map.rb",
  "haxe/ds/string_map.rb",
  "haxe/ds/vector.rb",
  "haxe/ds/vector/vector_impl.rb",
  "haxe/macro/expr_def.rb",
  "haxe/io/fp_helper.rb",
  "haxe/rtti/rtti.rb",
  "haxe/xml/parser.rb",
  "haxe/zip/compress.rb",
  "haxe/zip/uncompress.rb",
  "hxruby/core.rb",
  "main.rb",
  "run.rb",
  "sys/io/file_input.rb",
  "sys/io/file_output.rb",
  "sys/io/file_seek.rb",
  "unit/spec/rtti_class1.rb",
  "unit/spec/rtti_class2.rb",
  "unit/spec/rtti_class3.rb",
  "unit/spec/c.rb",
  "xml.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
if (actual !== "unitstd-ruby ok\n") {
  console.error("unitstd-ruby stdout mismatch");
  console.error(`expected: ${JSON.stringify("unitstd-ruby ok\n")}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
const eRegRuby = readFileSync(join(outputDir, "e_reg.rb"), "utf8");
const enumValueMapRuby = readFileSync(join(outputDir, "haxe", "ds", "enum_value_map.rb"), "utf8");
const intMapRuby = readFileSync(join(outputDir, "haxe", "ds", "int_map.rb"), "utf8");
const objectMapRuby = readFileSync(join(outputDir, "haxe", "ds", "object_map.rb"), "utf8");
const vectorRuby = readFileSync(join(outputDir, "haxe", "ds", "vector.rb"), "utf8");
const vectorImplRuby = readFileSync(join(outputDir, "haxe", "ds", "vector", "vector_impl.rb"), "utf8");
const exprDefRuby = readFileSync(join(outputDir, "haxe", "macro", "expr_def.rb"), "utf8");
const fpHelperRuby = readFileSync(join(outputDir, "haxe", "io", "fp_helper.rb"), "utf8");
const rttiRuby = readFileSync(join(outputDir, "haxe", "rtti", "rtti.rb"), "utf8");
const xmlParserRuby = readFileSync(join(outputDir, "haxe", "xml", "parser.rb"), "utf8");
const zipCompressRuby = readFileSync(join(outputDir, "haxe", "zip", "compress.rb"), "utf8");
const zipUncompressRuby = readFileSync(join(outputDir, "haxe", "zip", "uncompress.rb"), "utf8");
const fileOutputRuby = readFileSync(join(outputDir, "sys", "io", "file_output.rb"), "utf8");
const fileSeekRuby = readFileSync(join(outputDir, "sys", "io", "file_seek.rb"), "utf8");
const rttiClassRuby = readFileSync(join(outputDir, "unit", "spec", "rtti_class1.rb"), "utf8");
const stringMapRuby = readFileSync(join(outputDir, "haxe", "ds", "string_map.rb"), "utf8");
const typeFixtureRuby = readFileSync(join(outputDir, "unit", "spec", "c.rb"), "utf8");
const xmlRuby = readFileSync(join(outputDir, "xml.rb"), "utf8");
for (const expectedShape of [
  "StringBuf.new()",
  ".chr(Encoding::UTF_8)",
  "HXRuby.string_substr(",
  ".tap { ii_min = ii_min + 1 }",
]) {
  if (!mainRuby.includes(expectedShape)) {
    console.error(`Expected generated unitstd Ruby shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of ["0x100000000", "<< (32.to_i & 31)", ">> (1.to_i & 31)"]) {
  if (!mainRuby.includes(expectedShape)) {
    console.error(`Expected direct Int32 wrap/shift lowering missing: ${expectedShape}`);
    process.exit(1);
  }
}
if (mainRuby.includes("Haxe::Int32::Int32Impl.")) {
  console.error("Int32 parity should remain direct Ruby Integer arithmetic, not a boxed generated wrapper.");
  process.exit(1);
}
for (const expectedShape of [
  '[value].pack("e")',
  'packed.unpack1("l<")',
  'packed.byteslice(4, 4).unpack1("l<")',
  '[low, high].pack("l<l<")',
  'packed.unpack1("E")',
]) {
  if (!fpHelperRuby.includes(expectedShape)) {
    console.error(`Expected typed direct FPHelper binary shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of [
  'rtti = HXRuby.reflect_field(c, "__rtti")',
  "x = ::Xml.parse(rtti).first_element()",
  "Haxe::Rtti::XmlParser.new().process_element(x)",
]) {
  if (!rttiRuby.includes(expectedShape)) {
    console.error(`Expected upstream haxe.rtti.Rtti shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of [
  '{instance: ["f"], static: ["__rtti", "v"]}',
  '@rtti = "<class path=\\"unit.spec.RttiClass1\\"',
  '<f public=\\"1\\" set=\\"method\\"',
]) {
  if (!rttiClassRuby.includes(expectedShape)) {
    console.error(`Expected @:rtti class metadata shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of ["@element = 0", "@document = 6"]) {
  if (!xmlRuby.includes(expectedShape)) {
    console.error(`Expected typed Xml static initializer shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
if (xmlRuby.includes("XmlType.element")) {
  console.error("Xml enum-abstract constants should lower to their retained typed values, not runtime XmlType calls.");
  process.exit(1);
}
for (const expectedShape of ["h = Haxe::Ds::StringMap.new()", "doc = ::Xml.create_document()"]) {
  if (!xmlParserRuby.includes(expectedShape)) {
    console.error(`Expected absolute/core Xml parser shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const [label, source] of [
  ["StringMap", stringMapRuby],
  ["IntMap", intMapRuby],
]) {
  for (const expectedShape of ["self.data = {}", "hash[key] = value"]) {
    if (!source.includes(expectedShape)) {
      console.error(`Expected direct Ruby Hash ${label} shape missing: ${expectedShape}`);
      process.exit(1);
    }
  }
}
for (const expectedShape of ["self.data = {}.compare_by_identity", "hash[key] = value"]) {
  if (!objectMapRuby.includes(expectedShape)) {
    console.error(`Expected identity-backed ObjectMap shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of [
  "class EnumValueMap < Haxe::Ds::BalancedTree",
  "d = (Type.enum_index(k1) - Type.enum_index(k2))",
  "return self.compare_args(p1, p2)",
]) {
  if (!enumValueMapRuby.includes(expectedShape)) {
    console.error(`Expected portable EnumValueMap shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of [
  "# Haxe abstract haxe.ds.Vector has no Ruby runtime body.",
  "if src.equal?(dest)",
  "dest[(dest_pos +",
  "src[(src_pos +",
]) {
  const source = expectedShape.startsWith("# Haxe abstract") ? vectorRuby : vectorImplRuby;
  if (!source.includes(expectedShape)) {
    console.error(`Expected native-array Vector shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
if (!/HXRuby\.array_resize\(this1[^,]*, 3\)/.test(mainRuby)
  || !/Assert\.is_false\([^\n]+\.equal\?\([^\n]+\), "upstream unitstd haxe\/ds\/Vector\.unit\.hx/.test(mainRuby)) {
  console.error("Expected Vector resize and identity-equality lowering is missing from the upstream lane.");
  process.exit(1);
}
if (mainRuby.includes("VectorImpl.new(")) {
  console.error("Vector values should remain native Ruby arrays, not boxed VectorImpl instances.");
  process.exit(1);
}
for (const [label, source, packing, operation] of [
  ["Compress", zipCompressRuby, 'input = s.get_data().pack("C*")', "Zlib::Deflate.deflate(input, level)"],
  ["Uncompress", zipUncompressRuby, 'input = src.get_data().pack("C*")', "Zlib::Inflate.inflate(input)"],
]) {
  for (const expectedShape of ['require "zlib"', packing, operation]) {
    if (!source.includes(expectedShape)) {
      console.error(`Expected direct Ruby Zlib ${label} shape missing: ${expectedShape}`);
      process.exit(1);
    }
  }
}
for (const expectedShape of [
  "Sys::Io::FileOutput.new(::File.open(",
  'fw.write_string("apple\\n")',
  ".seek(7, Sys::Io::FileSeek.seek_begin())",
]) {
  if (!mainRuby.includes(expectedShape)) {
    console.error(`Expected direct upstream sys.io.File shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of [
  "class Sys",
  "module Io",
  "class FileOutput < Haxe::Io::Output",
  "self.handle.write(bytes.get_data().slice(pos, len).pack('C*'))",
]) {
  if (!fileOutputRuby.includes(expectedShape)) {
    console.error(`Expected sys.io.FileOutput carrier shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of ["module FileSeek", "def self.seek_begin()", 'SeekBegin.new("SeekBegin", 0)']) {
  if (!fileSeekRuby.includes(expectedShape)) {
    console.error(`Expected sys.io.FileSeek carrier shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of [
  "Regexp.new(pattern, flags)",
  "def self.expand_replacement(by, match)",
  "def match_sub(s, pos, len = -1)",
]) {
  if (!eRegRuby.includes(expectedShape)) {
    console.error(`Expected generated EReg Ruby shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
if (mainRuby.includes("String.from_char_code")) {
  console.error("Generated unitstd Ruby should lower String.fromCharCode directly, not patch Ruby String.");
  process.exit(1);
}
for (const expectedShape of [
  '"haxe.macro.ExprDef"',
  '{name: "EBreak", index: 19, method: :e_break, arity: 0}',
]) {
  if (!exprDefRuby.includes(expectedShape)) {
    console.error(`Expected generated haxe.macro.ExprDef shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of [
  "def self.__hx_fields()",
  '{instance: ["func", "prop", "v"], static: ["staticFunc", "staticProp", "staticVar"]}',
]) {
  if (!typeFixtureRuby.includes(expectedShape)) {
    console.error(`Expected generated Type fixture metadata missing: ${expectedShape}`);
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
      "reflaxe_ruby_profile=portable",
      "-D",
      "reflaxe_runtime",
      "-D",
      "no-utf16",
      "-cp",
      join(root, "src"),
      "-cp",
      join(root, "test", "unitstd_ruby", "src_haxe"),
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
