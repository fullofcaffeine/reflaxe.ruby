#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } = require("node:fs");
const os = require("node:os");
const { dirname, join, relative, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const generated = join(root, "test", ".generated", "stable_benchmark");
const cliOutput = join(generated, "rubyhx_cli");
const railsOutput = join(generated, "todoapp_server");
const todoapp = join(root, "examples", "todoapp_rails");
const clientOutput = join(todoapp, "tmp", "client");
const railsApp = join(todoapp, "build", "rails");
const reportPath = join(root, "tmp", "stable-benchmark.json");
const supportMatrix = JSON.parse(readFileSync(join(root, "lib", "hxruby", "support_matrix.json"), "utf8"));
const { samples, requireRails } = parseOptions(process.argv.slice(2));
const reflaxe = findReflaxe();

// These are runaway caps, not speed targets. Ordinary hosted-runner variance is
// reported for review and deliberately does not fail the release lane.
const limits = {
  rubyhx_cli_compile: { ms: 120_000, rssKb: 1_048_576, bytes: 5_000_000, files: 250 },
  railshx_server_compile: { ms: 180_000, rssKb: 2_097_152, bytes: 25_000_000, files: 1_500 },
  railshx_client_compile: { ms: 120_000, rssKb: 1_048_576, bytes: 25_000_000, files: 1_500 },
  rubyhx_cli_startup: { ms: 10_000, rssKb: 524_288 },
  rails_production_boot: { ms: 60_000, rssKb: 1_572_864 },
};

const workloads = [
  {
    id: "rubyhx_cli_compile",
    output: cliOutput,
    command: "haxe",
    args: compilerArgs(cliOutput, join(root, "examples", "rubyhx_cli"), false, ["--dce", "full"]),
  },
  {
    id: "railshx_server_compile",
    output: railsOutput,
    command: "haxe",
    args: compilerArgs(railsOutput, join(todoapp, "src"), true),
  },
  {
    id: "railshx_client_compile",
    output: clientOutput,
    command: "haxe",
    args: [join(todoapp, "build-client.hxml")],
  },
  {
    id: "rubyhx_cli_startup",
    command: "ruby",
    args: [join(cliOutput, "run.rb"), "test/fixtures/rubyhx_cli/sample.txt"],
    validate(result) {
      const actual = JSON.parse(result.stdout);
      const expected = { path: "test/fixtures/rubyhx_cli/sample.txt", lines: 2, words: 3, characters: 16 };
      if (JSON.stringify(actual) !== JSON.stringify(expected)) fail(`${this.id} returned unexpected output`);
    },
  },
];

const railsReady = existsSync(join(railsApp, "Gemfile"))
  && commandSucceeds("bundle", ["check"], { cwd: railsApp });
if (railsReady) {
  workloads.push({
    id: "rails_production_boot",
    command: "bundle",
    args: ["exec", "ruby", "bin/rails", "runner", "print Rails.version"],
    cwd: railsApp,
    env: { ...process.env, RAILS_ENV: "production", SECRET_KEY_BASE_DUMMY: "1" },
    validate(result) {
      const expected = supportMatrix.railsHx.verifiedRuntime.railsVersion;
      if (result.stdout.trim() !== expected) fail(`${this.id} expected Rails ${expected}`);
    },
  });
} else if (requireRails) {
  fail("Rails boot measurement needs a prepared todo app; run npm run test:todoapp-production first");
}

rmSync(generated, { force: true, recursive: true });
mkdirSync(generated, { recursive: true });
const results = workloads.map(measureWorkload);
const violations = checkLimits(results);
const report = {
  schema: 1,
  generatedAt: new Date().toISOString(),
  sourceSha: outputOf("git", ["rev-parse", "HEAD"]) || null,
  sampleCount: samples,
  policy: "Representative viability evidence with broad absolute runaway caps; normal runner variance is non-blocking.",
  runner: {
    platform: process.platform,
    release: os.release(),
    arch: os.arch(),
    cpu: os.cpus()[0]?.model ?? null,
    cpuCount: os.cpus().length,
    totalMemoryBytes: os.totalmem(),
    githubImageOs: process.env.ImageOS ?? null,
    githubImageVersion: process.env.ImageVersion ?? null,
    node: process.version,
    npm: invokingNpmVersion(),
    haxe: outputOf("haxe", ["-version"]),
    ruby: outputOf("ruby", ["-e", "print RUBY_VERSION"]),
  },
  limits,
  workloads: results,
  violations,
};

mkdirSync(dirname(reportPath), { recursive: true });
writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
printSummary(report);
console.log(`[stable-benchmark] machine report: ${relative(root, reportPath)}`);
console.log(`[stable-benchmark] json=${JSON.stringify(report)}`);
if (violations.length) {
  violations.forEach((message) => console.error(`[stable-benchmark] LIMIT: ${message}`));
  process.exit(1);
}

function measureWorkload(workload) {
  const measured = [];
  for (let index = 0; index < samples; index += 1) {
    if (workload.output) {
      rmSync(workload.output, { force: true, recursive: true });
      mkdirSync(workload.output, { recursive: true });
    }
    const result = timed(workload.command, workload.args, workload);
    workload.validate?.(result);
    const artifact = workload.output ? directoryStats(workload.output) : {};
    if (workload.output && artifact.files === 0) fail(`${workload.id} produced no files`);
    measured.push({
      label: index === 0 ? "cold" : `repeat-${index}`,
      durationMs: result.durationMs,
      peakRssKb: result.peakRssKb,
      outputBytes: artifact.bytes ?? null,
      outputFiles: artifact.files ?? null,
    });
  }
  const durations = measured.map((sample) => sample.durationMs);
  const rss = measured.map((sample) => sample.peakRssKb).filter(Number.isFinite);
  const last = measured[measured.length - 1];
  return {
    id: workload.id,
    samples: measured,
    summary: {
      medianMs: median(durations),
      minMs: Math.min(...durations),
      maxMs: Math.max(...durations),
      spreadPercent: round((Math.max(...durations) - Math.min(...durations)) / median(durations) * 100),
      maxPeakRssKb: rss.length ? Math.max(...rss) : null,
      outputBytes: last.outputBytes,
      outputFiles: last.outputFiles,
    },
  };
}

function timed(command, args, options) {
  const started = process.hrtime.bigint();
  let result;
  let peakRssKb = null;
  if (existsSync("/usr/bin/time") && process.platform === "linux") {
    result = run("/usr/bin/time", ["-f", "__HXRUBY_RSS_KB__=%M", "--", command, ...args], options);
    peakRssKb = Number(result.stderr.match(/__HXRUBY_RSS_KB__=(\d+)/)?.[1] ?? NaN);
  } else if (existsSync("/usr/bin/time") && process.platform === "darwin") {
    result = run("/usr/bin/time", ["-l", command, ...args], options);
    const bytes = Number(result.stderr.match(/^\s*(\d+)\s+maximum resident set size/m)?.[1] ?? NaN);
    peakRssKb = Number.isFinite(bytes) ? Math.round(bytes / 1024) : null;
  } else {
    result = run(command, args, options);
  }
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    fail(`${command} exited ${result.status ?? "without a status"}`);
  }
  if (!Number.isFinite(peakRssKb)) peakRssKb = null;
  if (process.env.CI && peakRssKb == null) fail(`canonical CI could not measure peak RSS for ${command}`);
  return {
    durationMs: round(Number(process.hrtime.bigint() - started) / 1_000_000),
    peakRssKb,
    stdout: result.stdout,
  };
}

