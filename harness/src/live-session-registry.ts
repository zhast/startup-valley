export interface SteerableSession {
  steer(message: string): Promise<void>;
}

export class LiveSessionRegistry<T extends SteerableSession> {
  readonly #sessions = new Map<string, T>();

  set(jobId: string, session: T): void {
    this.#sessions.set(jobId, session);
  }

  get(jobId: string): T | undefined {
    return this.#sessions.get(jobId);
  }

  delete(jobId: string): void {
    this.#sessions.delete(jobId);
  }

  async steer(jobId: string, message: string): Promise<void> {
    const session = this.#sessions.get(jobId);
    if (!session) throw new Error("Job does not have a live Pi session");
    await session.steer(message);
  }
}
