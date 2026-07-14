import { config } from "./env.js";

// Thin PostgREST client using the service-role key (server-side only).
export async function rest<T>(pathAndQuery: string, init?: { count?: boolean }): Promise<{ data: T; total: number | null }> {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!config.supabaseUrl || !key) throw new Error("Supabase env not configured");

  const res = await fetch(`${config.supabaseUrl}/rest/v1/${pathAndQuery}`, {
    headers: {
      apikey: key,
      authorization: `Bearer ${key}`,
      ...(init?.count ? { prefer: "count=exact" } : {}),
    },
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) throw new Error(`supabase ${res.status}: ${await res.text()}`);

  let total: number | null = null;
  const range = res.headers.get("content-range"); // e.g. "0-19/25892"
  if (range?.includes("/")) {
    const t = range.split("/")[1];
    if (t && t !== "*") total = Number(t);
  }
  return { data: (await res.json()) as T, total };
}
