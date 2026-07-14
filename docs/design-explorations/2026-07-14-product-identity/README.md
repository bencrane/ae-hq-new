# AccountExecutive.com — Product Identity Explorations

Parked **2026-07-14**. This folder preserves five distinct visual identities explored for the
AccountExecutive.com career-intelligence platform, so the exploration can be picked back up
exactly as it was.

## Get the designs back up (fastest)

Open the gallery directly — no server needed:

```
open docs/design-explorations/2026-07-14-product-identity/index.html
```

That gallery links to all five live mockups and their screenshots. Every mockup is a
single self-contained HTML file (inline CSS, Google Fonts via `<link>`, no build step,
no JavaScript required), so you can also open any variant on its own:

```
open docs/design-explorations/2026-07-14-product-identity/variant-C.html
```

If a browser blocks the Google Fonts request over `file://`, serve the folder instead:

```
cd docs/design-explorations/2026-07-14-product-identity
python3 -m http.server 8080
# then visit http://localhost:8080/
```

## The five directions

| Variant | Name | One-liner |
| --- | --- | --- |
| A | **The Terminal** | Bloomberg-terminal-for-sales-careers. Near-black, monospace numerals, amber accent, headcount tickers, command-line ask bar. Max data gravity. |
| B | **Swiss Ledger** | Light editorial-institutional. Paper ground, serif display, Swiss grid, ink-blue accent. Category authority. |
| C | **Linear Precision** | Graphite SaaS-clean (Linear/Vercel). Sidebar nav, ⌘K AI command palette centerpiece, SVG sparklines. Strongest acquirer-taste signal. |
| D | **The Broadsheet** | Newspaper of record for the AE profession. Masthead, multi-column data journalism, signal-red accent, alumni-flow infographic. Most shareable. |
| E | **The Scoreboard** | Sports-analytics energy. Navy + volt accent, oversized comp numerals, company "team cards", career leaderboard as transfer market. Most AE-native. |

Each variant renders realistic product content: live AE role listings with OTE comp,
company-quality data (funding stage, investors, sales-headcount growth), alumni
career-path flows ("where reps from X go next"), and an AI ask surface.

## Working direction at time of parking (not locked)

A **remix**: Variant **C**'s application architecture (sidebar, ⌘K AI palette, job-table
density) carrying **B**'s typographic identity (serif display, ledger discipline), with
**A**'s data-delta language (green/red tickers, tabular numerals) inside the data modules.
**D** was reserved as the skin for editorial / report surfaces (e.g. "State of AE Hiring"
pages), not the core app shell.

## Context notes carried from the session

These informed the mockups and matter if the project resumes:

- **Business thesis:** build an acquirer-grade product on the AccountExecutive.com domain
  as a distribution + data asset (category domain + AE work-history graph + live jobs +
  email reach), targeted for sale to a well-capitalized sales-tech buyer. Product
  experience — not monetization via per-listing fees — is the priority.
- **Jobs data:** ~25,892 live AE roles in `raw_brightdata_jobs` (export dated ~2026-07-13),
  ~15.2k US (~59%). The rest is international, retained and filterable.
- **Comp data reality:** a one-time extraction pass over job-description text yields a comp
  signal on ~30.9% of listings, clean OTE on ~8.3%; extracted USD OTE median ≈ $155k. The
  numbers rise sharply once the pool is filtered to curated venture-backed tech companies
  (removes non-tech AE noise like insurance / fire-protection / media sales). UI must show
  "comp undisclosed" honestly where absent — never fabricate.
- **The curated company list is the real spine.** "Not random companies" (venture-backed
  software) does more for on-screen quality than any extraction pass. A reference table
  `us_saas_companies` (~173k rows) exists in Supabase for matching job companies against.
- **Original design-generation note:** the gstack `design` image binary was blocked by
  OpenAI org verification, so these were hand-authored as coded HTML mockups (higher
  fidelity for UI identity work, and they double as a front-end head start).

## Source of record

The originals also live outside the repo at:
`~/.gstack/projects/bencrane-ae-hq-new/designs/product-identity-20260714/`
(includes `design-board.html`, the gstack comparison board). The copies in this folder are
the durable, committed record.
