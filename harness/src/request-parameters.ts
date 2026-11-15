import type { ProtocolRequest } from "./types.js";

export function stringParameter(request: ProtocolRequest, name: string, maxLength = 4000): string {
  const value = request.params[name];
  if (typeof value !== "string" || value.length === 0 || value.length > maxLength) throw new Error(`Parameter ${name} must be a non-empty string`);
  return value;
}

export function staffParameter(request: ProtocolRequest): string[] {
  const value = request.params.staffIds;
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.some((item) => typeof item !== "string")) throw new Error("Parameter staffIds must be an array of strings");
  return value;
}

export function numberParameter(request: ProtocolRequest, name: string): number {
  const value = request.params[name];
  if (typeof value !== "number" || !Number.isFinite(value)) throw new Error(`Parameter ${name} must be a finite number`);
  return value;
}

export function optionalIntegerParameter(request: ProtocolRequest, name: string): number | undefined {
  const value = request.params[name];
  if (value === undefined) return undefined;
  if (typeof value !== "number" || !Number.isInteger(value)) throw new Error(`Parameter ${name} must be an integer`);
  return value;
}

export function optionalStringParameter(request: ProtocolRequest, name: string, maxLength = 64): string | undefined {
  const value = request.params[name];
  if (value === undefined) return undefined;
  if (typeof value !== "string" || value.length === 0 || value.length > maxLength) throw new Error(`Parameter ${name} must be a non-empty string`);
  return value;
}

