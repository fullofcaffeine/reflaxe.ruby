#!/usr/bin/env node

const { existsSync, readdirSync, readFileSync, statSync } = require("node:fs");
const { join, relative, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const auditPath = join(root, "docs", "ruby-stdlib-parity-audit.json");
const manifestPath = join(root, "test", "upstream_unitstd", "manifest.json");
const referenceRoot = process.env.HAXE_RUBY_UNITSTD_REFERENCE
  ? resolve(process.env.HAXE_RUBY_UNITSTD_REFERENCE)
  : resolve(root, "..", "haxe.compilerdev.reference", "haxe", "tests", "unit", "src", "unitstd");

const allowedClassifications = new Set([
  "covered-ruby-override",
  "covered-upstream-fallback",
  "upstream-fallback-candidate",
  "ruby-override-needed",
  "unsupported-target-specific",
]);

const audit = JSON.parse(readFileSync(auditPath, "utf8"));
const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
const manifestByModule = new Map(manifest.modules.map((entry) => [entry.module, entry]));
const allowedUnitstdStatuses = new Set([...manifest.statusValues, "not-tracked"]);

failIf(audit.schemaVersion !== 1, "schemaVersion must be 1");
failIf(audit.referenceRoot !== manifest.referenceRoot, "referenceRoot must match test/upstream_unitstd/manifest.json");
failIf(audit.manifest !== "test/upstream_unitstd/manifest.json", "manifest path must point at the checked unitstd manifest");
failIf(!Array.isArray(audit.candidates), "candidates must be an array");

const modules = new Set();
let previousModule = "";
for (const candidate of audit.candidates) {
  failIf(!candidate.module || typeof candidate.module !== "string", "candidate module is required");
  failIf(modules.has(candidate.module), `duplicate candidate module: ${candidate.module}`);
  modules.add(candidate.module);

  failIf(previousModule && previousModule > candidate.module, `candidates must be sorted by module: ${candidate.module}`);
  previousModule = candidate.module;

  failIf(!allowedClassifications.has(candidate.classification), `invalid classification for ${candidate.module}: ${candidate.classification}`);
  failIf(!allowedUnitstdStatuses.has(candidate.unitstdStatus), `invalid unitstdStatus for ${candidate.module}: ${candidate.unitstdStatus}`);
  failIf(!candidate.next || typeof candidate.next !== "string", `next is required for ${candidate.module}`);
  failIf(!candidate.notes || typeof candidate.notes !== "string", `notes is required for ${candidate.module}`);

  const manifestEntry = manifestByModule.get(candidate.module);
  if (manifestEntry) {
    failIf(candidate.unitstdStatus !== manifestEntry.status, `unitstdStatus mismatch for ${candidate.module}: expected ${manifestEntry.status}`);
    if (manifestEntry.source) {
      failIf(candidate.source !== manifestEntry.source, `source mismatch for manifest module ${candidate.module}`);
    }
  } else if (candidate.unitstdStatus !== "not-tracked" && candidate.unitstdStatus !== "no-upstream-spec") {
    failIf(true, `${candidate.module} has unitstdStatus ${candidate.unitstdStatus} but is missing from manifest`);
  }

  if (candidate.unitstdStatus === "enabled" || candidate.unitstdStatus === "adapted") {
    failIf(!candidate.source, `covered unitstd candidate must record source: ${candidate.module}`);
  }

  if (candidate.classification === "covered-ruby-override") {
    failIf(!candidate.owner, `covered Ruby override must record owner: ${candidate.module}`);
  }
}

for (const manifestEntry of manifest.modules) {
  failIf(!modules.has(manifestEntry.module), `manifest module missing from audit: ${manifestEntry.module}`);
}

if (existsSync(referenceRoot)) {
  const sourceByModule = new Map();
  for (const file of walk(referenceRoot)) {
    const source = relative(referenceRoot, file).split("\\").join("/");
    const module = moduleNameForFixture(source);
    sourceByModule.set(module, source);
  }

  for (const [module, source] of sourceByModule) {
    failIf(!modules.has(module), `upstream unitstd fixture missing from audit: ${module} (${source})`);
    const candidate = audit.candidates.find((entry) => entry.module === module);
    failIf(candidate.source !== source, `upstream unitstd source mismatch for ${module}: expected ${source}`);
  }
}

function moduleNameForFixture(source) {
  return source
    .replace(/\.macro\.unit\.hx$/, "")
    .replace(/\.unit\.hx(?:\.disabled|\.no)?$/, "")
    .split("/")
    .join(".");
}

function walk(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) {
      walk(path, out);
    } else {
      out.push(path);
    }
  }
  return out.sort();
}

function failIf(condition, message) {
  if (condition) {
    console.error(`[ruby-stdlib-parity-audit] ${message}`);
    process.exit(1);
  }
}
