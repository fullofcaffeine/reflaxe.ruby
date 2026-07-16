#!/usr/bin/env node

const { existsSync, readFileSync, readdirSync } = require("node:fs");
const { join, relative, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const coveragePath = join(root, "lib", "hxruby", "stdlib_coverage.json");
const coverage = JSON.parse(readFileSync(coveragePath, "utf8"));
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const supportMatrixPath = join(root, coverage.supportMatrix ?? "");
const supportMatrix = JSON.parse(readFileSync(supportMatrixPath, "utf8"));
const allowedDistributionKinds = new Set([
  "core",
  "standard-library",
  "default-gem",
  "bundled-gem",
  "platform-specific",
]);
const implementedStatuses = new Set([
  "implemented-public",
  "implemented-internal",
  "implemented-convenience",
]);
const allowedCoverageStatuses = new Set([...implementedStatuses, "planned", "deferred"]);

function fail(message) {
  console.error(`[ruby-stdlib-coverage] ERROR: ${message}`);
  process.exit(1);
}

function assert(condition, message) {
  if (!condition) fail(message);
}

function isNonEmptyString(value) {
  return typeof value === "string" && value.length > 0;
}

function walkHaxeFiles(directory, out) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== "_std") walkHaxeFiles(path, out);
    } else if (entry.isFile() && entry.name.endsWith(".hx")) {
      out.push(relative(root, path).split("\\").join("/"));
    }
  }
}

function compareBranches(left, right) {
  const a = left.split(".").map(Number);
  const b = right.split(".").map(Number);
  return a[0] - b[0] || a[1] - b[1];
}

assert(coverage.schemaVersion === 1, "schemaVersion must be 1");
assert(coverage.supportMatrix === "lib/hxruby/support_matrix.json", "supportMatrix must use the canonical manifest");
assert(coverage.scope?.unit === "Ruby library domain", "scope.unit must name the catalog unit");
assert(
  coverage.scope?.completeness === "curated-not-whole-stdlib",
  "scope must fail closed against a whole-stdlib support claim",
);
assert(isNonEmptyString(coverage.scope?.statement), "scope.statement is required");
assert(
  coverage.rbsGeneration?.scope === "strict-precise-or-omitted-subset",
  "RBS generation must retain its conservative supported subset",
);
assert(
  coverage.rbsGeneration?.claim === "generator-infrastructure-not-library-coverage",
  "RBS generation must not imply new library coverage",
);
assert(
  coverage.rbsGeneration?.command === "ruby -Ilib scripts/rbs/generate-extern.rb",
  "RBS generation command must remain explicit",
);
assert(
  coverage.rbsGeneration?.evidence === "npm run test:rbs-generator",
  "RBS generation must name its mandatory evidence",
);
assert(
  Array.isArray(coverage.rbsGeneration?.implementation) && coverage.rbsGeneration.implementation.length > 0,
  "RBS generation implementation paths are required",
);
for (const path of coverage.rbsGeneration.implementation) {
  assert(isNonEmptyString(path) && existsSync(join(root, path)), `RBS generation implementation is missing: ${path}`);
}
assert(existsSync(join(root, "scripts", "rbs", "generate-extern.rb")), "RBS generator command is missing");
assert(
  packageJson.scripts?.test?.includes("test:rbs-generator") &&
    packageJson.scripts?.["test:rbs-generator"]?.includes("rbs-generator-smoke.js"),
  "RBS generator evidence must be mandatory in npm test",
);
assert(
  packageJson.scripts?.test?.includes("test:csv-facade") &&
    packageJson.scripts?.["test:csv-facade"]?.includes("csv-facade-smoke.js"),
  "CSV facade evidence must be mandatory in npm test",
);
assert(
  packageJson.scripts?.test?.includes("test:open3-facade") &&
    packageJson.scripts?.["test:open3-facade"]?.includes("open3-facade-smoke.js"),
  "Open3 facade evidence must be mandatory in npm test",
);
assert(Array.isArray(coverage.domains) && coverage.domains.length > 0, "domains must be a non-empty array");
assert(
  JSON.stringify(coverage.rubyBranches) === JSON.stringify(supportMatrix.ruby.ciBranches),
  "rubyBranches must exactly match support_matrix.json",
);
assert(
  JSON.stringify(Object.keys(coverage.distributionKinds).sort()) ===
    JSON.stringify([...allowedDistributionKinds].sort()),
  "distributionKinds must define the complete supported classification vocabulary",
);
assert(
  JSON.stringify(Object.keys(coverage.coverageStatuses).sort()) ===
    JSON.stringify([...allowedCoverageStatuses].sort()),
  "coverageStatuses must define the complete supported status vocabulary",
);

