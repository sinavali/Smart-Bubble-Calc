---
id: "ADR-0001"
title: "Adoption of Enterprise-Product Engineering OS (EP-OS)"
status: "Accepted"
date: "2026-10-19"
deciders:
  - "Engineering Team"
  - "Antigravity Engineering Agent"
affected_projects:
  - "backend"
  - "mobile"
  - "contracts"
tier_override: false
---

# ADR-0001: Adoption of Enterprise-Product Engineering OS (EP-OS)

## 1. Context and Problem Statement
The Smart-Bubble-Calc codebase initially consisted of isolated `backend` (Go) and `mobile` (Flutter) directories without unified task orchestration, mechanical boundaries, standardized API contracts, or automated architectural gating. As the product scales to handle high-frequency Iranian asset pricing and cross-platform mobile users, we need production-grade engineering rigor, deterministic DAG task execution, and zero-compromise architectural standards.

## 2. Decision Drivers
- **Deterministic Polyglot Orchestration**: Need a unified task graph across Go, Flutter, and OpenAPI schemas without toolchain fragmentation.
- **Hierarchical Governance**: Cascade organization-level engineering inviolables into subprojects via `AGENT.md`.
- **Value-Driven Testing & Real Containers**: Guarantee reliable test execution using real containerized runtimes (Podman) rather than in-memory mocking.
- **Strict Blast-Radius Bounding**: Ensure all modifications are declared and validated via `CHANGE_SURFACE.md`.
- **Sovereign Infrastructure & Zero Vendor Lock-In**: Deployable on self-hosted or standard container infrastructure with UTC data persistence.

## 3. Considered Options
- **Option 1**: Loose Poly-Repo / Scripted Bash Folders (Status Quo).
- **Option 2**: Lerna / Pure Node monorepo (Lacks multi-language Go & Flutter first-class target contracts).
- **Option 3**: **Enterprise-Product Engineering OS (EP-OS) with Nx Reference Standard**.

## 4. Decision Outcome
**Chosen Option**: Option 3 (Enterprise-Product Engineering OS with Nx standard), because it provides:
1. Complete architectural profile classification (Profile A for Go backend, Profile C for Flutter client, Profile D for shared contracts).
2. Standalone DAG runner (`ep run` / `ep run-many`) and native Nx target delegation.
3. 10-Dimension Enterprise Audit automated verification (`ep audit`).
4. Mechanical blast-radius enforcement (`ep surface check-diff`).
5. Universal manifest projection (`ep manifest sync`) keeping Claude, Cursor, and Windsurf configurations in sync.

## 5. Consequences

### Positive Consequences
- Unified root commands: `lint`, `test`, `build`, `audit`, and `verify` across all subprojects.
- Comprehensive mechanical checks prevent undetected regressions or undeclared blast radius.
- Single source of truth for API contracts via OpenAPI 3.1 in `contracts/`.
- Automated CI pipeline with 2-Pass PR self-audit gatekeeping.

### Negative Consequences / Trade-Offs
- Requires developers and AI agents to author and validate a `CHANGE_SURFACE.md` prior to non-trivial changes.
- Requires strict adherence to Tier 1 Inviolables (UTC conventions, pure domain isolation).

## 6. Compliance & Verification Strategy
- **Automated Verification**: Mechanical gatekeeper `python3 scripts/ep.py verify` verifies Nx target contracts, `AGENT.md` manifests, NC items, and migration safety.
- **Audit Verification**: `python3 scripts/ep.py audit --scope .` runs the 10-Dimension Enterprise Audit.
- **Continuous Integration**: `.github/workflows/ci.yml` gates all pull requests on mechanical verification and Nx affected matrix.
