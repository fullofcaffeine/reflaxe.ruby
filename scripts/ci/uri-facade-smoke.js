#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "uri_facade");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function fail(message) {
  console.error(`[uri-facade] ERROR: ${message}`);
  process.exit(1);
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

for (const path of ["std/ruby/URI.hx", "std/ruby/URIValue.hx"]) {
  const source = readFileSync(join(root, path), "utf8");
  for (const forbidden of [/\bDynamic\b/, /\bAny\b/, /\buntyped\b/, /\bcast\b/, /__ruby__/, /#if\s+ruby/]) {
    if (forbidden.test(source)) fail(`${path} widens the typed native boundary with ${forbidden}`);
  }
}

rmSync(outputDir, { force: true, recursive: true });
const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) fail("unable to find vendored Reflaxe source");

run("haxe", [
  "-D",
  `ruby_output=${outputDir}`,
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  join(root, "test", "uri_facade", "src_haxe"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "-main",
  "Main",
]);

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  if (!existsSync(join(outputDir, file))) fail(`expected generated Ruby file missing: ${file}`);
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
if ((runRuby.match(/require "uri"/g) ?? []).length !== 1) {
  fail('run.rb must contain exactly one deduplicated require "uri"');
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /URI\.parse\("https:\/\/user:pass@example\.com:8443\/app\/items\?q=hello%20world#top"\)/,
  /parsed(?:__hx\d+)?\.scheme\(\)/,
  /parsed(?:__hx\d+)?\.hierarchical\?\(\)/,
  /parsed(?:__hx\d+)?\.absolute\?\(\)/,
  /parsed(?:__hx\d+)?\.relative\?\(\)/,
  /parsed(?:__hx\d+)?\.merge\("\.\.\/api\?q=1"\)\.to_s\(\)/,
  /\.route_to\("https:\/\/example\.com\/app\/assets\/logo\.svg"\)\.to_s\(\)/,
  /\.route_from\("https:\/\/example\.com\/app\/views\/index"\)\.to_s\(\)/,
  /URI\.join\("https:\/\/example\.com\/app\/", "\.\.\/assets\/logo\.svg"\)\.to_s\(\)/,
  /URI\.encode_www_form_component\("a b\+c"\)/,
  /URI\.decode_www_form_component\("a\+b%2Bc"\)/,
  /URI\.encode_uri_component\("a b\/c\?d"\)/,
  /URI\.decode_uri_component\("a%20b%2Fc%3Fd"\)/,
  /mailto(?:__hx\d+)?\.path\(\)/,
  /mailto(?:__hx\d+)?\.opaque\(\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(mainRuby);
    fail(`expected direct URI shape missing from main.rb: ${expected}`);
  }
}
if (/Ruby::URI|HXRuby\.(?:uri|URI)|class URIValue/.test(mainRuby)) {
  fail("URI facade must dispatch directly without a generated wrapper or runtime helper");
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "https",
  "user:pass",
  "user",
  "pass",
  "example.com",
  "example.com",
  "8443",
  "/app/items",
  "q=hello%20world",
  "true",
  "top",
  "true",
  "true",
  "false",
  "https://user:pass@example.com:8443/app/items?q=hello%20world#top",
  "https://user:pass@example.com:8443/api?q=1",
  "../assets/logo.svg",
  "../assets/logo.svg",
  "http://example.com/~user",
  "https://example.com/assets/logo.svg",
  "a+b%2Bc",
  "a b+c",
  "a%20b%2Fc%3Fd",
  "a b/c?d",
  "true",
  "dev@example.com",
  "false",
  "",
].join("\n");
if (actual !== expected) {
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  fail("runtime stdout mismatch");
}

console.log("[uri-facade] OK: typed facade compiles to direct URI calls and passes MRI runtime behavior");