const ids = new Set();
const facadeOwners = new Map();
const usedKinds = new Set();
let previousId = "";
for (const domain of coverage.domains) {
  assert(isNonEmptyString(domain.id), "every domain needs an id");
  assert(!ids.has(domain.id), `duplicate domain id: ${domain.id}`);
  assert(previousId < domain.id, `domains must be sorted by id: ${previousId} before ${domain.id}`);
  ids.add(domain.id);
  previousId = domain.id;

  assert(allowedCoverageStatuses.has(domain.coverageStatus), `invalid coverageStatus for ${domain.id}`);
  assert(Array.isArray(domain.surfaces), `surfaces must be an array for ${domain.id}`);
  assert(Array.isArray(domain.facadePaths), `facadePaths must be an array for ${domain.id}`);
  assert(Array.isArray(domain.evidence), `evidence must be an array for ${domain.id}`);
  assert(isNonEmptyString(domain.notes), `notes are required for ${domain.id}`);
  assert(domain.runtimeProbe && typeof domain.runtimeProbe === "object", `runtimeProbe is required for ${domain.id}`);
  assert(
    JSON.stringify(Object.keys(domain.distributionByRuby)) === JSON.stringify(coverage.rubyBranches),
    `distributionByRuby keys must exactly match rubyBranches for ${domain.id}`,
  );

  for (const [branch, kind] of Object.entries(domain.distributionByRuby)) {
    assert(allowedDistributionKinds.has(kind), `invalid ${branch} distribution for ${domain.id}: ${kind}`);
    usedKinds.add(kind);
  }

  if (implementedStatuses.has(domain.coverageStatus)) {
    assert(domain.surfaces.length > 0, `implemented domain must name surfaces: ${domain.id}`);
    assert(domain.facadePaths.length > 0, `implemented domain must name facade paths: ${domain.id}`);
    assert(domain.evidence.length > 0, `implemented domain must name evidence: ${domain.id}`);
  } else {
    assert(domain.surfaces.length === 0, `unimplemented domain cannot claim surfaces: ${domain.id}`);
    assert(domain.facadePaths.length === 0, `unimplemented domain cannot claim facade paths: ${domain.id}`);
    assert(domain.evidence.length === 0, `unimplemented domain cannot claim evidence: ${domain.id}`);
  }

  for (const surface of domain.surfaces) {
    assert(isNonEmptyString(surface), `empty surface in ${domain.id}`);
  }
  for (const evidence of domain.evidence) {
    assert(isNonEmptyString(evidence), `empty evidence in ${domain.id}`);
    assert(evidence.startsWith("npm run test:"), `evidence must name a mandatory npm gate in ${domain.id}: ${evidence}`);
  }
  for (const facadePath of domain.facadePaths) {
    assert(/^std\/ruby\/(?!_std\/).+\.hx$/.test(facadePath), `invalid facade path in ${domain.id}: ${facadePath}`);
    assert(existsSync(join(root, facadePath)), `facade path is missing for ${domain.id}: ${facadePath}`);
    assert(!facadeOwners.has(facadePath), `facade path has multiple owners: ${facadePath}`);
    facadeOwners.set(facadePath, domain.id);
  }

  const kinds = new Set(Object.values(domain.distributionByRuby));
  if (kinds.size === 1 && kinds.has("core")) {
    assert(domain.runtimeProbe.require === undefined, `core probe must not require a library: ${domain.id}`);
    assert(domain.runtimeProbe.gem === undefined, `core probe must not name a gem: ${domain.id}`);
  } else {
    assert(isNonEmptyString(domain.runtimeProbe.require), `non-core probe must name require path: ${domain.id}`);
  }
  if (kinds.has("default-gem") || kinds.has("bundled-gem")) {
    assert(isNonEmptyString(domain.runtimeProbe.gem), `gem-backed probe must name a gem: ${domain.id}`);
  }
  assert(
    Array.isArray(domain.runtimeProbe.constants) && domain.runtimeProbe.constants.length > 0,
    `runtimeProbe.constants must be non-empty for ${domain.id}`,
  );
}

