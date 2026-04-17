import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

const behindTls = process.env.BEHIND_TLS_PROXY === "1";
const publicHost = process.env.VITE_APP_HOST || "demo2dev.ru";

export default defineConfig({
  plugins: [react()],
  server: {
    // Доступ по домену (не только localhost), иначе Vite: "This host is not allowed"
    allowedHosts: ["demo2dev.ru", "www.demo2dev.ru"],
    ...(behindTls
      ? {
          hmr: {
            protocol: "wss",
            clientPort: 443,
            host: publicHost,
          },
        }
      : {}),
    proxy: {
      "/api": process.env.API_URL || "http://localhost:8000",
      "/health": process.env.API_URL || "http://localhost:8000",
      "/docs": process.env.API_URL || "http://localhost:8000",
      "/redoc": process.env.API_URL || "http://localhost:8000",
      "/openapi.yaml": process.env.API_URL || "http://localhost:8000",
      "/openapi.json": process.env.API_URL || "http://localhost:8000",
    },
  },
});
