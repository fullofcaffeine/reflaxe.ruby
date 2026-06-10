#!/usr/bin/env node

const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const script = [
  `require ${JSON.stringify(join(root, "runtime", "hxruby", "core.rb"))}`,
  `require ${JSON.stringify(join(root, "runtime", "hxruby", "data_define.rb"))}`,
  `require ${JSON.stringify(join(root, "runtime", "hxruby", "hx_exception.rb"))}`,
  "Maybe = Data.define(:value, :__hx_tag, :__hx_index)",
  "v = Maybe.new(42, 'Some', 1)",
  "raise HxException.new(v) rescue (ex = $!)",
  "puts HXRuby.stringify(nil)",
  "puts HXRuby.enum_tag(ex.value)",
  "puts HXRuby.enum_index(ex.value)",
  "puts HXRuby.type_name(ex.value).empty? ? 'missing' : 'typed'",
].join("; ");

const result = spawnSync("ruby", ["-e", script], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});

if (result.status !== 0) {
  process.stdout.write(result.stdout);
  process.stderr.write(result.stderr);
  process.exit(result.status ?? 1);
}

const expected = "null\nSome\n1\ntyped\n";
if (result.stdout !== expected) {
  console.error("runtime core smoke mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(result.stdout)}`);
  process.exit(1);
}
