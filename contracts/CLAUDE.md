<!-- AUTO-GENERATED FROM AGENT.md by ep manifest sync -->

---
project_name: "contracts"
profile: "D"
stack: "openapi-3.1"
scope: "shared"
owner: "engineering"
tier_overrides: []
slo:
  tier: "tier-1"
  availability_target: "0.999"
dr:
  rto: "1h"
  rpo: "15m"
resources:
  cpu_limit: "250m"
  memory_limit: "128Mi"
---

# Project Agent Manifest: contracts

## 1. Scope & Business Intent
The `contracts` project serves as the single source of truth for all API wire contracts, data schemas, and DTO definitions across Smart-Bubble-Calc. It defines the formal OpenAPI 3.1 specification for market tickers, asset intrinsic values, legal jewelry calculation formulas, dynamic admin configuration, and health check endpoints.

## 2. Architectural Profile & Boundaries
- **Profile**: D (Shared Contracts & Core Libraries)
- **Primary Inputs**:
  - OpenAPI 3.1 YAML schema definitions (`schemas/openapi/`).
- **Allowed Outbound Dependencies**:
  - Zero external code dependencies (pure schema definitions and linting targets).
- **Forbidden Dependencies**:
  - Implementation code from `backend` or `mobile`.

## 3. Local Nx Target Delegations
- `nx lint contracts` -> OpenAPI YAML syntax and schema validation.
- `nx test contracts` -> Schema structural and breaking change verification.
- `nx build contracts` -> Bundled schema artifact verification.
- `nx audit contracts` -> Contract compliance and spec drift verification.

## 4. Test & Verification Rules
- All timestamp properties must specify UTC format (`date-time` with `Z` timezone indicator).
- All numeric currency fields must define explicit data types (`number` with format `double` or `int64`).
- Breaking changes (field removals, type alterations) require an ADR and major version increment.
- Single-turn context ingestion: run `python3 scripts/ep.py pack --surface` before editing.

## 5. Approved Tier 2 Deviations
| Rule | Justification | ADR Reference |
|---|---|---|
| *(None)* | Fully compliant with Tier 1 and Tier 2 EP-OS standards | - |

## 6. Project Invariants
- Intrinsic value formulas and tax calculation request/response schemas must maintain 100% backward compatibility.
- All mutating endpoints (`POST`) require explicit validation constraints.
