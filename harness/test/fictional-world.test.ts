import assert from "node:assert/strict";
import { mkdtemp, mkdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { GameDatabase } from "../src/database.js";

test("older branded saves display fictional names and retain their one-time port payout", async () => {
  const root = await mkdtemp(join(tmpdir(), "startup-valley-fictional-world-"));
  const project = join(root, "project");
  await mkdir(project);
  const db = new GameDatabase(join(root, "game.sqlite"), project);
  try {
    db.tycoon.start("crypto", "newsletter", []);
    db.endDay(1);
    db.endDay(2);
    db.tycoon.release("p1");
    for (let day = 3; day <= 6; day++) db.endDay(day);
    db.tycoon.port("p1");
    const sql = db.journey.db;
    const stored = JSON.parse(String(sql.prepare("SELECT staff_json FROM tycoon_products WHERE id='p1'").get()!.staff_json));
    stored.port.shelf = "Whop Mobile";
    sql.prepare("UPDATE tycoon_products SET staff_json=? WHERE id='p1'").run(JSON.stringify(stored));
    const review = JSON.parse(String(sql.prepare("SELECT review_json FROM tycoon_products WHERE id='p1'").get()!.review_json));
    review.reviewers[0].name = "Whop Weekly";
    sql.prepare("UPDATE tycoon_products SET review_json=? WHERE id='p1'").run(JSON.stringify(review));
    sql.prepare("UPDATE company_transactions SET label='Port: Whop Mobile' WHERE id='tycoon:port:p1'").run();
    const original = String(sql.prepare("SELECT staff_json FROM tycoon_products WHERE id='p1'").get()!.staff_json);
    const view = db.journey.state();
    assert.equal(view.tycoon?.history[0]?.port?.shelf, "TownSquare Mobile");
    assert.equal(view.tycoon?.history[0]?.port?.phase, "selling");
    assert.doesNotMatch(JSON.stringify(view), /\bWhop\b/u);
    assert.doesNotMatch(JSON.stringify(db.journey.daySummary(7, 0)), /\bWhop\b/u);
    assert.equal(String(sql.prepare("SELECT staff_json FROM tycoon_products WHERE id='p1'").get()!.staff_json), original, "reading a renamed view must not rewrite the save");
    const before = view.company.cashCents;
    db.endDay(7);
    const paid = db.journey.state().company.cashCents;
    assert.ok(paid > before, "legacy shelf still pays its pending sale");
    assert.equal(db.journey.state().tycoon?.history[0]?.port?.phase, "sold");
    db.endDay(7);
    assert.equal(db.journey.state().company.cashCents, paid, "the sale still pays only once");
  } finally {
    db.close();
  }
});
