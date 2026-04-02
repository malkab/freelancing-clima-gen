import { defineConfig } from "vite";

export default defineConfig({
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