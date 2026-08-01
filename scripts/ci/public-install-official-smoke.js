#!/usr/bin/env node

"use strict";

const {
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} = require("node:fs");
const { createHash } = require("node:crypto");
const { tmpdir } = require("node:os");
const { dirname, join, relative, resolve, sep } = require("node:path");
const { spawnSync } = require("node:child_process");
const { sha256File } = require("../release/artifact-utils");

const root = resolve(__dirname, "..", "..");
const evidenceRoot = join(root, "test", ".generated", "public_install_official");
const logRoot = join(evidenceRoot, "logs");
const generatedEvidenceRoot = join(evidenceRoot, "generated");
const manifestPath = join(root, "test", "public_install_official", "manifest.json");
const manifest = readJson(manifestPath);
const stagedVersion = "0.2.3";
const stagedTag = `v${stagedVersion}`;
const sourceSha = runRaw("git", ["rev-parse", "HEAD"], { cwd: root }).stdout.trim();
const activeRuby = runRaw("ruby", ["-rrbconfig", "-e", "print RbConfig.ruby"], { cwd: root }).stdout.trim();
const archivePath = join(root, "dist", "reflaxe.ruby-release.zip");
const sidecarPath = `${archivePath}.sha256.json`;
const temporaryRoot = mkdtempSync(join(tmpdir(), "rubyhx-public-install-official."));
const consumerRoot = join(temporaryRoot, "consumer");
const consumerSource = join(consumerRoot, "src");
const outputs = {
  success: join(consumerRoot, "out-success"),
  assertionFailure: join(consumerRoot, "out-assertion-failure"),
  runtimeFailure: join(consumerRoot, "out-runtime-failure"),
};
const trackedDiffBefore = trackedDiff();
const report = {
  schemaVersion: 1,
  outcome: "fail",
  sourceSha,
  baseline: manifest.baseline,
  artifact: null,
  consumer: {
    rootAuthority: "isolated-haxelib-repository",
    checkoutClasspathsRejected: false,
    resolvedInstallSource: null,
    compileArguments: [
      "-D", "ruby_output=<isolated-output>",
      "-D", "reflaxe_ruby_profile=portable",
      "-D", "reflaxe_runtime",
      "-D", "no-utf16",
      "-cp", "src",
      "-lib", "reflaxe.ruby",
      "-main", "Main",
    ],
  },
  families: manifest.families,
  stages: [],
  runtime: null,
  failureProbes: null,
};

rmSync(evidenceRoot, { force: true, recursive: true });
mkdirSync(logRoot, { recursive: true });

let failure = null;
try {
  stage("verify-provenance", verifyProvenance);
  stage("build-release-shaped-package", buildPackage);
  stage("prepare-isolated-consumer", prepareConsumer);
  stage("install-public-package", installPackage);
  stage("resolve-install-authority", verifyInstallAuthority);
  stage("compile-official-representatives", () => compile("Main", outputs.success));
  stage("check-generated-ruby", () => verifyGeneratedRuby(outputs.success));
  stage("execute-official-representatives", executeSuccess);
  stage("prove-assertion-failure", proveAssertionFailure);
  stage("prove-runtime-failure", proveRuntimeFailure);
  if (trackedDiff() !== trackedDiffBefore) {
    throw new Error("public-install smoke changed tracked checkout files");
  }
  report.outcome = "pass";
} catch (error) {
  failure = error;
  report.error = error.message;
} finally {
  preserveGeneratedOutput();
  writeReports();
  rmSync(temporaryRoot, { force: true, recursive: true });
}

if (failure) {
  console.error(`[public-install-official] ERROR: ${failure.message}`);
  process.exit(1);
}

console.log(`[public-install-official] OK: ${report.runtime.stdout.trim()}`);
console.log(`[public-install-official] evidence: ${relative(root, evidenceRoot)}`);

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function slash(path) {
  return path.split(sep).join("/");
}

