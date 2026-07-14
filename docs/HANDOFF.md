# ae-hq — Project Handoff

Written 2026-07-14. State of the AccountExecutive.com job-board platform after the first development cycle. Everything below is committed on `main` of `bencrane/ae-hq-new` unless noted.

## Product thesis

Job board for Account Executives, focused on venture-backed technology/software companies. Three data layers:

| Layer | Source | Status |
| --- | --- | --- |
| Demand — who's hiring AEs (jobs, comp, geo) | BrightData LinkedIn jobs export | Loaded (25,892 jobs) |
| Supply — who the AEs are + full work history | Clay (find-people + person-enrichment) | Pipelines live |
| Company quality — stage, funding, investors, growth | Crunchbase (BrightData-shape dataset) | Sample profiled; NOT purchased yet |

## Architecture

pnpm monorepo, three apps:

| App | Path | Deploy | Domain |
| --- | --- | --- | --- |
| Marketing site | `apps/marketing` | Vercel | accountexecutive.com (Vite+React placeholder) |
| Platform app | `apps/platform-app` | Railway | app.accountexecutive.com (Vite+React SPA, served by `serve`) |
| Platform API | `apps/platform-api` | Railway | **api.salesengine.run** (Hono BFF → Supabase) |

- Secrets: Doppler project **`ae-hq-new`**, config **`prd`** (NOT `ae-hq-all` — that name was abandoned). Railway services carry only `DOPPLER_TOKEN` (a prd service token); containers boot via `doppler run` in the Dockerfiles.
- Supabase project: **`ae-dot-com`** (`cewfhhhhbqlkryquztix`), org shyualumvqvkxdduezad.
- Vite gotcha: `VITE_*` values are baked at Docker **build** time (`doppler run -- vite build`). Changing `VITE_API_URL` requires a platform-app redeploy.
- Railway gotcha (cost a debugging cycle): custom build/start commands on a service bypass the Dockerfile `CMD`, so `doppler run` never executes and the container boots with zero secrets while still appearing Online. Both services must use builder=Dockerfile via config-as-code paths (`apps/*/railway.json`), no custom build command, no custom start command. Diagnostic: `GET /api/v1/status` → `doppler.configured` must be `true`; Doppler service-token `last_seen_at` shows whether containers are actually fetching.

## Doppler secrets (`ae-hq-new` / `prd`)

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `PLATFORM_APP_ORIGIN=https://app.accountexecutive.com`, `MARKETING_ORIGIN=https://accountexecutive.com`, `VITE_API_URL=https://api.salesengine.run`, `VITE_PLATFORM_APP_URL=https://app.accountexecutive.com`, `CLAY_INGEST_KEY` (shared secret for ingest endpoints). `PORT` is Railway-injected; never set it.

## Database state (Supabase `ae-dot-com`)

### Dropped legacy prototype
The project originally contained a 22-table prototype (profiles/candidates/jobs/matches/pipelines/etc. with ~1.4k rows of demo data). It was archived **then dropped**. Full DDL: `docs/legacy-prototype/schema.sql`. Full data snapshot: `docs/legacy-prototype/data/*.json` (committed at `b2a833e`). Its ideas (company stage, investor pedigree as match criteria) inform the Crunchbase layer.

### Live tables

| Table | Rows | Purpose / keys |
| --- | --- | --- |
| `raw_brightdata_jobs` | 25,892 | Staging. BrightData NDJSON payloads, unique `job_posting_id`. Transform is re-runnable. |
| `companies` | 9,410 | Canonical. Keyed `linkedin_company_id`. PDL-enriched: `domain` (7,840), `industry` (8,162), `employee_size_range`, `locality/region/country`, `year_founded` (7,109), `pdl_company_id`, `enriched_from`. |
| `jobs` | 25,892 | Canonical. Unique `job_posting_id`, FK `company_id` (25,865 linked), salary parsed where present (2,497), `posted_at` indexed desc. |
| `clay_find_companies` | streaming | Staging. `raw_payload` jsonb, unique generated `clay_company_id`. |
| `clay_find_people` | streaming | Staging. `raw_payload` jsonb, unique generated `linkedin_url` (lowercased, trailing-slash-stripped), indexed generated `company_clay_company_id`. |
| `clay_enriched_people` | streaming | Staging. Full profile+work-history payloads. Unique generated `linkedin_url`, indexed generated `profile_id`. |

RLS: `jobs`/`companies` are public-read (anon select policies). All staging tables RLS-on with NO policies (service-role only). **No cross-table validation on ingest by design** — enriched people need not exist in `clay_find_people`; joins happen at read time.

## API endpoints (live at api.salesengine.run)

