#!/usr/bin/env node

const { readdirSync, readFileSync } = require("node:fs");
const { join, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");

const requiredDocs = [
  "docs/railshx-sql-string-policy.md",
  "docs/railshx-typed-api-production-gap-audit.md",
  "docs/railshx-escape-hatch-security-audit.md",
  "AGENTS.md",
];

for (const relative of requiredDocs) {
  const content = readFileSync(join(root, relative), "utf8");
  for (const expected of [
    "typed",
    "checked",
    "escape",
  ]) {
    if (!content.toLowerCase().includes(expected)) {
      fail(`${relative} must mention ${expected} string/SQL policy class.`);
    }
  }
}

const policy = readFileSync(join(root, "docs", "railshx-sql-string-policy.md"), "utf8");
for (const expected of [
  "Typed default",
  "Checked literal",
  "Explicit escape hatch",
  "haxe.ruby-bjv.10",
  "haxe.ruby-bjv.4.1",
  "npm run test:sql-string-policy",
]) {
  if (!policy.includes(expected)) {
    fail(`SQL/string policy doc missing required content: ${expected}`);
  }
}

const canonicalRoots = [
  join(root, "examples", "active_record_model"),
  join(root, "examples", "todoapp_rails"),
];
const rawQueryPattern = /\.(where|rewhere|order|reorder|select|group|having|from|joins)\s*\(\s*["'`]/;

for (const file of hxFiles(canonicalRoots)) {
  const content = readFileSync(file, "utf8");
  const lines = content.split(/\r?\n/);
  lines.forEach((line, index) => {
    if (rawQueryPattern.test(line) && !line.includes("railshx:allow-raw-sql-example")) {
      fail(`${relativePath(file)}:${index + 1} uses a raw SQL/string query fragment. Use typed refs/builders or an explicit audited escape hatch.`);
    }
  });
}

function hxFiles(roots) {
  const out = [];
  for (const rootDir of roots) {
    collect(rootDir, out);
  }
  return out;
}

function collect(dir, out) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) {
      collect(path, out);
    } else if (entry.isFile() && entry.name.endsWith(".hx")) {
      out.push(path);
    }
  }
}

function relativePath(path) {
  return path.slice(root.length + 1);
}

function fail(message) {
  console.error(`[sql-string-policy] ${message}`);
  process.exit(1);
}
