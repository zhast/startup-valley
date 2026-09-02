import assert from "node:assert/strict";
import test from "node:test";

import { normalizeKeychainValue } from "../src/credential-store.js";

test("missing keychain values never appear configured", () => {
  assert.equal(normalizeKeychainValue(null), undefined);
  assert.equal(normalizeKeychainValue(undefined), undefined);
  assert.equal(normalizeKeychainValue(""), undefined);
  assert.equal(normalizeKeychainValue("sk-or-example"), "sk-or-example");
});
