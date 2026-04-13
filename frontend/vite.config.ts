import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    // Доступ по домену (не только localhost), иначе Vite: "This host is not allowed"
    allowedHosts: ["demo2dev.ru", "www.demo2dev.ru"],
    proxy: {
      "/api": process.env.API_URL || "http://localhost:8000",
      "/docs": process.env.API_URL || "http://localhost:8000",
      "/redoc": process.env.API_URL || "http://localhost:8000",
      "/openapi.json": process.env.API_URL || "http://localhost:8000",
    },
  },
});
