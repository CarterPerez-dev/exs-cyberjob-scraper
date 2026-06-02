---------------
# CertScout

A command-line web scraper, written in Elixir, that pulls cybersecurity job
postings from public hiring APIs, isolates the genuine cybersecurity roles, and
reports which certifications employers ask for most. It produces a clean
Markdown report and raw JSON/CSV data. Every number it prints is the real count
it pulled; nothing is fabricated.

## What it does

1. Fetches job postings from one or more pluggable sources (concurrently, with
   polite rate limiting and backoff).
2. Deduplicates them and isolates the cybersecurity subset with a precise
   title/role classifier.
3. Scans each posting's full text for a configurable list of certifications.
4. Ranks the certifications by how many postings mention them and computes each
   one's share of cybersecurity postings.
5. Writes raw data to `output/data/` (JSON + CSV) and a report to
   `output/REPORT.md`, with each top certification's real logo embedded.

## Sources

Sources are pluggable. The defaults need no keys.

| Source | Auth | Notes |
|--------|------|-------|
| `workday` | none | Enterprise/defense Workday boards; keyword search, paginated, full descriptions. The volume engine. |
| `greenhouse` | none | Greenhouse public boards; one request returns every posting with its description. |
| `lever` | none | Lever public postings. |
| `ashby` | none | Ashby public job boards. |
| `remoteok` | none | Single public feed; small, good for a quick smoke test. |
| `usajobs` | free key | Federal/DoD postings, the richest certification source. Set `USAJOBS_API_KEY` and `USAJOBS_EMAIL`. |
| `adzuna` | free key | Market-wide keyword search, highest raw volume. Set `ADZUNA_APP_ID` and `ADZUNA_APP_KEY`. |

Default sources: `workday`, `greenhouse`.

## Requirements

Either Elixir 1.18+ on your machine, or Docker. The Justfile uses your local
`mix` if it is installed and otherwise runs everything inside the official
`elixir` Docker image, so a fresh clone needs nothing but Docker.

## Usage

```sh
just setup        # install deps and compile (run once)
just test         # run the test suite
just run          # scrape with defaults (workday + greenhouse)
just demo         # fast greenhouse-only run
just build        # build the standalone ./certscout escript
```

Pass options straight through:

```sh
just run --sources greenhouse,workday --target 8000 --top 10
just run --sources greenhouse --output reports/run1
```

### Options

```
--sources a,b,c     Sources to scrape
--terms "x,y"       Search terms for keyword sources
--target N | all    Cap on cybersecurity postings to analyze (default 12000)
--top N             Number of certifications in the report (default 12)
--concurrency N     Max concurrent requests (default 24)
--delay MS          Max jitter delay per request in ms (default 25)
--output DIR        Output directory (default output)
--all               Analyze every posting, skip the cybersecurity filter
--country CC        Country code for Adzuna (default us)
--boards-file F     Override Greenhouse board tokens (one per line)
--workday-file F    Override Workday sites (lines: tenant,datacenter,site)
--lever-file F      Override Lever companies (one per line)
--ashby-file F      Override Ashby orgs (one per line)
--certs-file F      Override certification catalogue (JSON array)
```

## Output

```
output/
  REPORT.md                 ranked report with logos, counts, and shares
  data/
    certifications.csv      rank, certification, issuer, postings, percent
    certifications.json     same ranking as JSON
    postings.json           analyzed cybersecurity postings + matched certs
    postings.csv            same postings as CSV
    summary.json            run metadata and the top certifications
  assets/                   downloaded certification logos
```

## Customizing

The certification catalogue lives in `lib/cert_scout/certifications.ex`. To scan
for a different set without editing code, pass `--certs-file` a JSON array of
`{slug, name, issuer, aliases, logo}` objects. To point a source at different
companies, use the `--*-file` overrides.

## Notes on conduct

CertScout only calls documented public hiring APIs, sends a descriptive
user-agent, limits concurrency, jitters requests, and backs off on HTTP 429. It
does not attempt to defeat anti-bot protections. Respect each site's terms of
service and robots policy before pointing it somewhere new.
