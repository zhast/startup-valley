import type { ClockState, SchedulePhase } from "./types.js";

export const MINUTES_PER_DAY = 24 * 60;
export const WORK_START = 8 * 60;
export const LUNCH_START = 12 * 60 + 30;
export const LUNCH_END = 13 * 60 + 30;
export const WORK_END = 17 * 60 + 30;

export function normalizeMinute(value: number): number {
  return Math.max(0, Math.min(MINUTES_PER_DAY - 1, Math.trunc(value)));
}

export function phaseForMinute(minuteOfDay: number): SchedulePhase {
  const minute = normalizeMinute(minuteOfDay);
  if (minute >= LUNCH_START && minute < LUNCH_END) return "lunch";
  if ((minute >= WORK_START && minute < LUNCH_START) || (minute >= LUNCH_END && minute < WORK_END)) return "work";
  return "off";
}

export function normalizeClock(value: Partial<ClockState>): ClockState {
  const minuteOfDay = normalizeMinute(value.minuteOfDay ?? WORK_START);
  const speed = Number.isFinite(value.speed) ? Math.max(0, Math.min(64, Number(value.speed))) : 1;
  return {
    day: Math.max(1, Math.trunc(value.day ?? 1)),
    minuteOfDay,
    speed,
    phase: phaseForMinute(minuteOfDay),
  };
}
