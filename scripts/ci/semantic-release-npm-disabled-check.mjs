#!/usr/bin/env node

import * as disabledPlugin from "../release/semantic-release-npm-disabled/index.mjs";

const expectedMessage =
  "@semantic-release/npm is disabled: RubyHx publishes only through the reviewed GitHub Releases workflow.";

for (const hook of ["verifyConditions", "prepare", "publish", "addChannel"]) {
  try {
    disabledPlugin[hook]();
    throw new Error(`${hook} unexpectedly allowed npm registry publication`);
  } catch (error) {
    if (!(error instanceof Error) || error.message !== expectedMessage) {
      throw error;
    }
  }
}

console.log("[semantic-release-npm-disabled] OK: every registry publication hook fails closed");
