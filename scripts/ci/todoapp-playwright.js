#!/usr/bin/env node

const { existsSync, readdirSync } = require("node:fs");
const net = require("node:net");
const { join, resolve } = require("node:path");
const { spawn, spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const appDir = join(root, "test", ".generated", "rails_integration");
const requestedPort = process.env.RAILSHX_PLAYWRIGHT_PORT ?? process.env.PORT;
const defaultPort = "3100";
const bind = process.env.BIND ?? "127.0.0.1";
const spec = process.env.RAILSHX_PLAYWRIGHT_SPEC ?? "examples/todoapp_rails/e2e";

let server = null;
let serverLog = "";
let currentStage = "startup";

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    cleanup();
    process.exit(signal === "SIGINT" ? 130 : 143);
  });
}

main().catch((error) => {
  console.error(error.stack ?? error.message ?? String(error));
  cleanup();
  process.exit(1);
});

async function main() {
  stage("browser ruby probe", ensureSupportedRuby);

  const port = await stageAsync("browser port allocation", resolvePort);
  const baseUrl = process.env.BASE_URL ?? `http://${bind}:${port}`;

  stage("browser app prepare", () => run(process.execPath, [join(root, "scripts", "rails", "todoapp.js"), "prepare"], {
    env: { ...process.env, PORT: port, BIND: bind },
  }));

  stage("browser install", ensurePlaywrightBrowser);

  currentStage = "browser server boot";
  process.stdout.write(`[todoapp-playwright] stage: ${currentStage}\n`);
  server = spawn("bundle", ["exec", "ruby", "bin/rails", "server", "-b", bind, "-p", port], {
    cwd: appDir,
    env: process.env,
    stdio: ["ignore", "pipe", "pipe"],
  });

  server.stdout.on("data", (chunk) => {
    serverLog += chunk.toString();
  });
  server.stderr.on("data", (chunk) => {
    serverLog += chunk.toString();
  });
  server.on("exit", (code, signal) => {
    if (code !== 0 && signal == null) {
      console.error(`[todoapp-playwright] Rails server exited with ${code}.`);
      if (serverLog.trim() !== "") {
        console.error(serverLog.trim());
      }
    }
  });

  await stageAsync("browser readiness", () => waitForReady(`${baseUrl}/todos`, 45_000));
  const specArgs = spec.split(/\s+/).filter(Boolean);
  const result = stage("browser specs", () => run("npx", ["playwright", "test", ...specArgs, "--workers=1"], {
    allowFailure: true,
    env: { ...process.env, BASE_URL: baseUrl },
  }));

  cleanup();
  if (result.status !== 0) {
    printServerLog();
    process.exit(result.status ?? 1);
  }
}

async function resolvePort() {
  if (requestedPort != null) {
    if (!(await isPortAvailable(Number(requestedPort)))) {
      throw new Error(`Requested RailsHx Playwright port ${requestedPort} is already in use.`);
    }
    return requestedPort;
  }

  var candidate = Number(defaultPort);
  for (let attempt = 0; attempt < 20; attempt += 1) {
    if (await isPortAvailable(candidate)) {
      return String(candidate);
    }
    candidate += 1;
  }
  throw new Error(`Could not find a free RailsHx Playwright port starting at ${defaultPort}.`);
}

function isPortAvailable(port) {
  return new Promise((resolvePortCheck) => {
    const probe = net.createServer();
    probe.once("error", () => resolvePortCheck(false));
    probe.once("listening", () => {
      probe.close(() => resolvePortCheck(true));
    });
    probe.listen(port, bind);
  });
}

function ensurePlaywrightBrowser() {
  if (process.env.PLAYWRIGHT_SKIP_BROWSER_INSTALL === "1") {
    return;
  }
  if (hasChromiumBrowser()) {
    return;
  }
  run("npx", ["playwright", "install", "chromium"]);
}

function hasChromiumBrowser() {
  const cacheDir = join(process.env.HOME ?? "", ".cache", "ms-playwright");
  if (!existsSync(cacheDir)) {
    return false;
  }
  return readdirSync(cacheDir).some((entry) => entry.startsWith("chromium-") || entry.startsWith("chromium_headless_shell-"));
}

function ensureSupportedRuby() {
  const result = spawnSync("ruby", ["-e", "print RUBY_VERSION"], {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    process.stderr.write(result.stderr ?? "");
    throw new Error("RailsHx Playwright requires Ruby to be available on PATH.");
  }

  const version = (result.stdout ?? "").trim();
  const [major, minor] = version.split(".").map((part) => Number(part));
  if (Number.isNaN(major) || Number.isNaN(minor) || major < 3 || (major === 3 && minor < 2)) {
    throw new Error(`RailsHx Playwright requires Ruby >= 3.2 for the generated Rails app; current Ruby is ${version}.`);
  }
}

async function waitForReady(url, deadlineMs) {
  const started = Date.now();
  let lastError = "";
  while (Date.now() - started < deadlineMs) {
    const result = spawnSync("curl", ["-fsS", url], {
      cwd: root,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    if (result.status === 0) {
      return;
    }
    lastError = `${result.stdout}\n${result.stderr}`.trim();
    await sleep(500);
  }
  throw new Error(`Rails todoapp did not become ready at ${url}.\n${lastError}`);
}

function cleanup() {
  if (server == null || server.killed) {
    return;
  }
  server.kill("SIGTERM");
}

function printServerLog() {
  if (serverLog.trim() !== "") {
    console.error("[todoapp-playwright] Rails server log:");
    console.error(serverLog.trim());
  }
}

function sleep(ms) {
  return new Promise((resolveSleep) => setTimeout(resolveSleep, ms));
}

function stage(name, callback) {
  currentStage = name;
  process.stdout.write(`[todoapp-playwright] stage: ${name}\n`);
  return callback();
}

async function stageAsync(name, callback) {
  currentStage = name;
  process.stdout.write(`[todoapp-playwright] stage: ${name}\n`);
  return await callback();
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
    encoding: "utf8",
    stdio: options.allowFailure ? ["ignore", "pipe", "pipe"] : "inherit",
  });
  if (options.allowFailure) {
    process.stdout.write(result.stdout ?? "");
    process.stderr.write(result.stderr ?? "");
  }
  if (result.status !== 0 && !options.allowFailure) {
    process.stderr.write(`[todoapp-playwright] failed during ${currentStage}: ${command} ${args.join(" ")}\n`);
    process.exit(result.status ?? 1);
  }
  return result;
}
