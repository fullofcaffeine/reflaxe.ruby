#!/usr/bin/env node

const { readdirSync, readFileSync, statSync } = require("node:fs");
const { join, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const documentationPath = join(root, "docs", "compiler-metadata.md");
const scanRoots = [
  join(root, "src", "reflaxe", "ruby"),
  join(root, "std", "rails", "macros"),
];

function hxFiles(path) {
  if (statSync(path).isFile()) {
    return path.endsWith(".hx") ? [path] : [];
  }
  return readdirSync(path).flatMap((entry) => hxFiles(join(path, entry)));
}

function metadataTokens(content) {
  return [...content.matchAll(/:(ruby[A-Z][A-Za-z0-9_]*|rails(?:[A-Z_][A-Za-z0-9_]*))/g)].map((match) => `@:${match[1]}`);
}

const discovered = new Set(
  scanRoots.flatMap(hxFiles).flatMap((path) => metadataTokens(readFileSync(path, "utf8")))
);
const documented = new Set(metadataTokens(readFileSync(documentationPath, "utf8")));
const missing = [...discovered].filter((token) => !documented.has(token)).sort();

if (missing.length > 0) {
  console.error("Compiler metadata missing from docs/compiler-metadata.md:");
  for (const token of missing) {
    console.error(`- ${token}`);
  }
  process.exit(1);
}

console.log(`[compiler-metadata-docs] OK: ${discovered.size} compiler metadata tokens documented`);