assert(
  JSON.stringify([...usedKinds].sort()) === JSON.stringify([...allowedDistributionKinds].sort()),
  "the catalog must exercise every declared distribution kind",
);

const committedFacades = [];
walkHaxeFiles(join(root, "std", "ruby"), committedFacades);
committedFacades.sort();
for (const path of committedFacades) {
  assert(facadeOwners.has(path), `committed ruby facade is missing from the coverage catalog: ${path}`);
}
for (const path of facadeOwners.keys()) {
  assert(committedFacades.includes(path), `coverage catalog references a non-facade path: ${path}`);
}

const uri = coverage.domains.find((domain) => domain.id === "library.uri");
assert(uri?.coverageStatus === "implemented-public", "library.uri must remain an implemented public contract");
assert(uri.contractProvenance?.kind === "reviewed-rbs", "URI contract must record reviewed RBS provenance");
assert(uri.contractProvenance?.repository === "https://github.com/ruby/rbs", "URI provenance must use official ruby/rbs");
assert(/^v\d+\.\d+\.\d+$/.test(uri.contractProvenance?.release ?? ""), "URI provenance must pin an RBS release");
assert(uri.contractProvenance?.library === "stdlib/uri/0", "URI provenance must name the reviewed library");
assert(Array.isArray(uri.contractProvenance?.sources) && uri.contractProvenance.sources.length > 0, "URI provenance sources required");
for (const source of uri.contractProvenance.sources) {
  assert(isNonEmptyString(source.path), "URI provenance source path required");
  assert(/^[0-9a-f]{64}$/.test(source.sha256 ?? ""), `URI provenance SHA-256 is invalid: ${source.path}`);
}
assert(isNonEmptyString(uri.contractProvenance?.curation), "URI provenance must describe signature curation");

const csv = coverage.domains.find((domain) => domain.id === "library.csv");
assert(csv?.coverageStatus === "implemented-public", "library.csv must be an implemented public contract");
assert(csv.contractProvenance?.kind === "reviewed-rbs-plus-official-ruby-api", "CSV contract provenance kind mismatch");
assert(csv.contractProvenance?.repository === "https://github.com/ruby/rbs", "CSV provenance must use official ruby/rbs");
assert(csv.contractProvenance?.release === "v4.0.3", "CSV provenance must pin the reviewed RBS release");
assert(csv.contractProvenance?.library === "stdlib/csv/0", "CSV provenance must name the reviewed library");
assert(
  csv.contractProvenance?.rubyDocumentation === "https://docs.ruby-lang.org/en/3.3/CSV.html",
  "CSV provenance must name official Ruby documentation",
);
assert(Array.isArray(csv.contractProvenance?.sources) && csv.contractProvenance.sources.length > 0, "CSV provenance sources required");
for (const source of csv.contractProvenance.sources) {
  assert(isNonEmptyString(source.path), "CSV provenance source path required");
  assert(/^[0-9a-f]{64}$/.test(source.sha256 ?? ""), `CSV provenance SHA-256 is invalid: ${source.path}`);
}
assert(isNonEmptyString(csv.contractProvenance?.curation), "CSV provenance must describe signature curation");

const open3 = coverage.domains.find((domain) => domain.id === "library.open3");
assert(open3?.coverageStatus === "implemented-public", "library.open3 must be an implemented public contract");
assert(open3.contractProvenance?.kind === "reviewed-rbs-plus-official-gem-source", "Open3 provenance kind mismatch");
assert(open3.contractProvenance?.repository === "https://github.com/ruby/rbs", "Open3 provenance must use official ruby/rbs");
assert(open3.contractProvenance?.release === "v4.0.3", "Open3 provenance must pin the reviewed RBS release");
assert(open3.contractProvenance?.library === "stdlib/open3/0", "Open3 provenance must name the reviewed library");
assert(
  open3.contractProvenance?.implementationRepository === "https://github.com/ruby/open3" &&
    open3.contractProvenance?.implementationRelease === "v0.2.1",
  "Open3 provenance must pin the official implementation release",
);
for (const source of [
  ...(open3.contractProvenance?.sources ?? []),
  ...(open3.contractProvenance?.implementationSources ?? []),
]) {
  assert(isNonEmptyString(source.path), "Open3 provenance source path required");
  assert(/^[0-9a-f]{64}$/.test(source.sha256 ?? ""), `Open3 provenance SHA-256 is invalid: ${source.path}`);
}
assert(isNonEmptyString(open3.contractProvenance?.curation), "Open3 provenance must describe signature curation");

