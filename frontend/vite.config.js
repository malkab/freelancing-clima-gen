import { defineConfig } from "vite";
import { existsSync, readdirSync } from "node:fs";
import { extname, join, relative, resolve } from "node:path";

function collectHtmlEntries(dirAbsolutePath, rootAbsolutePath, out = {}) {
  const entries = readdirSync(dirAbsolutePath, { withFileTypes: true });

  for (const entry of entries) {
    const absolutePath = join(dirAbsolutePath, entry.name);

    if (entry.isDirectory()) {
      collectHtmlEntries(absolutePath, rootAbsolutePath, out);
      continue;
    }

    if (entry.isFile() && extname(entry.name) === ".html") {
      const relativePath = relative(rootAbsolutePath, absolutePath);
      const entryKey = relativePath.replace(/\.html$/, "");
      out[entryKey] = absolutePath;
    }
  }

  return out;
}

const rootDir = resolve(__dirname);
const pagesDir = resolve(rootDir, "src/pages");
const pageEntries = existsSync(pagesDir)
  ? collectHtmlEntries(pagesDir, rootDir)
  : {};

export default defineConfig({
  build: {
    // maplibre-gl is heavy and can exceed 500 kB minified.
    // Raise warning threshold to avoid noisy false alarms.
    chunkSizeWarningLimit: 1200,
    rollupOptions: {
      input: {
        index: resolve(rootDir, "index.html"),
        ...pageEntries,
      },
      output: {
        manualChunks(id) {
          if (id.includes("node_modules/maplibre-gl")) {
            return "vendor-maplibre";
          }

          return undefined;
        },
      },
    },
  },
  server: {
    host: true,
    port: 5173,
    strictPort: true,
    headers: {
      "Cache-Control": "no-store",
      "Pragma": "no-cache",
      "Expires": "0",
    },
    proxy: {
      "/api/v1": {
        target: "http://python:8000",
        changeOrigin: true,
      },
      "/martin": {
        target: "http://martin:3000",
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/martin/, ""),
      },
    }
  },
});
