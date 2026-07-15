#!/usr/bin/env node

const { existsSync, readFileSync, readdirSync, statSync } = require("node:fs");
const { join, relative, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const auditPath = join(root, "docs", "railshx-component-dependencies.json");
const parityPath = join(root, "docs", "ruby-stdlib-parity-audit.json");
const inventoryPath = join(root, "docs", "stdlib-inventory.json");
const packagePath = join(root, "package.json");
const workflowPath = join(root, ".github", "workflows", "ci.yml");

const audit = readJson(auditPath);
const parity = readJson(parityPath);
const inventory = readJson(inventoryPath);
const packageJson = readJson(packagePath);
const workflow = readFileSync(workflowPath, "utf8");
const componentRuntime = readFileSync(join(root, "scripts", "ci", "rails-component-runtime.js"), "utf8");
const parityByModule = new Map(parity.candidates.map((entry) => [entry.module, entry]));
const inventoryByPath = new Map(inventory.entries.map((entry) => [entry.path, entry]));
const rubyInventoryByModule = new Map(
  inventory.entries
    .filter((entry) => entry.path.startsWith("std/ruby/") && !entry.path.startsWith("std/ruby/_std/") && entry.path.endsWith(".hx"))
    .map((entry) => [entry.path.replace(/^std\//, "").replace(/\.hx$/, "").split("/").join("."), entry]),
);
const coveredClassifications = new Set(["covered-ruby-override", "covered-upstream-fallback"]);
const evidenceKinds = new Set(["compile", "negative", "runtime", "browser", "production"]);
const evidenceLanes = new Set(["full", "rails-runtime", "browser", "production"]);

failIf(audit.schemaVersion !== 1, "schemaVersion must be 1");
failIf(!audit.scope || typeof audit.scope !== "string", "scope is required");
failIf(!Array.isArray(audit.scanRoots) || audit.scanRoots.length === 0, "scanRoots must be a non-empty array");
failIf(!audit.foundations || !Array.isArray(audit.foundations.evidence), "foundations.evidence is required");
failIf(!Array.isArray(audit.components) || audit.components.length === 0, "components must be a non-empty array");
validateCommand("test:railshx-component-dependencies", "full", "component dependency audit");

for (const marker of [
  "support_matrix.json",
  "verifiedRuntime.railsVersion",
  "BUNDLE_GEMFILE",
  'REQUIRE_RAILS: "1"',
  "active-support-facades-smoke.js",
  "instrumentation-smoke.js",
  "rails-concern-smoke.js",
  "rails-generators-smoke.js",
]) {
  failIf(!componentRuntime.includes(marker), `exact-Rails component runtime is missing required marker: ${marker}`);
}

for (const module of audit.foundations.coveredHaxeStdModules ?? []) {
  const entry = parityByModule.get(module);
  failIf(!entry, `foundational Haxe std module is missing from parity audit: ${module}`);
  failIf(!coveredClassifications.has(entry.classification), `foundational Haxe std module is not covered: ${module} (${entry.classification})`);
}

for (const path of audit.foundations.runtimePaths ?? []) {
  const entry = inventoryByPath.get(path);
  failIf(!entry, `foundation runtime path is missing from std inventory: ${path}`);
  failIf(entry.status !== "implemented", `foundation runtime path is not implemented: ${path} (${entry.status})`);
  failIf(!existsSync(join(root, path)), `foundation runtime path is missing: ${path}`);
}

for (const command of audit.foundations.evidence) {
  validateCommand(command, "full", "foundation");
}

const componentIds = new Set();
let previousId = "";
for (const component of audit.components) {
  failIf(!component.id || typeof component.id !== "string", "component id is required");
  failIf(componentIds.has(component.id), `duplicate component id: ${component.id}`);
  failIf(previousId && previousId > component.id, `components must be sorted by id: ${component.id}`);
  componentIds.add(component.id);
  previousId = component.id;

  failIf(!component.scope || typeof component.scope !== "string", `component scope is required: ${component.id}`);
  failIf(!Array.isArray(component.claimMarkers) || component.claimMarkers.length === 0, `claimMarkers are required: ${component.id}`);
  failIf(!Array.isArray(component.sourceRoots) || component.sourceRoots.length === 0, `sourceRoots are required: ${component.id}`);
  failIf(!Array.isArray(component.targetDependencies) || component.targetDependencies.length === 0, `targetDependencies are required: ${component.id}`);
  failIf(!Array.isArray(component.evidence) || component.evidence.length === 0, `evidence is required: ${component.id}`);

  for (const marker of component.claimMarkers) {
    failIf(!marker.path || !marker.contains, `invalid claim marker: ${component.id}`);
    const fullPath = join(root, marker.path);
    failIf(!existsSync(fullPath), `claim document is missing for ${component.id}: ${marker.path}`);
    failIf(!readFileSync(fullPath, "utf8").includes(marker.contains), `claim marker is missing for ${component.id}: ${marker.contains}`);
  }

  for (const path of component.sourceRoots) {
    failIf(!existsSync(join(root, path)), `component source root is missing for ${component.id}: ${path}`);
  }

  const kinds = new Set();
  for (const evidence of component.evidence) {
    failIf(!evidenceKinds.has(evidence.kind), `invalid evidence kind for ${component.id}: ${evidence.kind}`);
    failIf(!evidenceLanes.has(evidence.lane), `invalid evidence lane for ${component.id}: ${evidence.lane}`);
    validateCommand(evidence.command, evidence.lane, component.id);
    kinds.add(evidence.kind);
  }
  for (const requiredKind of ["compile", "negative"]) {
    failIf(!kinds.has(requiredKind), `${component.id} is missing ${requiredKind} evidence`);
  }
  failIf(!["runtime", "browser", "production"].some((kind) => kinds.has(kind)), `${component.id} is missing executable target evidence`);
}

const scanFiles = [];
for (const path of audit.scanRoots) {
  const fullPath = join(root, path);
  failIf(!existsSync(fullPath), `scan root is missing: ${path}`);
  collectHaxeFiles(fullPath, scanFiles);
}

const unfinishedUses = [];
const unaccountedImports = [];
const rubyFacadeUses = new Set();
for (const file of [...new Set(scanFiles)].sort()) {
  const source = stripCommentsAndStrings(readFileSync(file, "utf8"));
  const imports = [...source.matchAll(/^\s*(?:import|using)\s+([A-Za-z0-9_.]+)(?:\s+as\s+[A-Za-z0-9_]+)?\s*;/gm)].map((match) => match[1]);

  for (const imported of imports) {
    if (imported.startsWith("haxe.macro.")) continue;
    if (!imported.startsWith("haxe.") && !imported.startsWith("sys.")) continue;

    const entry = parityEntryForImport(imported);
    if (!entry) {
      unaccountedImports.push(`${relative(root, file)}: ${imported}`);
    } else if (!coveredClassifications.has(entry.classification)) {
      unfinishedUses.push(`${relative(root, file)}: ${imported} -> ${entry.module} (${entry.classification})`);
    }
  }

  for (const match of source.matchAll(/\b(?:haxe|sys)\.[A-Za-z0-9_.]+/g)) {
    const qualified = match[0].replace(/\.+$/, "");
    if (qualified.startsWith("haxe.macro.")) continue;
    const entry = parityEntryForImport(qualified);
    if (!entry) {
      unaccountedImports.push(`${relative(root, file)}: ${qualified}`);
    } else if (!coveredClassifications.has(entry.classification)) {
      unfinishedUses.push(`${relative(root, file)}: ${qualified} -> ${entry.module} (${entry.classification})`);
    }
  }

  for (const match of source.matchAll(/(?:^|[^A-Za-z0-9_.])(ruby\.[A-Za-z0-9_.]+)/gm)) {
    const qualified = match[1].replace(/\.+$/, "");
    const module = [...rubyInventoryByModule.keys()]
      .filter((candidate) => qualified === candidate || qualified.startsWith(`${candidate}.`))
      .sort((left, right) => right.length - left.length)[0];
    failIf(!module, `RailsHx Ruby facade use is missing from std inventory: ${relative(root, file)}: ${qualified}`);
    rubyFacadeUses.add(module);
  }

  for (const entry of parity.candidates) {
    if (coveredClassifications.has(entry.classification)) continue;
    const pattern = new RegExp(`(^|[^A-Za-z0-9_])${escapeRegex(entry.module)}([^A-Za-z0-9_]|$)`);
    if (pattern.test(source)) {
      unfinishedUses.push(`${relative(root, file)}: ${entry.module} (${entry.classification})`);
    }
  }
}

failIf(unaccountedImports.length > 0, `runtime Haxe/sys imports are missing from the parity ledger:\n${unique(unaccountedImports).join("\n")}`);
failIf(unfinishedUses.length > 0, `supported RailsHx sources use unfinished Haxe std candidates:\n${unique(unfinishedUses).join("\n")}`);

for (const module of [...rubyFacadeUses].sort()) {
  const entry = rubyInventoryByModule.get(module);
  failIf(entry.status !== "implemented", `RailsHx Ruby facade is not implemented: ${module} (${entry.status})`);
  failIf(!existsSync(join(root, entry.path)), `RailsHx Ruby facade path is missing: ${entry.path}`);
}

console.log(`[railshx-component-dependencies] ${audit.components.length} component families checked`);
console.log(`[railshx-component-dependencies] ${new Set(scanFiles).size} Haxe sources scanned`);
console.log(`[railshx-component-dependencies] ${rubyFacadeUses.size} direct ruby.* facades verified`);
console.log("[railshx-component-dependencies] no supported source imports an unfinished Haxe std candidate");

function validateCommand(command, lane, owner) {
  failIf(!command || typeof command !== "string", `evidence command is required: ${owner}`);
  failIf(!packageJson.scripts[command], `unknown evidence command for ${owner}: ${command}`);

  if (lane === "full") {
    failIf(!packageJson.scripts.test.includes(`npm run ${command}`), `${command} is not mandatory in npm test (${owner})`);
    return;
  }

  if (lane === "rails-runtime") {
    failIf(!packageJson.scripts["test:rails-runtime"].includes(`npm run ${command}`), `${command} is not mandatory in test:rails-runtime (${owner})`);
    failIf(!workflow.includes("npm run test:rails-runtime"), "CI does not invoke test:rails-runtime");
    return;
  }

  if (lane === "browser") {
    failIf(!workflow.includes(`npm run ${command}`), `${command} is not invoked by the browser CI lane (${owner})`);
    return;
  }

  if (lane === "production") {
    failIf(!workflow.includes(`npm run ${command}`), `${command} is not invoked by the production CI lane (${owner})`);
  }
}

function parityEntryForImport(imported) {
  const candidates = parity.candidates
    .filter((entry) => imported === entry.module || imported.startsWith(`${entry.module}.`))
    .sort((left, right) => right.module.length - left.module.length);
  return candidates[0];
}

function collectHaxeFiles(path, out) {
  if (statSync(path).isFile()) {
    if (path.endsWith(".hx")) out.push(path);
    return;
  }
  for (const entry of readdirSync(path)) {
    collectHaxeFiles(join(path, entry), out);
  }
}

function stripCommentsAndStrings(source) {
  return source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/\/\/.*$/gm, "")
    .replace(/"(?:\\.|[^"\\])*"/g, '""')
    .replace(/'(?:\\.|[^'\\])*'/g, "''");
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function unique(values) {
  return [...new Set(values)].sort();
}

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function failIf(condition, message) {
  if (condition) {
    console.error(`[railshx-component-dependencies] ${message}`);
    process.exit(1);
  }
}
