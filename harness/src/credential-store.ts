import { AsyncEntry } from "@napi-rs/keyring";

const SERVICE = "dev.startup-valley.game";
const ACCOUNT = "openrouter";

export interface CredentialStore {
  hasOpenRouterKey(): Promise<boolean>;
  getOpenRouterKey(): Promise<string | undefined>;
  setOpenRouterKey(key: string): Promise<void>;
}

export class KeychainCredentialStore implements CredentialStore {
  readonly #entry = new AsyncEntry(SERVICE, ACCOUNT);

  async hasOpenRouterKey(): Promise<boolean> {
    return (await this.#entry.getPassword()) !== undefined;
  }

  async getOpenRouterKey(): Promise<string | undefined> {
    return this.#entry.getPassword();
  }

  async setOpenRouterKey(key: string): Promise<void> {
    const trimmed = key.trim();
    if (trimmed.length < 20 || trimmed.length > 512 || /\s/u.test(trimmed)) {
      throw new Error("The OpenRouter key format is invalid");
    }
    await this.#entry.setPassword(trimmed);
  }
}
