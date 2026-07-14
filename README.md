# ae-hq

Job board platform monorepo (pnpm workspaces).

| App | Path | Deploys to | Stack |
| --- | --- | --- | --- |
| Marketing site | `apps/marketing` | Vercel | Vite + React |
| Platform app | `apps/platform-app` | Railway | Vite + React SPA (static, served by `serve`) |
| Platform API | `apps/platform-api` | Railway | Hono BFF → Supabase |

Secrets live in Doppler project **`ae-hq-all`**. Nothing reads `.env` files in deployed environments — the API and app containers boot via `doppler run` using the `DOPPLER_TOKEN` each Railway service is given.

## Local dev

```sh
pnpm install
doppler setup   # project: ae-hq-all, config: dev
doppler run -- pnpm dev:api    # :8080
doppler run -- pnpm dev:app    # :5173
pnpm dev:marketing             # :5174
```

## Required Doppler secrets (`ae-hq-all`)

| Key | Used by | Purpose |
| --- | --- | --- |
| `SUPABASE_URL` | platform-api | Supabase project URL |
| `SUPABASE_ANON_KEY` | platform-api | Public anon key (also used by the status probe) |
| `SUPABASE_SERVICE_ROLE_KEY` | platform-api | Server-only privileged key |
| `PLATFORM_APP_ORIGIN` | platform-api | CORS allow-origin, e.g. `https://app.example.com` |
| `MARKETING_ORIGIN` | platform-api | CORS allow-origin, e.g. `https://example.com` |
| `VITE_API_URL` | platform-app | Public URL of platform-api (baked at build) |
| `VITE_PLATFORM_APP_URL` | marketing | Public URL of platform-app |

`PORT` is injected by Railway; do not set it in Doppler.

## Railway setup (two services, one repo)

For each of `platform-api` and `platform-app`:

1. New service → GitHub repo `bencrane/ae-hq-new`.
2. Settings → **Config-as-code path**: `apps/platform-api/railway.json` (or `apps/platform-app/railway.json`). Root directory stays repo root — the Dockerfiles expect the full repo as build context.
3. Variables → add `DOPPLER_TOKEN` (a Doppler **service token** scoped to `ae-hq-all` / the right config).

The API container runs `doppler run -- node dist/index.js`, so all secrets resolve at boot. The app container resolves `VITE_*` at **build** time (`doppler run -- vite build`) — redeploy after changing `VITE_API_URL`.

## Vercel setup (marketing)

1. Import repo, set **Root Directory** = `apps/marketing` (vercel.json there supplies pnpm-workspace-aware install/build commands).
2. Either add `VITE_PLATFORM_APP_URL` directly in Vercel env vars, or install the Doppler↔Vercel integration on `ae-hq-all`.

## Verifying the wiring

- `GET <api>/healthz` → `{ ok: true }` (Railway health check target).
- `GET <api>/api/v1/status` → reports which Doppler secrets landed and whether Supabase's auth health endpoint is reachable.
- The platform-app home page calls `/api/v1/status` and renders the same report — one page proves app → API → Doppler → Supabase end-to-end.
