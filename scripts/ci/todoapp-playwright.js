#!/usr/bin/env node

const { existsSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawn, spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const appDir = join(root, "test", ".generated", "rails_integration");
const port = process.env.PORT ?? process.env.RAILSHX_PLAYWRIGHT_PORT ?? "3100";
const bind = process.env.BIND ?? "127.0.0.1";
const baseUrl = process.env.BASE_URL ?? `http://${bind}:${port}`;
const spec = process.env.RAILSHX_PLAYWRIGHT_SPEC ?? "examples/todoapp_rails/e2e";

let server = null;

main().catch((error) => {
  console.error(error.stack ?? error.message ?? String(error));
  cleanup();
  process.exit(1);
});

async function main() {
  run(process.execPath, [join(root, "scripts", "rails", "todoapp.js"), "prepare"], {
    env: { ...process.env, PORT: port, BIND: bind },
  });

  ensurePlaywrightBrowser();

  server = spawn("bundle", ["exec", "ruby", "bin/rails", "server", "-b", bind, "-p", port], {
    cwd: appDir,
    env: process.env,
    stdio: ["ignore", "pipe", "pipe"],
  });

  let serverLog = "";
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

  await waitForReady(`${baseUrl}/todos`, 45_000);
  const specArgs = spec.split(/\s+/).filter(Boolean);
  const result = run("npx", ["playwright", "test", ...specArgs, "--workers=1"], {
    allowFailure: true,
    env: { ...process.env, BASE_URL: baseUrl },
  });

  cleanup();
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

function ensurePlaywrightBrowser() {
  if (process.env.PLAYWRIGHT_SKIP_BROWSER_INSTALL === "1") {
    return;
  }
  if (existsSync(join(process.env.HOME ?? "", ".cache", "ms-playwright"))) {
    return;
  }
  run("npx", ["playwright", "install", "chromium"]);
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

function sleep(ms) {
  return new Promise((resolveSleep) => setTimeout(resolveSleep, ms));
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
    process.exit(result.status ?? 1);
  }
  return result;
}
