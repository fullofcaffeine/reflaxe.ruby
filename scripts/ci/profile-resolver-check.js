#!/usr/bin/env node

const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");

function runHaxe(args) {
  return spawnSync("haxe", [
    "-cp",
    join(root, "src"),
    "-cp",
    join(root, "test", "profile"),
    "-main",
    "ProfileResolverMacroMain",
    "--interp",
    ...args,
  ], {
    cwd: root,
    encoding: "utf8",
  });
}

const passCases = [
  { name: "default ruby_first", expected: "ruby_first", args: [] },
  { name: "profile ruby_first", expected: "ruby_first", args: ["-D", "reflaxe_ruby_profile=ruby_first"] },
  { name: "legacy profile idiomatic", expected: "ruby_first", args: ["-D", "reflaxe_ruby_profile=idiomatic"] },
  { name: "profile portable", expected: "portable", args: ["-D", "reflaxe_ruby_profile=portable"] },
  { name: "ruby_first define", expected: "ruby_first", args: ["-D", "ruby_first"] },
  { name: "legacy ruby_idiomatic define", expected: "ruby_first", args: ["-D", "ruby_idiomatic"] },
  { name: "ruby_portable define", expected: "portable", args: ["-D", "ruby_portable"] },
  {
    name: "ruby_first plus legacy idiomatic is compatible",
    expected: "ruby_first",
    args: ["-D", "ruby_first", "-D", "ruby_idiomatic"],
  },
];

for (const testCase of passCases) {
  const result = runHaxe([
    "--macro",
    `ProfileResolverMacroMain.assertProfile("${testCase.expected}")`,
    ...testCase.args,
  ]);
  if (result.status !== 0) {
    process.stderr.write(`[profile-resolver] ${testCase.name} failed\n`);
    process.stderr.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
}

const failCases = [
  {
    name: "ruby_first conflicts with portable",
    args: ["-D", "ruby_first", "-D", "ruby_portable"],
    message: "Conflicting Ruby profile defines",
  },
  {
    name: "invalid profile reports accepted values",
    args: ["-D", "reflaxe_ruby_profile=metal"],
    message: "expected ruby_first|portable",
  },
];

for (const testCase of failCases) {
  const result = runHaxe([
    "--macro",
    'ProfileResolverMacroMain.assertProfile("ruby_first")',
    ...testCase.args,
  ]);
  const output = `${result.stdout}\n${result.stderr}`;
  if (result.status === 0 || !output.includes(testCase.message)) {
    process.stderr.write(`[profile-resolver] ${testCase.name} did not fail as expected\n`);
    process.stderr.write(output);
    process.exit(1);
  }
}

console.log("[profile-resolver] OK");
