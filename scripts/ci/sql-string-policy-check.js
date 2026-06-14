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
    rejectRawQueryLine(file, line, index + 1);
  });
}

for (const relative of [
  "docs/railshx-sql-string-policy.md",
  "docs/railshx-query-guide.md",
  "examples/active_record_model/README.md",
  "examples/todoapp_rails/README.md",
]) {
  scanMarkdownCodeFences(join(root, relative));
}

const audit = readFileSync(join(root, "docs", "railshx-escape-hatch-security-audit.md"), "utf8");
for (const escapeName of [
  "@:railsAllowRawErb",
  "Template.external",
  "Lock.custom",
  "externalTables",
]) {
  if (!audit.includes(escapeName)) {
    fail(`Escape hatch audit must document ${escapeName}.`);
  }
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

function scanMarkdownCodeFences(file) {
  const lines = readFileSync(file, "utf8").split(/\r?\n/);
  let inFence = false;
  let fenceLanguage = "";
  lines.forEach((line, index) => {
    const fence = line.match(/^```(\S*)/);
    if (fence) {
      inFence = !inFence;
      fenceLanguage = inFence ? fence[1].toLowerCase() : "";
      return;
    }
    if (inFence && ["haxe", "hx", "ruby", "rb"].includes(fenceLanguage)) {
      rejectRawQueryLine(file, line, index + 1);
    }
  });
}

function rejectRawQueryLine(file, line, lineNumber) {
  if (rawQueryPattern.test(line) && !line.includes("railshx:allow-raw-sql-example")) {
    fail(`${relativePath(file)}:${lineNumber} uses a raw SQL/string query fragment. Use typed refs/builders or an explicit audited escape hatch.`);
  }
}

function relativePath(path) {
  return path.slice(root.length + 1);
}

function fail(message) {
  console.error(`[sql-string-policy] ${message}`);
  process.exit(1);
}
