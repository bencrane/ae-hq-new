// Stream a BrightData .jsonl(.gz) export into public.raw_brightdata_jobs.
// Usage: doppler run -- pnpm tsx scripts/ingest-brightdata.ts <file.jsonl[.gz]> [snapshot-id]
import { createReadStream } from "node:fs";
import { basename } from "node:path";
import { createInterface } from "node:readline";
import { createGunzip } from "node:zlib";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not set (run via doppler run)");
  process.exit(1);
}

const file = process.argv[2];
if (!file) {
  console.error("usage: ingest-brightdata.ts <file.jsonl[.gz]> [snapshot-id]");
  process.exit(1);
}
const snapshot = process.argv[3] ?? basename(file).replace(/\.jsonl(\.gz)?$/, "");

const BATCH = 500;
let batch: { job_posting_id: string; payload: unknown; source_snapshot: string }[] = [];
let sent = 0;
let skipped = 0;

async function flush() {
  if (batch.length === 0) return;
  const rows = batch;
  batch = [];
  const res = await fetch(`${SUPABASE_URL}/rest/v1/raw_brightdata_jobs?on_conflict=job_posting_id`, {
    method: "POST",
    headers: {
      apikey: SERVICE_KEY!,
      authorization: `Bearer ${SERVICE_KEY}`,
      "content-type": "application/json",
      prefer: "resolution=merge-duplicates,return=minimal",
    },
    body: JSON.stringify(rows),
  });
  if (!res.ok) {
    throw new Error(`insert failed (${res.status}): ${await res.text()}`);
  }
  sent += rows.length;
  process.stdout.write(`\rupserted ${sent}`);
}

const input = file.endsWith(".gz")
  ? createReadStream(file).pipe(createGunzip())
  : createReadStream(file);

for await (const line of createInterface({ input, crlfDelay: Infinity })) {
  if (!line.trim()) continue;
  const record = JSON.parse(line);
  const id = record.job_posting_id;
  if (!id) {
    skipped++;
    continue;
  }
  batch.push({ job_posting_id: String(id), payload: record, source_snapshot: snapshot });
  if (batch.length >= BATCH) await flush();
}
await flush();
console.log(`\ndone: ${sent} upserted, ${skipped} skipped (no job_posting_id), snapshot=${snapshot}`);
