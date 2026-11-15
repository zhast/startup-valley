import { defineConfig } from "vite";
import { resolve } from "node:path";

export default defineConfig({
  base: "./",
  publicDir: "public",
  plugins: [{
    name: "offline-worker-boundary",
    generateBundle() {
      const forbidden = /(?:^node:|__vite-browser-external|\/node_modules\/(?:@earendil-works|@napi-rs)\/|\/harness\/src\/(?:main|database|furnishing|validation|credential-store|grok-auth|pi-worker-adapter|tools|path-guard)\.ts$)/;
      for (const id of this.getModuleIds()) {
        if (forbidden.test(id)) this.error(`Native or provider module entered the browser worker: ${id}`);
      }
    },
  }],
  build: {
    target: "es2022",
    emptyOutDir: true,
    assetsInlineLimit: 0,
    minify: true,
    // The single owner Worker loads the simulation and SQLite together.
    chunkSizeWarningLimit: 1000,
    rollupOptions: {
      input: resolve(import.meta.dirname, "src/worker.ts"),
      output: { format: "es", entryFileNames: "worker.js", assetFileNames: "assets/[name]-[hash][extname]" },
      onwarn(warning, defaultHandler) {
        if (warning.code === "UNRESOLVED_IMPORT") throw new Error(warning.message);
        defaultHandler(warning);
      },
    },
  },
});
