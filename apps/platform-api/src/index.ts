import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { config, envReport } from "./env.js";
import { ingest } from "./ingest.js";
import { jobs } from "./jobs.js";

const app = new Hono();

app.use(
  "/api/*",
  cors({
    origin: [config.appOrigin, config.marketingOrigin],
    allowMethods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
  })
);

app.get("/healthz", (c) => c.json({ ok: true, service: "platform-api" }));

// Wiring probe: reports whether Doppler secrets landed and whether Supabase is reachable.
app.get("/api/v1/status", async (c) => {
  const env = envReport();

  let supabase: { reachable: boolean; detail?: string } = { reachable: false, detail: "SUPABASE_URL not set" };
  if (config.supabaseUrl && config.supabaseAnonKey) {
    try {
      const res = await fetch(`${config.supabaseUrl}/auth/v1/health`, {
        headers: { apikey: config.supabaseAnonKey },
        signal: AbortSignal.timeout(5000),
      });
      supabase = { reachable: res.ok, detail: `auth health ${res.status}` };
    } catch (err) {
      supabase = { reachable: false, detail: err instanceof Error ? err.message : "fetch failed" };
    }
  }

  return c.json({
    service: "platform-api",
    doppler: { configured: env.missing.length === 0, present: env.present, missing: env.missing },
    supabase,
    timestamp: new Date().toISOString(),
  });
});

app.route("/api/v1/jobs", jobs);
app.route("/api/v1/ingest", ingest);

app.onError((err, c) => {
  console.error(err);
  return c.json({ error: "internal error" }, 500);
});

serve({ fetch: app.fetch, port: config.port }, (info) => {
  console.log(`platform-api listening on :${info.port}`);
});