- `GET /healthz` — Railway health check.
- `GET /api/v1/status` — wiring probe: Doppler secrets present? Supabase reachable? This is the first thing to check when anything misbehaves.
- `GET /api/v1/jobs` — paginated (`page`, `per_page` ≤100), ordered `posted_at desc`. Filters: `q` (title ilike), `country` (ISO-2), `seniority`, `employment_type`, `company_id`.
- `GET /api/v1/jobs/:jobPostingId` — full record incl. `description_html`.
- `POST /api/v1/ingest/clay/companies` | `/clay/people` | `/clay/enriched-people` — Clay HTTP API targets. Headers: `x-ingest-key: <CLAY_INGEST_KEY>` AND `content-type: application/json`. Body: `{"raw_payload": { ...clay object verbatim... }}` (Clay does NOT unfurl). Upsert semantics on resend. Responses: 200 ok / 401 bad key / 422 missing raw_payload or identity field (`clay_company_id` for companies, `url` for people) / 503 = server env broken (see Railway gotcha).

## Scripts

- `scripts/ingest-brightdata.mts` — streams `.jsonl(.gz)` → `raw_brightdata_jobs`. Run: `doppler run -p ae-hq-new -c prd -- pnpm tsx scripts/ingest-brightdata.mts <file> [snapshot-id]`. Idempotent (upsert on job_posting_id). Note: `.mts` extension required (root package.json is not type:module).

## Cross-repo data-plane work (core-x)

The 9,410 companies were enriched from the core-x Lance data plane, not Clay:
- `s3://data-sink/active/pdl_normalized_companies` (35.4M rows) joined on `linkedin_slug` vs our cleaned LinkedIn URLs.
- Match rate: 87.7% (8,257); usable non-generic domain: 83.3% (7,840); zero slug ambiguity.
- Access pattern: `doppler run -p core-x -c prd` supplies `R2_ACCESS_KEY_ID/R2_SECRET_ACCESS_KEY/R2_ENDPOINT`; read Lance via python (`core-x/.venv`) + duckdb.
- Also available there: `bridge_dsbs_pdl_linkedin`, `companies_canonical`, `pdl_companies` (raw, has `linkedin_url`).

## Desktop artifacts (not in repo)

- `~/Desktop/ae-hq-companies.csv` — all 9,410 companies, cleaned canonical LinkedIn URLs (`https://www.linkedin.com/company/<slug>`), for Clay find-people sourcing.
- `~/Desktop/ae-hq-companies-needs-clay.csv` — 1,570 companies needing Clay domain enrichment (1,153 no PDL match + 417 matched-but-generic/no domain).
- `~/Downloads/snap_mra6u8np2o8pr3qwov.jsonl.gz` — original BrightData export (58MB, 25,892 rows).
- `~/Downloads/Crunchbase companies information.json` — 1,000-record Crunchbase sample (see below).

## Crunchbase (next major workstream — NOT started)

Sample profiled: company-centric records with embedded `funding_rounds` (summary: total USD, last type/date, count), `funding_rounds_list[]`, `investors[]`, `founders[]`, growth/heat scores, web traffic, `ipo_status`, tech stack. Identity: `uuid` (100%), `company_id` slug (97%). Join paths to our companies: LinkedIn URL inside `social_media_links[]` (~88%) and `website` domain vs PDL-enriched `domain` (~99%) — two independent keys.

Plan when purchased: staging table `crunchbase_companies` (raw_payload jsonb, unique `uuid`, generated columns for slug/linkedin-slug/domain), then transform onto `companies`: `funding_total_usd`, `last_funding_type`, `last_funding_at`, `num_funding_rounds`, `investor_names[]`, `ipo_status`, `cb_rank`, `growth_score`. Open questions for the operator: delivery mechanism (bulk file vs push), record count, and whether the purchase is pre-filtered to venture-backed tech.

## Known open items

1. Crunchbase purchase + ingest + transform (above).
2. The 1,570-company Clay domain-enrichment run (CSV ready on Desktop).
3. Clay find-people + enrichment runs are operator-driven; data lands in staging as it streams. Normalization of `clay_enriched_people.experience[]` into a canonical work-history model is future work (join keys: person `url`, `experience[].org_id` ↔ `companies.linkedin_company_id`, `experience[].company_domain` ↔ `companies.domain`).
4. Platform-app is a wiring-proof page only; marketing is a placeholder. No product UI yet.
5. Operator mentioned AE work-history context "living elsewhere" — deliberately deferred, not yet discussed in detail.

## Commit log of this cycle

`9cf1e62` scaffold → `e08ee7f` doppler rename → `ba86b5f` BrightData loader → `b2a833e` legacy archive → `23219e6` jobs schema+API → `5a40aae` Clay ingest → `f7c40d3` raw_payload body shape → `8096c22` enriched-people endpoint.
