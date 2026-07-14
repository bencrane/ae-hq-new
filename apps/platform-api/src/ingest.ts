import { Hono } from "hono";
import { config } from "./env.js";

// Clay HTTP API pushes one raw payload object per request.
// Auth: x-ingest-key shared secret (CLAY_INGEST_KEY in Doppler).
export const ingest = new Hono();

ingest.use("*", async (c, next) => {
  const key = process.env.CLAY_INGEST_KEY;
  if (!key) return c.json({ error: "ingest not configured" }, 503);
  if (c.req.header("x-ingest-key") !== key) return c.json({ error: "unauthorized" }, 401);
  await next();
});

async function upsert(table: string, conflictColumn: string, payload: unknown) {
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  const res = await fetch(`${config.supabaseUrl}/rest/v1/${table}?on_conflict=${conflictColumn}`, {
    method: "POST",
    headers: {
      apikey: serviceKey,
      authorization: `Bearer ${serviceKey}`,
      "content-type": "application/json",
      prefer: "resolution=merge-duplicates,return=minimal",
    },
    body: JSON.stringify({ raw_payload: payload, updated_at: new Date().toISOString() }),
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) throw new Error(`supabase ${res.status}: ${await res.text()}`);
}

ingest.post("/clay/companies", async (c) => {
  const payload = await c.req.json();
  if (payload?.clay_company_id == null) {
    return c.json({ error: "clay_company_id missing from payload" }, 422);
  }
  await upsert("clay_find_companies", "clay_company_id", payload);
  return c.json({ ok: true, clay_company_id: payload.clay_company_id });
});

ingest.post("/clay/people", async (c) => {
  const payload = await c.req.json();
  if (typeof payload?.url !== "string" || payload.url.length === 0) {
    return c.json({ error: "url missing from payload" }, 422);
  }
  await upsert("clay_find_people", "linkedin_url", payload);
  return c.json({ ok: true, url: payload.url });
});
