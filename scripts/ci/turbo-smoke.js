#!/usr/bin/env node

const { mkdtempSync, mkdirSync, readFileSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");

const root = resolve(__dirname, "..", "..");
const workDir = mkdtempSync(join(tmpdir(), "railshx-turbo."));
const srcDir = join(workDir, "src");
const outFile = join(workDir, "turbo_client.js");
mkdirSync(srcDir, { recursive: true });

writeFileSync(join(srcDir, "TurboClient.hx"), [
  "import rails.turbo.Turbo;",
  "import rails.turbo.TurboFrameLoading;",
  "import rails.turbo.TurboFrameTarget;",
  "import rails.turbo.TurboStreamAction;",
  "import rails.turbo.TurboVisitAction;",
  "",
  "class TurboClient {",
  "\tstatic function main():Void {",
  "\t\tTurbo.onBeforeVisit(function(event) {",
  "\t\t\tvar url:Null<String> = event.detail.url;",
  "\t\t\tif (url != null && url.indexOf(\"/admin\") == 0) event.preventDefault();",
  "\t\t});",
  "\t\tTurbo.onBeforeFetchRequest(function(event) {",
  "\t\t\tTurbo.addFetchRequestHeader(event, \"X-RailsHx\", \"typed\");",
  "\t\t});",
  "\t\tTurbo.onSubmitEnd(function(event) {",
  "\t\t\tvar ok:Null<Bool> = event.detail.success;",
  "\t\t\tvar form = event.detail.formSubmission == null ? null : event.detail.formSubmission.formElement;",
  "\t\t});",
  "\t\tTurbo.visit(\"/todos\", { action: TurboVisitAction.Replace, frame: \"todos\", acceptsStreamResponse: true });",
  "\t\tvar frame = Turbo.frameById(\"todos\");",
  "\t\tif (frame != null) {",
  "\t\t\tTurbo.setFrameLoading(frame, TurboFrameLoading.Lazy);",
  "\t\t\tTurbo.setFrameTarget(frame, TurboFrameTarget.Top);",
  "\t\t\tTurbo.setFrameSrc(frame, \"/todos\");",
  "\t\t\tTurbo.reloadFrame(frame);",
  "\t\t}",
  "\t\tTurbo.renderStreamMessage(Turbo.stream(TurboStreamAction.Append, \"todos\", \"<div>typed</div>\"));",
  "\t}",
  "}",
  "",
].join("\n"));

run("haxe", [
  "-cp",
  join(root, "std"),
  "-cp",
  srcDir,
  "-main",
  "TurboClient",
  "-js",
  outFile,
  "--dce=full",
]);

const js = readFileSync(outFile, "utf8");
for (const expected of [
  "turbo:before-visit",
  "turbo:before-fetch-request",
  "Object.assign",
  "X-RailsHx",
  "turbo:submit-end",
  "window.Turbo.visit",
  "window.Turbo.renderStreamMessage",
  "turbo-stream",
  "loading",
  "_top",
]) {
  if (!js.includes(expected)) {
    fail(`compiled Turbo client is missing ${expected}`);
  }
}

console.log("[turbo] OK");

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

function fail(message) {
  console.error(`[turbo] ERROR: ${message}`);
  process.exit(1);
}
