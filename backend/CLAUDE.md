<!-- AUTO-GENERATED FROM AGENT.md by ep manifest sync -->

---
project_name: "backend"
profile: "A"
stack: "go-1.23"
scope: "backend"
owner: "engineering"
tier_overrides: []
slo:
  tier: "tier-1"
  availability_target: "0.999"
dr:
  rto: "15m"
  rpo: "5m"
resources:
  cpu_limit: "500m"
  memory_limit: "128Mi"
---

# Project Agent Manifest: backend

## 1. Scope & Business Intent
The `backend` microservice is the real-time pricing and computational core of Smart-Bubble-Calc. It ingests public orderbook and ticker feeds from domestic Iranian providers and Nobitex, stores market state in an atomic lock-free cache (`sync/atomic.Pointer`), computes coin intrinsic values and bubbles, calculates legal jewelry purchase breakdowns (9% VAT on Labor + Profit per Iranian tax laws), and serves HTTP/JSON APIs with ETag 304 caching and gzip compression at an ultra-low memory footprint (~15MB RAM).

## 2. Architectural Profile & Boundaries
- **Profile**: A (Backend & Core Services: Hexagonal / DDD)
- **Primary Inputs**:
  - Inbound HTTP REST API (`/api/v1/market`, `/api/v1/calculate/jewelry`, `/api/v1/admin/config`, `/healthz`).
  - Scheduled background ticker polling external market orderbooks.
- **Allowed Outbound Dependencies**:
  - `contracts`: Shared OpenAPI 3.1 contract definitions.
  - Ephemeral containerized test runtimes (`golang:1.23-alpine`).
  - Nobitex and TGJU public orderbook endpoints.
- **Forbidden Dependencies**:
  - No database ORM or direct relational storage dependencies (in-memory atomic cache with external persistence decoupling).
  - No framework UI or client-side packages.

## 3. Local Nx Target Delegations
- `nx lint backend` -> Go static analysis / vetting.
- `nx test backend` -> Comprehensive unit and race test execution.
- `nx build backend` -> Static Linux binary compilation (`bubble-server`).
- `nx audit backend` -> Module vulnerability and dependency audit.

## 4. Test & Verification Rules
- Pure mathematical functions in `internal/math/` must maintain 100% test coverage with exact floating-point tolerance assertions.
- Atomic cache concurrency must pass the Go race detector (`-race`).
- All timestamps must be generated and exchanged in UTC ISO-8601 (`time.Now().UTC()`).
- Single-turn context ingestion: run `python3 scripts/ep.py pack --surface` before editing.

## 5. Approved Tier 2 Deviations
| Rule | Justification | ADR Reference |
|---|---|---|
| *(None)* | Fully compliant with Tier 1 and Tier 2 EP-OS standards | - |

## 6. Project Invariants
- Intrinsic coin calculation strictly preserves legal coin weights (Emami 8.133g, Half 4.066g, Quarter 2.033g, Gerami 1.0g at 900/1000 purity).
- Jewelry tax calculation strictly levies VAT (9%) on Labor + Profit ONLY, exempting raw gold bullion from tax.
- In-memory cache updates must never block HTTP read handlers.
- Server must trap `SIGTERM`/`SIGINT` and drain active connections within 5 seconds.
