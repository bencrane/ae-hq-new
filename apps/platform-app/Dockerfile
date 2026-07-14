# Build context = repo root (set via railway.json dockerfilePath)
FROM node:22-slim AS base
RUN corepack enable \
  && apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates gnupg \
  && curl -Ls https://cli.doppler.com/install.sh | sh \
  && apt-get clean
WORKDIR /repo

FROM base AS build
# Vite envs (VITE_*) are baked at build time — doppler resolves them via DOPPLER_TOKEN.
ARG DOPPLER_TOKEN
ENV DOPPLER_TOKEN=$DOPPLER_TOKEN
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY apps/platform-app/package.json apps/platform-app/
RUN pnpm install --frozen-lockfile --filter @ae-hq/platform-app
COPY apps/platform-app apps/platform-app
RUN doppler run -- pnpm --filter @ae-hq/platform-app build

FROM base AS runtime
ENV NODE_ENV=production
COPY --from=build /repo /repo
WORKDIR /repo/apps/platform-app
CMD ["pnpm", "start"]
