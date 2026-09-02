import assert from "node:assert/strict";
import test from "node:test";

import { LiveSessionRegistry } from "../src/live-session-registry.js";

test("steering an in-flight job reuses its attached live Pi session", async () => {
  const messages: string[] = [];
  const fakeSession = {
    async steer(message: string): Promise<void> {
      messages.push(message);
    },
  };
  const registry = new LiveSessionRegistry<typeof fakeSession>();
  registry.set("active-job", fakeSession);

  await registry.steer("active-job", "Keep the same session and add one risk.");

  assert.equal(registry.get("active-job"), fakeSession);
  assert.deepEqual(messages, ["Keep the same session and add one risk."]);
  await assert.rejects(registry.steer("other-job", "Do not create a session"), /live Pi session/u);
});
