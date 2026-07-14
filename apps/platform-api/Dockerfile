# Build context = repo root (set via railway.json dockerfilePath)
FROM node:22-slim AS base
RUN corepack enable \
  && apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates gnupg \
  && curl -Ls https://cli.doppler.com/install.sh | sh \
  && apt-get clean
WORKDIR /repo

FROM base AS build
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY apps/platform-api/package.json apps/platform-api/
RUN pnpm install --frozen-lockfile --filter @ae-hq/platform-api
COPY apps/platform-api apps/platform-api
RUN pnpm --filter @ae-hq/platform-api build

FROM base AS runtime
ENV NODE_ENV=production
COPY --from=build /repo /repo
WORKDIR /repo/apps/platform-api
# DOPPLER_TOKEN is injected by Railway; doppler resolves all other secrets at boot.
CMD ["doppler", "run", "--", "node", "dist/index.js"]