function stage(id, action) {
  const started = process.hrtime.bigint();
  try {
    const value = action();
    report.stages.push({ id, status: "pass", durationMs: elapsedMs(started) });
    return value;
  } catch (error) {
    report.stages.push({ id, status: "fail", durationMs: elapsedMs(started), error: error.message });
    throw error;
  }
}

function elapsedMs(started) {
  return Number((process.hrtime.bigint() - started) / 1000000n);
}

function runRaw(command, args, options = {}) {
  return spawnSync(command, args, {
    cwd: options.cwd ?? root,
    encoding: "utf8",
    env: options.env ?? process.env,
    stdio: ["ignore", "pipe", "pipe"],
  });
}

function runLogged(id, command, args, options = {}) {
  const result = runRaw(command, args, options);
  const rendered = [`$ ${command} ${args.join(" ")}`, result.stdout, result.stderr].filter(Boolean).join("\n");
  writeFileSync(join(logRoot, `${id}.log`), `${rendered.trimEnd()}\n`);
  if (!options.allowFailure && result.status !== 0) {
    throw new Error(`${id} exited ${result.status}: ${(result.stderr || result.stdout).trim()}`);
  }
  return result;
}

function trackedDiff() {
  const unstaged = runRaw("git", ["diff", "--binary"], { cwd: root });
  const staged = runRaw("git", ["diff", "--cached", "--binary"], { cwd: root });
  if (unstaged.status !== 0 || staged.status !== 0) throw new Error("unable to capture tracked checkout diff");
  return `${unstaged.stdout}${staged.stdout}`;
}

function verifyProvenance() {
  if (manifest.schemaVersion !== 1
    || manifest.baseline.version !== "4.3.7"
    || manifest.baseline.commit !== "e0b355c6be312c1b17382603f018cf52522ec651") {
    throw new Error("official representative manifest baseline is not the reviewed Haxe 4.3.7 identity");
  }
  const ids = manifest.families.map((family) => family.id);
  if (JSON.stringify(ids) !== JSON.stringify(["shared-top-level", "unitstd", "general-issue"])) {
    throw new Error("official representative manifest must contain exactly the three bounded families");
  }
  for (const family of manifest.families) {
    const localPath = join(root, family.localPath);
    if (!existsSync(localPath) || sha256(readFileSync(localPath)) !== family.localSha256) {
      throw new Error(`official representative fixture hash drifted: ${family.localPath}`);
    }
    if (family.classification === "unmodified" && family.localSha256 !== family.upstreamSha256) {
      throw new Error(`unmodified official fixture identity disagrees: ${family.localPath}`);
    }
    if (!family.protectedClaim?.trim()) throw new Error(`protected claim missing: ${family.id}`);
  }

  const referenceIndex = process.argv.indexOf("--reference");
  if (referenceIndex !== -1) verifyReferenceCheckout(resolve(process.argv[referenceIndex + 1]));
}

function verifyReferenceCheckout(referenceRoot) {
  const commit = runRaw("git", ["rev-parse", "HEAD"], { cwd: referenceRoot });
  const tag = runRaw("git", ["describe", "--tags", "--exact-match", "HEAD"], { cwd: referenceRoot });
  if (commit.status !== 0 || commit.stdout.trim() !== manifest.baseline.commit
    || tag.status !== 0 || tag.stdout.trim() !== manifest.baseline.version) {
    throw new Error("explicit Haxe reference checkout does not match the pinned tag and commit");
  }
  for (const family of manifest.families) {
    const upstreamPath = join(referenceRoot, family.upstreamPath);
    if (!existsSync(upstreamPath) || sha256(readFileSync(upstreamPath)) !== family.upstreamSha256) {
      throw new Error(`explicit Haxe reference bytes drifted: ${family.upstreamPath}`);
    }
  }
}

