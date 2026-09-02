import assert from "node:assert/strict";
import test from "node:test";

import {
  LUNCH_END,
  LUNCH_START,
  WORK_END,
  WORK_START,
  phaseForMinute,
} from "../src/day-clock.js";

test("work, lunch, and off-shift boundaries are exact", () => {
  assert.equal(phaseForMinute(WORK_START - 1), "off");
  assert.equal(phaseForMinute(WORK_START), "work");
  assert.equal(phaseForMinute(LUNCH_START - 1), "work");
  assert.equal(phaseForMinute(LUNCH_START), "lunch");
  assert.equal(phaseForMinute(LUNCH_END - 1), "lunch");
  assert.equal(phaseForMinute(LUNCH_END), "work");
  assert.equal(phaseForMinute(WORK_END - 1), "work");
  assert.equal(phaseForMinute(WORK_END), "off");
});
