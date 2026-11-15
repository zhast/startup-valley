import { defineConfig } from "vite";
import { resolve } from "node:path";

export default defineConfig({
  base: "./",
  publicDir: false,
  build: {
    target: "es2022",
    emptyOutDir: false,
    minify: true,
    lib: { entry: resolve(import.meta.dirname, "src/bridge.ts"), name: "StartupValleyBridge", formats: ["iife"], fileName: () => "bridge.js" },
  },
});