function buildPackage() {
  if (!process.argv.includes("--reuse-built-artifact")) {
    runLogged("build-package", "node", [
      "scripts/release/build-haxelib-package.js",
      stagedVersion,
      stagedTag,
      sourceSha,
    ], { cwd: root });
  }
  if (!existsSync(archivePath) || !existsSync(sidecarPath)) throw new Error("release-shaped Haxelib archive or sidecar is missing");
  const sidecar = readJson(sidecarPath);
  if (sidecar.sha256 !== sha256File(archivePath) || sidecar.sourceSha !== sourceSha || sidecar.version !== stagedVersion) {
    throw new Error("release-shaped Haxelib archive identity does not match its sidecar");
  }
  report.artifact = {
    filename: sidecar.localFilename,
    hostedFilename: sidecar.hostedFilename,
    version: sidecar.version,
    sourceSha: sidecar.sourceSha,
    bytes: sidecar.bytes,
    sha256: sidecar.sha256,
  };
}

function prepareConsumer() {
  mkdirSync(consumerSource, { recursive: true });
  cpSync(join(root, "test", "public_install_official", "harness"), consumerSource, { recursive: true });
  cpSync(join(root, "test", "public_install_official", "official"), consumerSource, { recursive: true });
  mkdirSync(join(consumerSource, "unitstd_ruby"), { recursive: true });
  for (const file of ["Assert.hx", "UpstreamUnitStdMacro.hx"]) {
    cpSync(join(root, "test", "unitstd_ruby", "src_haxe", "unitstd_ruby", file), join(consumerSource, "unitstd_ruby", file));
  }
  const unitstdTarget = join(consumerRoot, "test", "upstream_unitstd", "upstream", "StringBuf.unit.hx");
  mkdirSync(dirname(unitstdTarget), { recursive: true });
  cpSync(join(root, "test", "upstream_unitstd", "upstream", "StringBuf.unit.hx"), unitstdTarget);
}

function installPackage() {
  runLogged("haxelib-newrepo", "haxelib", ["newrepo"], { cwd: consumerRoot });
  runLogged("haxelib-install", "haxelib", ["install", archivePath, "--skip-dependencies", "--quiet"], { cwd: consumerRoot });
}

function verifyInstallAuthority() {
  const resolved = runLogged("haxelib-path", "haxelib", ["path", "reflaxe.ruby"], { cwd: consumerRoot });
  const combined = `${resolved.stdout}\n${resolved.stderr}`;
  if (!combined.includes(consumerRoot) || combined.includes(root)) {
    throw new Error("reflaxe.ruby did not resolve exclusively from the isolated Haxelib repository");
  }
  report.consumer.checkoutClasspathsRejected = true;
  report.consumer.resolvedInstallSource = "isolated-haxelib-repository";
}

function compile(mainClass, outputRoot) {
  rmSync(outputRoot, { force: true, recursive: true });
  const args = [
    "-v",
    "-D", `ruby_output=${outputRoot}`,
    "-D", "reflaxe_ruby_profile=portable",
    "-D", "reflaxe_runtime",
    "-D", "no-utf16",
    "-cp", "src",
    "-lib", "reflaxe.ruby",
    "-main", mainClass,
  ];
  const id = `compile-${mainClass.replaceAll(/([a-z])([A-Z])/g, "$1-$2").toLowerCase()}`;
  const result = runLogged(id, "haxe", args, { cwd: consumerRoot });
  const compilerEvidence = `${result.stdout}\n${result.stderr}`;
  if (compilerEvidence.includes(root)) {
    throw new Error(`${mainClass} compile observed the source checkout path instead of only the installed package`);
  }
  const generatedInventory = join(outputRoot, "_GeneratedFiles.json");
  if (existsSync(generatedInventory) && readFileSync(generatedInventory, "utf8").includes(root)) {
    throw new Error(`${mainClass} generated inventory leaked a source-checkout classpath`);
  }
}

function rubyFilesUnder(directory, base = directory) {
  const paths = [];
  for (const entry of readdirSync(directory).sort()) {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) paths.push(...rubyFilesUnder(path, base));
    else if (path.endsWith(".rb")) paths.push(slash(relative(base, path)));
  }
  return paths;
}

