import { Ajv2020, type ValidateFunction } from "ajv/dist/2020.js";
import formats from "ajv-formats";
import type { FormatsPlugin } from "ajv-formats";
import type { JobSpec, ProtocolRequest } from "./types.js";
import type { FurnishingState } from "./furnishing-core.js";
const addFormats = formats as unknown as FormatsPlugin;

export const CONTRACT_SCHEMAS = ["worker-event.schema.json", "artifact.schema.json", "job.schema.json", "protocol.schema.json", "furnishing.schema.json"] as const;

function validationMessage(validate: ValidateFunction): string {
  return validate.errors?.map((error) => `${error.instancePath || "/"} ${error.message ?? "is invalid"}`).join("; ") ?? "invalid data";
}

export function createValidation(schemas: Record<string, object>) {
  const readSchema = (name: string): object => {
    const schema = schemas[name];
    if (!schema) throw new Error(`Missing contract schema: ${name}`);
    return schema;
  };
  const ajv = new Ajv2020({ allErrors: true, strict: true });
  addFormats(ajv);
  const eventSchema = readSchema("worker-event.schema.json");
  const artifactSchema = readSchema("artifact.schema.json");
  const jobSchema = readSchema("job.schema.json");
  const protocolSchema = readSchema("protocol.schema.json");
  ajv.addSchema(eventSchema);
  ajv.addSchema(artifactSchema);
  ajv.addSchema(jobSchema);
  ajv.addSchema(readSchema("furnishing.schema.json"));
  const validateProtocol = ajv.compile(protocolSchema);
  const validateFurnishing = ajv.getSchema("https://startup-valley.local/contracts/furnishing.schema.json")!;
  const registeredJobValidator = ajv.getSchema("https://startup-valley.local/contracts/job.schema.json");
  if (!registeredJobValidator) throw new Error("Job schema failed to register");
  const validateJob: ValidateFunction = registeredJobValidator;

  function parseRequest(value: unknown): ProtocolRequest {
    if (!validateProtocol(value) || typeof value !== "object" || value === null || (value as { kind?: unknown }).kind !== "request") {
      throw new Error(`Invalid protocol request: ${validationMessage(validateProtocol)}`);
    }
    return value as ProtocolRequest;
  }

  function parseJobSpec(value: unknown): JobSpec {
    if (!validateJob(value)) throw new Error(`Invalid job specification: ${validationMessage(validateJob)}`);
    return value as JobSpec;
  }

  function parseFurnishingState(value: unknown): FurnishingState {
    if (!validateFurnishing(value)) throw new Error(`Invalid furnishing state: ${validationMessage(validateFurnishing)}`);
    return value as FurnishingState;
  }

  return { parseRequest, parseJobSpec, parseFurnishingState };
}
