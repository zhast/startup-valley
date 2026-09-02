import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { Ajv2020, type ValidateFunction } from "ajv/dist/2020.js";
import type { FormatsPlugin } from "ajv-formats";

import type { JobSpec, ProtocolRequest } from "./types.js";

function readSchema(name: string): object {
  const moduleDirectory = dirname(fileURLToPath(import.meta.url));
  const path = join(moduleDirectory, "..", "..", "contracts", name);
  return JSON.parse(readFileSync(path, "utf8")) as object;
}

function validationMessage(validate: ValidateFunction): string {
  return validate.errors?.map((error) => `${error.instancePath || "/"} ${error.message ?? "is invalid"}`).join("; ") ?? "invalid data";
}

const ajv = new Ajv2020({ allErrors: true, strict: true });
const require = createRequire(import.meta.url);
const addFormats = require("ajv-formats") as FormatsPlugin;
addFormats(ajv);
const eventSchema = readSchema("worker-event.schema.json");
const artifactSchema = readSchema("artifact.schema.json");
const jobSchema = readSchema("job.schema.json");
const protocolSchema = readSchema("protocol.schema.json");
ajv.addSchema(eventSchema);
ajv.addSchema(artifactSchema);
ajv.addSchema(jobSchema);
const validateProtocol = ajv.compile(protocolSchema);
const registeredJobValidator = ajv.getSchema("https://startup-valley.local/contracts/job.schema.json");
if (!registeredJobValidator) throw new Error("Job schema failed to register");
const validateJob: ValidateFunction = registeredJobValidator;

export function parseRequest(value: unknown): ProtocolRequest {
  if (!validateProtocol(value) || typeof value !== "object" || value === null || (value as { kind?: unknown }).kind !== "request") {
    throw new Error(`Invalid protocol request: ${validationMessage(validateProtocol)}`);
  }
  return value as ProtocolRequest;
}

export function parseJobSpec(value: unknown): JobSpec {
  if (!validateJob(value)) throw new Error(`Invalid job specification: ${validationMessage(validateJob)}`);
  return value as JobSpec;
}