function verifyGeneratedRuby(outputRoot) {
  const rubyFiles = rubyFilesUnder(outputRoot);
  for (const required of ["main.rb", "run.rb", "unit/test_ops.rb", "unit/issues/issue10098.rb", "string_buf.rb"]) {
    if (!rubyFiles.includes(required)) throw new Error(`representative generated Ruby file is missing: ${required}`);
  }
  for (const relativePath of rubyFiles) {
    const syntax = runLogged(`ruby-syntax-${relativePath.replaceAll("/", "-")}`, activeRuby, ["-c", join(outputRoot, relativePath)], { cwd: consumerRoot });
    if (syntax.stdout.trim() !== "Syntax OK") throw new Error(`Ruby syntax check did not confirm ${relativePath}`);
  }
  report.runtime = { generatedRubyFiles: rubyFiles, exitCode: null, stdout: null };
}

function executeSuccess() {
  const result = runLogged("ruby-success", activeRuby, [join(outputs.success, "run.rb")], { cwd: consumerRoot });
  const match = /^public-install-official ok families=3 topLevelAssertions=(\d+)\n$/.exec(result.stdout);
  if (!match || Number(match[1]) < 50) throw new Error(`official representative runtime stdout mismatch: ${JSON.stringify(result.stdout)}`);
  report.runtime.exitCode = result.status;
  report.runtime.stdout = result.stdout;
  report.runtime.topLevelAssertions = Number(match[1]);
}

function proveAssertionFailure() {
  compile("AssertionFailureMain", outputs.assertionFailure);
  const result = runLogged("ruby-assertion-failure", activeRuby, [join(outputs.assertionFailure, "run.rb")], {
    cwd: consumerRoot,
    allowFailure: true,
  });
  const output = `${result.stdout}\n${result.stderr}`;
  if (result.status === 0 || !output.includes("official assertion failed")) {
    throw new Error("intentional harness assertion did not propagate as a recognizable nonzero Ruby failure");
  }
  report.failureProbes = {
    assertion: { exitCode: result.status, marker: "official assertion failed" },
    runtime: null,
  };
}

function proveRuntimeFailure() {
  compile("RuntimeFailureMain", outputs.runtimeFailure);
  const result = runLogged("ruby-runtime-failure", activeRuby, [join(outputs.runtimeFailure, "run.rb")], {
    cwd: consumerRoot,
    allowFailure: true,
  });
  const output = `${result.stdout}\n${result.stderr}`;
  if (result.status === 0 || !output.includes("intentional-public-install-runtime-failure")) {
    throw new Error("intentional target-runtime exception did not propagate as a recognizable nonzero Ruby failure");
  }
  report.failureProbes.runtime = { exitCode: result.status, marker: "intentional-public-install-runtime-failure" };
}

function preserveGeneratedOutput() {
  mkdirSync(generatedEvidenceRoot, { recursive: true });
  for (const [id, outputRoot] of Object.entries(outputs)) {
    if (existsSync(outputRoot)) cpSync(outputRoot, join(generatedEvidenceRoot, id), { recursive: true });
  }
}

function writeReports() {
  mkdirSync(evidenceRoot, { recursive: true });
  writeFileSync(join(evidenceRoot, "report.json"), `${JSON.stringify(report, null, 2)}\n`);
  const lines = [
    `PUBLIC INSTALL OFFICIAL: ${report.outcome.toUpperCase()}`,
    `source SHA: ${sourceSha}`,
    `package: ${report.artifact?.filename ?? "not built"}`,
    `install authority: ${report.consumer.resolvedInstallSource ?? "unproved"}`,
    `families: ${report.families.map((family) => `${family.id} (${family.classification})`).join(", ")}`,
    `runtime: ${report.runtime?.stdout?.trim() ?? "not completed"}`,
    `assertion failure propagation: ${report.failureProbes?.assertion?.exitCode > 0 ? "nonzero" : "unproved"}`,
    `runtime failure propagation: ${report.failureProbes?.runtime?.exitCode > 0 ? "nonzero" : "unproved"}`,
    `stages: ${report.stages.map((entry) => `${entry.id}=${entry.status}`).join(", ")}`,
  ];
  if (report.error) lines.push(`error: ${report.error}`);
  writeFileSync(join(evidenceRoot, "report.txt"), `${lines.join("\n")}\n`);
}