function checkLimits(results) {
  const violations = [];
  for (const result of results) {
    const limit = limits[result.id];
    for (const sample of result.samples) {
      for (const [metric, value, maximum] of [
        ["durationMs", sample.durationMs, limit.ms],
        ["peakRssKb", sample.peakRssKb, limit.rssKb],
        ["outputBytes", sample.outputBytes, limit.bytes],
        ["outputFiles", sample.outputFiles, limit.files],
      ]) {
        if (Number.isFinite(value) && Number.isFinite(maximum) && value > maximum) {
          violations.push(`${result.id}/${sample.label} ${metric}=${value} exceeds ${maximum}`);
        }
      }
    }
  }
  return violations;
}

function compilerArgs(destination, source, rails, extra = []) {
  return [
    "-D", `ruby_output=${destination}`,
    "-D", "reflaxe_runtime",
    ...(rails ? ["-D", "reflaxe_ruby_rails"] : []),
    "-cp", join(root, "src"),
    "-cp", source,
    "-cp", reflaxe,
    "--macro", "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro", "reflaxe.ruby.CompilerInit.Start()",
    ...extra,
    "-main", "Main",
  ];
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 16 * 1024 * 1024,
  });
  if (result.error) throw result.error;
  return result;
}

function outputOf(command, args) {
  try {
    const result = run(command, args);
    return result.status === 0 ? result.stdout.trim() : "";
  } catch {
    return "";
  }
}

function invokingNpmVersion() {
  // `npm run` prepends node_modules/.bin, where semantic-release may expose a
  // different transitive npm. The user agent identifies the CLI that actually
  // launched this script.
  const match = process.env.npm_config_user_agent?.match(/(?:^|\s)npm\/([^\s]+)/);
  return match?.[1] ?? outputOf("npm", ["--version"]);
}

function commandSucceeds(command, args, options) {
  try {
    return run(command, args, options).status === 0;
  } catch {
    return false;
  }
}

function directoryStats(directory) {
  return readdirSync(directory, { withFileTypes: true }).reduce((total, entry) => {
    const path = join(directory, entry.name);
    const next = entry.isDirectory() ? directoryStats(path) : { bytes: entry.isFile() ? statSync(path).size : 0, files: entry.isFile() ? 1 : 0 };
    return { bytes: total.bytes + next.bytes, files: total.files + next.files };
  }, { bytes: 0, files: 0 });
}

function findReflaxe() {
  const candidates = [
    join(root, "vendor", "reflaxe", "src"),
    resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
    resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
    resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
  ];
  const found = candidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
  if (!found) fail("unable to find vendored Reflaxe source");
  return found;
}

function parseOptions(args) {
  let count = Number(process.env.HXRUBY_BENCHMARK_SAMPLES ?? "3");
  let rails = false;
  for (let index = 0; index < args.length; index += 1) {
    if (args[index] === "--require-rails") rails = true;
    else if (args[index] === "--samples") count = Number(args[++index]);
    else fail(`unknown option ${args[index]}`);
  }
  if (!Number.isInteger(count) || count < 1 || count > 10) fail("--samples must be an integer from 1 to 10");
  return { samples: count, requireRails: rails };
}

function median(values) {
  const sorted = [...values].sort((left, right) => left - right);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
}

function printSummary(report) {
  console.log("[stable-benchmark] representative viability results");
  for (const workload of report.workloads) {
    const value = workload.summary;
    const output = value.outputBytes == null ? "n/a" : `${value.outputBytes} bytes/${value.outputFiles} files`;
    console.log(`[stable-benchmark] ${workload.id}: median=${value.medianMs}ms range=${value.minMs}-${value.maxMs}ms spread=${value.spreadPercent}% peak_rss=${value.maxPeakRssKb ?? "n/a"}KiB output=${output}`);
  }
}

function round(value) {
  return Math.round(value * 10) / 10;
}

function fail(message) {
  console.error(`[stable-benchmark] ERROR: ${message}`);
  process.exit(1);
}
