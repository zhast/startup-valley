import type { SqlDatabase } from "./sql-database.js";
import type { JourneyStore } from "./journey.js";
import type { FurnishingStore } from "./furnishing-core.js";

export type StoryLocation = "office" | "courtyard";
export interface StoryOperation { operationId: string; expectedRevision: number }
export interface StoryTravel extends StoryOperation { destination: StoryLocation }
export interface StoryView {
  revision: number;
  location: StoryLocation;
  courtyardUnlocked: boolean;
  visited: boolean;
  metTheo: boolean;
  opportunity: {
    id: "market_day_kit"; title: string; description: string;
    topicId: "reselling"; typeId: "template_pack";
    status: "locked" | "available" | "accepted" | "developing" | "completed";
    productId: string;
  };
}

/** A bounded offline story beat. The world renders this projection; only the
 * worker may unlock the visit, accept the brief, or associate a real product. */
export class StoryStore {
  constructor(
    private readonly db: SqlDatabase,
    private readonly journey: JourneyStore,
    private readonly furnishing: FurnishingStore,
    private readonly unlockResearch: () => void,
  ) {}

  private row() { return this.db.prepare("SELECT * FROM story_state WHERE id=1").get()!; }
  private linkedProduct(id: string) {
    return this.db.prepare("SELECT id,status FROM tycoon_products WHERE id=? AND topic_id='reselling' AND type_id='template_pack'").get(id);
  }
  view(): StoryView {
    const row = this.row();
    const unlocked = this.journey.releasedProducts() >= 1;
    const product = this.linkedProduct(String(row.opportunity_product_id));
    return {
      revision: Number(row.revision), location: row.location as StoryLocation,
      courtyardUnlocked: unlocked, visited: Boolean(row.visited), metTheo: Boolean(row.met_theo),
      opportunity: {
        id: "market_day_kit", title: "Market Day Kit",
        description: "Theo is helping the weekend makers market. Make a simple planning kit so neighbors can set up their first stall.",
        topicId: "reselling", typeId: "template_pack",
        status: Boolean(row.opportunity_accepted)
          ? product ? product.status === "developing" ? "developing" : "completed" : "accepted"
          : unlocked ? "available" : "locked",
        productId: product ? String(product.id) : "",
      },
    };
  }

  private operation(value: StoryOperation, action: string, run: () => void): boolean {
    if (!value || typeof value.operationId !== "string" || !/^[A-Za-z0-9_-]{1,100}$/u.test(value.operationId) || !Number.isSafeInteger(value.expectedRevision) || value.expectedRevision < 0) throw new Error("Invalid story operation or revision");
    const fingerprint = JSON.stringify([action, value.expectedRevision]);
    return this.journey.transaction(() => {
      const previous = this.db.prepare("SELECT fingerprint FROM story_operations WHERE operation_id=?").get(value.operationId);
      if (previous) {
        if (previous.fingerprint !== fingerprint) throw new Error("Story operation id was already used for a different action");
        return true;
      }
      if (Number(this.row().revision) !== value.expectedRevision) throw new Error("The story changed. Refresh before trying again.");
      run();
      this.db.prepare("INSERT INTO story_operations VALUES (?,?)").run(value.operationId, fingerprint);
      return false;
    });
  }

  travel(value: StoryTravel): boolean {
    if (!value || !["office", "courtyard"].includes(value.destination)) throw new Error("Unknown story destination");
    return this.operation(value, `travel:${value.destination}`, () => {
      const row = this.row();
      if (row.location === value.destination) return;
      if (value.destination === "courtyard" && this.journey.releasedProducts() < 1) throw new Error("Release your first project before visiting the courtyard.");
      this.furnishing.sync();
      const player = JSON.parse(String(this.db.prepare("SELECT player_json FROM company_state WHERE id=1").get()!.player_json)) as Record<string, unknown>;
      const geometry = this.furnishing.geometry;
      const [sx, sy] = geometry.room.player_spawn;
      let x = sx * 32 + 16, y = sy * 32 + 16;
      if (value.destination === "courtyard") {
        this.db.prepare("UPDATE story_state SET return_x=?,return_y=?,return_layout_id=? WHERE id=1").run(
          typeof player.x === "number" ? player.x : x,
          typeof player.y === "number" ? player.y : y,
          geometry.room.id,
        );
        x = 496; y = 560;
      } else if (row.return_layout_id === geometry.room.id && typeof row.return_x === "number" && typeof row.return_y === "number") {
        // Furniture updates are refused outside. Validate nevertheless so old
        // or externally edited saves cannot restore the founder inside a prop.
        const placements = JSON.parse(String(this.db.prepare("SELECT placements_json FROM furnishing_state WHERE id=1").get()!.placements_json));
        const inventory = this.db.prepare("SELECT * FROM furnishing_inventory ORDER BY id").all().map((item) => ({ id: String(item.id), kind: String(item.kind), ownerId: String(item.owner_id), essential: Boolean(item.essential), grant: String(item.grant_id), roleKit: String(item.role_kit) }));
        try {
          geometry.validate(placements, inventory, [{ id: "founder", grid: [Math.floor(row.return_x / 32), Math.floor(row.return_y / 32)], position: [row.return_x, row.return_y] }]);
          x = row.return_x; y = row.return_y;
        } catch { /* a changed/invalid return point uses the safe entrance */ }
      }
      this.db.prepare("UPDATE company_state SET player_json=? WHERE id=1").run(JSON.stringify({ ...player, x, y }));
      this.db.prepare("UPDATE story_state SET location=?,visited=1,revision=revision+1 WHERE id=1").run(value.destination);
    });
  }

  acceptOpportunity(value: StoryOperation): boolean {
    return this.operation(value, "accept:market_day_kit", () => {
      const row = this.row();
      if (Boolean(row.opportunity_accepted)) return;
      if (row.location !== "courtyard" || this.journey.releasedProducts() < 1) throw new Error("Meet Theo in the courtyard first.");
      // The ordinary research catalog owns this grant. It is an introduction,
      // not purchased research, so it adds no paid-research score bonus or cash.
      this.unlockResearch();
      this.db.prepare("UPDATE story_state SET met_theo=1,opportunity_accepted=1,revision=revision+1 WHERE id=1").run();
    });
  }

  /** Called inside the real product-start transaction; never starts work itself. */
  productStarted(id: string, topic: string, type: string): void {
    const row = this.row();
    if (!Boolean(row.opportunity_accepted) || topic !== "reselling" || type !== "template_pack" || this.linkedProduct(String(row.opportunity_product_id))) return;
    this.db.prepare("UPDATE story_state SET opportunity_product_id=?,revision=revision+1 WHERE id=1").run(id);
  }
}
