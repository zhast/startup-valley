import type { GameDatabase } from "./database-core.js";
import type { FurnishingUpdate } from "./furnishing-core.js";
import type { StoryOperation, StoryTravel } from "./story.js";
import type { ProtocolRequest } from "./types.js";
import { stringParameter, numberParameter, staffParameter, optionalIntegerParameter, optionalStringParameter } from "./request-parameters.js";

export const UNHANDLED = Symbol("unhandled offline request");
export interface OfflineHooks {
  isBusy?: () => boolean;
  startNextQueuedJob?: () => Promise<string | undefined>;
}
/** The same authoritative routes serve native stdio and the offline browser Worker. */
export async function dispatchOffline(request: ProtocolRequest, database: GameDatabase, hooks: OfflineHooks = {}): Promise<unknown> {
  switch (request.method) {
    case "story.travel":
    case "story.acceptOpportunity": {
      const replayed = request.method === "story.travel"
        ? database.story.travel(request.params as unknown as StoryTravel)
        : database.story.acceptOpportunity(request.params as unknown as StoryOperation);
      const { journey, furnishing } = database.bootstrap();
      return { journey, furnishing, replayed };
    }
    case "furnishing.update":
      return database.furnishing.update(request.params as unknown as FurnishingUpdate);
    case "hiring.complete":
      database.journey.hire(stringParameter(request, "employeeId", 64), database.clockState().day);
      return database.bootstrap();
    case "milestone.complete":
    case "milestone.override":
      return { journey: database.journey.complete(stringParameter(request, "jobId", 64), request.method === "milestone.override", database.clockState().day), dailySpend: database.dailySpend() };
    case "chapter.continue":
      return { journey: database.journey.continueChapter(), dailySpend: database.dailySpend() };
    case "game.save":
      database.journey.savePlayer(request.params);
      return { saved: true };
    case "day.end": {
      if (hooks.isBusy?.()) throw new Error("Wait for active AI work to finish before ending the day");
      const result = database.endDay(numberParameter(request, "day"));
      await hooks.startNextQueuedJob?.();
      return { ...result, journey: database.journey.state(), dailySpend: database.dailySpend() };
    }
    case "tycoon.start":
      return {
        journey: database.tycoon.start(
          stringParameter(request, "topicId", 64),
          stringParameter(request, "typeId", 64),
          staffParameter(request),
          optionalIntegerParameter(request, "pricePercent"),
          optionalStringParameter(request, "marketing"),
          optionalStringParameter(request, "engine"),
          optionalStringParameter(request, "focus"),
          optionalStringParameter(request, "audience"),
          optionalStringParameter(request, "size"),
        ),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.release":
      return { journey: database.tycoon.release(stringParameter(request, "productId", 32)), dailySpend: database.dailySpend() };
    case "tycoon.acceptContract":
      return { journey: database.tycoon.acceptContract(), dailySpend: database.dailySpend() };
    case "tycoon.patch":
      return { journey: database.tycoon.patch(stringParameter(request, "productId", 32)), dailySpend: database.dailySpend() };
    case "tycoon.sequel":
      return { journey: database.tycoon.sequel(stringParameter(request, "productId", 32)), dailySpend: database.dailySpend() };
    case "tycoon.award":
      return { journey: database.tycoon.award(stringParameter(request, "productId", 32)), dailySpend: database.dailySpend() };
    case "tycoon.port":
      return { journey: database.tycoon.port(stringParameter(request, "productId", 32)), dailySpend: database.dailySpend() };
    case "tycoon.localize":
      return { journey: database.tycoon.localize(stringParameter(request, "productId", 32)), dailySpend: database.dailySpend() };
    case "tycoon.train":
      return {
        journey: database.tycoon.train(stringParameter(request, "staffId", 32), stringParameter(request, "stat", 16)),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.research":
      return {
        journey: database.tycoon.research(stringParameter(request, "kind", 16), stringParameter(request, "id", 64)),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.buyUpgrade":
      return {
        journey: database.tycoon.buyUpgrade(stringParameter(request, "id", 64)),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.buyEngine":
      return {
        journey: database.tycoon.buyEngine(stringParameter(request, "id", 64)),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.expandOffice": {
      const journey = database.tycoon.expandOffice();
      return { journey, furnishing: database.furnishing.state(), dailySpend: database.dailySpend() };
    }
    case "tycoon.takeLoan":
      return { journey: database.tycoon.takeLoan(), dailySpend: database.dailySpend() };
    case "tycoon.signPublisher":
      return { journey: database.tycoon.signPublisher(), dailySpend: database.dailySpend() };
    case "tycoon.bookBooth":
      return { journey: database.tycoon.bookBooth(), dailySpend: database.dailySpend() };
    case "tycoon.takeTownDay":
      return { journey: database.tycoon.takeTownDay(), dailySpend: database.dailySpend() };
    case "tycoon.showPressDemo":
      return { journey: database.tycoon.showPressDemo(), dailySpend: database.dailySpend() };
    case "tycoon.addFeature":
      return { journey: database.tycoon.addFeature(), dailySpend: database.dailySpend() };
    case "tycoon.setDayPlan":
      return { journey: database.tycoon.setDayPlan(stringParameter(request, "stat", 16)), dailySpend: database.dailySpend() };
    case "tycoon.fixBugs":
      return { journey: database.tycoon.fixBugs(), dailySpend: database.dailySpend() };
    case "tycoon.crunch":
      return { journey: database.tycoon.crunch(), dailySpend: database.dailySpend() };
    case "tycoon.earlyAccess":
      return { journey: database.tycoon.earlyAccess(), dailySpend: database.dailySpend() };
    case "tycoon.cancelBuild":
      return { journey: database.tycoon.cancelBuild(), dailySpend: database.dailySpend() };
    case "tycoon.slipDay":
      return { journey: database.tycoon.slipDay(), dailySpend: database.dailySpend() };
    case "tycoon.pivot":
      return {
        journey: database.tycoon.pivot(stringParameter(request, "topicId", 64), stringParameter(request, "typeId", 64)),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.playtest":
      return { journey: database.tycoon.playtest(), dailySpend: database.dailySpend() };
    case "tycoon.assignTeam":
      return { journey: database.tycoon.assignTeam(staffParameter(request)), dailySpend: database.dailySpend() };
    case "tycoon.researchSpike":
      return { journey: database.tycoon.researchSpike(), dailySpend: database.dailySpend() };
    case "tycoon.salePrice":
      return {
        journey: database.tycoon.salePrice(stringParameter(request, "productId", 32), numberParameter(request, "pricePercent")),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.letGo":
      database.tycoon.letGo(stringParameter(request, "staffId", 32));
      return database.bootstrap();
    case "tycoon.setPace":
      return {
        journey: database.tycoon.setPace(stringParameter(request, "staffId", 32), stringParameter(request, "pace", 16)),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.listCatalog":
      return {
        journey: database.tycoon.listCatalog(stringParameter(request, "productId", 32)),
        dailySpend: database.dailySpend(),
      };
    case "tycoon.delistCatalog":
      return { journey: database.tycoon.delistCatalog(), dailySpend: database.dailySpend() };
    case "tycoon.makeTrailer":
      return { journey: database.tycoon.makeTrailer(stringParameter(request, "productId", 32)), dailySpend: database.dailySpend() };
    case "tycoon.writeDiary":
      return { journey: database.tycoon.writeDiary(stringParameter(request, "productId", 32)), dailySpend: database.dailySpend() };
    case "bootstrap":
      return database.bootstrap();
    case "clock.set": {
      const clock = database.setClock(
        numberParameter(request, "day"),
        numberParameter(request, "minuteOfDay"),
        numberParameter(request, "speed"),
      );
      const startedJobId = await hooks.startNextQueuedJob?.();
      return { clock, startedJobId };
    }
    default:
      return UNHANDLED;
  }
}