for (const id of ["library.set"]) {
  const domain = coverage.domains.find((candidate) => candidate.id === id);
  assert(domain?.coverageStatus === "planned", `${id} must remain planned until its own facade bead lands`);
}

const version = spawnSync("ruby", ["-e", "print RUBY_VERSION"], { cwd: root, encoding: "utf8" });
if (version.status !== 0) {
  process.stdout.write(version.stdout);
  process.stderr.write(version.stderr);
  fail("unable to determine the active Ruby version");
}
const rubyVersion = version.stdout.trim();
const rubyBranch = rubyVersion.split(".").slice(0, 2).join(".");
const newestBranch = coverage.rubyBranches.at(-1);
if (!coverage.rubyBranches.includes(rubyBranch)) {
  assert(
    compareBranches(rubyBranch, newestBranch) > 0,
    `Ruby ${rubyVersion} is neither a supported branch nor a newer forward-permissive branch`,
  );
  console.warn(
    `[ruby-stdlib-coverage] WARN: Ruby ${rubyVersion} is newer than tested ${newestBranch}; schema checked, runtime availability unverified`,
  );
  process.exit(0);
}

const probes = coverage.domains
  .filter((domain) => {
    const platforms = domain.runtimeProbe.platforms;
    return !platforms || platforms.includes(process.platform);
  })
  .map((domain) => ({
    id: domain.id,
    distribution: domain.distributionByRuby[rubyBranch],
    ...domain.runtimeProbe,
  }))
  .sort((left, right) => Number(right.distribution === "core") - Number(left.distribution === "core"));

const rubyProbe = String.raw`
require "json"
require "rubygems"

probes = JSON.parse(STDIN.read)
probes.each do |probe|
  distribution = probe.fetch("distribution")
  require probe.fetch("require") if probe["require"] && distribution != "core"
  probe.fetch("constants").each do |name|
    name.split("::").reject(&:empty?).reduce(Object) { |owner, part| owner.const_get(part, false) }
  end

  gem_name = probe["gem"] || probe["require"]
  specs = gem_name ? Gem::Specification.find_all_by_name(gem_name) : []
  case distribution
  when "core"
    # A domain can move from a gem to core across Ruby branches. Resolving its
    # constant before its historical require proves the current core contract.
  when "standard-library"
    raise "#{probe.fetch("id")}: expected no gem specification for #{gem_name}" unless specs.empty?
  when "default-gem"
    raise "#{probe.fetch("id")}: expected a shipped default gem for #{gem_name}" unless specs.any?(&:default_gem?)
  when "bundled-gem"
    raise "#{probe.fetch("id")}: expected an installed bundled gem for #{gem_name}" if specs.empty?
    raise "#{probe.fetch("id")}: bundled gem unexpectedly has a default specification" if specs.any?(&:default_gem?)
  when "platform-specific"
    # Availability plus constants are the platform-specific contract; gem
    # classification is intentionally orthogonal here.
  else
    raise "#{probe.fetch("id")}: unsupported distribution"
  end
end
`;
const runtime = spawnSync("ruby", ["-e", rubyProbe], {
  cwd: root,
  encoding: "utf8",
  input: JSON.stringify(probes),
});
if (runtime.status !== 0) {
  process.stdout.write(runtime.stdout);
  process.stderr.write(runtime.stderr);
  fail(`runtime distribution probe failed on Ruby ${rubyVersion}`);
}

console.log(
  `[ruby-stdlib-coverage] OK: ${coverage.domains.length} domains, ${committedFacades.length} facades, Ruby ${rubyVersion} availability`,
);
