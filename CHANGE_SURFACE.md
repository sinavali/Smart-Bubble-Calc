---
title: "Change Surface: Adoption of Enterprise-Product Engineering OS (EP-OS)"
author: "Antigravity Engineering Agent"
created_date: "2026-10-19"
target_branch: "main"
risk_level: "LOW"
affected_projects:
  - "backend"
  - "mobile"
  - "contracts"
---

# Change Surface: Enterprise-Product Engineering OS Adoption

## 1. Intent & Business Rationale
Transition the Smart-Bubble-Calc repository from an uncoordinated multi-folder layout into a fully governed polyglot monorepo adhering to the `enterprise-product` engineering operating system (EP-OS). This establishes deterministic DAG orchestration (Nx standard), hierarchical governance via `AGENT.md` manifests, strict architectural profiles (Profile A for Go backend, Profile C for Flutter mobile, Profile D for shared OpenAPI contracts), zero-stub production rigor, automated mechanical verification gates (`ep verify`), and 10-dimension audit compliance (`ep audit`).

## 2. Affected Monorepo Projects & Profiles
| Project Path | Architectural Profile | Responsibility in this Change |
|---|---|---|
| `.` (Monorepo Root) | Root Governance | Root `AGENT.md`, `package.json`, `nx.json`, universal manifests, and native hooks |
| `backend` | Profile A (DDD / Hexagonal) | Go service manifest, Nx target contracts, UTC container standard, bugfixes |
| `mobile` | Profile C (Mobile Client) | Flutter client manifest, Nx target contracts, Clean Architecture scaffold |
| `contracts` | Profile D (Shared Contracts) | OpenAPI 3.1 specification, schema validation, and contract manifest |

## 3. Code Surface (Targeted Symbols & Files)

### Scopes and Component Trees
- `scripts/`: Standalone EP-OS mechanical tooling and audit suite.
- `contracts/`: OpenAPI 3.1 contract definitions and target contracts.
- `mobile/`: Flutter client application and Clean Architecture lib.
- `ci/`: Enterprise CI/CD workflow template.
- `.ep/`: Baseline snapshot and session management.
- `docs/`: ADRs, NC tracking, releases, and change specifications.
- `backend/`: Go backend service, domain math, and target contracts.

### Added Files
- `CHANGE_SURFACE.md`: Active Change Surface declaring full blast radius and invariants.
- `AGENT.md`: Root Enterprise Governance Manifest enforcing Prime Directives P1–P10.
- `package.json`: Monorepo root package with Nx task pipeline and verification scripts.
- `nx.json`: Root Nx task graph orchestrator with target defaults and caching rules.
- `CLAUDE.md`: Auto-generated universal manifest projection for Claude Code.
- `.cursorrules`: Auto-generated universal manifest projection for Cursor IDE.
- `.windsurfrules`: Auto-generated universal manifest projection for Windsurf.
- `scripts/ep.py`: Unified mechanical CLI for EP-OS governance.
- `scripts/ep_adopt.py`: Brownfield monorepo adoption and baseline ratcheting wizard.
- `scripts/ep_ast.py`: AST invariant scanning and ast-grep integration.
- `scripts/ep_context.py`: Single-turn context ingestion engine.
- `scripts/ep_hooks.py`: Native git hooks manager.
- `scripts/ep_ops.py`: Operational engineering gates (container, SLO, DORA, IaC).
- `scripts/ep_runner.py`: Standalone DAG task runner and dependency graph builder.
- `scripts/ep_scaffold.py`: Project scaffolding and manifest projection engine.
- `scripts/ep_security.py`: Secret and credential scanner.
- `scripts/ep_session.py`: Multi-session state machine and memory management.
- `scripts/ep_stack.py`: Polyglot stack detector and toolchain resolver.
- `scripts/ep_sync.py`: Bidirectional skill synchronization engine.
- `scripts/ep_vcs.py`: VCS topology and 4-tier branch synchronization.
- `scripts/audit-runner.py`: 10-Dimension Enterprise Audit automated scanner.
- `scripts/check-nc-items.py`: 14-day NC expiration linter.
- `scripts/validate-change-surface.py`: Change Surface structural validator.
- `scripts/verify-agent-manifests.py`: AGENT.md schema and tier override validator.
- `scripts/verify-nx-targets.py`: Nx project.json target contract validator.
- `docs/adr/0001-adoption-of-enterprise-product-os.md`: Architecture Decision Record for EP-OS adoption.
- `docs/nc/.gitkeep`: Need Clarification protocol directory.
- `docs/releases/.gitkeep`: Milestone and release governance directory.
- `docs/changes/.gitkeep`: Change surface archive directory.
- `ci/ci.yml.example`: Enterprise CI pipeline template with mechanical gates and Nx matrix.
- `backend/AGENT.md`: Subproject Agent Manifest for Go backend (Profile A).
- `backend/project.json`: Nx target contracts (`lint`, `test`, `build`, `audit`) for Go backend.
- `backend/internal/math/shamsi.go`: Solar Hijri (Shamsi) mathematical conversion and Tehran timezone formatting.
- `backend/internal/math/shamsi_test.go`: Unit tests for Gregorian <-> Shamsi conversions.
- `mobile/AGENT.md`: Subproject Agent Manifest for Flutter mobile app (Profile C).
- `mobile/project.json`: Nx target contracts (`lint`, `test`, `build`, `audit`) for Flutter mobile app.
- `mobile/pubspec.yaml`: Flutter project metadata and dependencies.
- `mobile/analysis_options.yaml`: Flutter static analysis and linting rules.
- `mobile/lib/main.dart`: Flutter entry point with Swiss minimalist theme, Tehran clock, and navigation tabs.
- `mobile/lib/core/shamsi_date.dart`: Standalone Shamsi calendar math with zero half-spaces.
- `mobile/lib/core/persian_number.dart`: Persian digit conversion, comma formatting, and words generator.
- `mobile/lib/core/theme.dart`: Swiss minimalist terminal theme with dark palette and gold accents.
- `mobile/lib/core/api_client.dart`: Resilient API client with offline cache and on-device legal tax engine.
- `mobile/lib/widgets/shamsi_date_picker.dart`: Interactive Shamsi date picker modal.
- `mobile/lib/widgets/status_pill.dart`: Terminal state and risk level pill badge.
- `mobile/lib/widgets/sparkline.dart`: Lightweight flat sparkline graph.
- `mobile/lib/features/market/market_screen.dart`: Live 10 core Iranian financial assets ticker.
- `mobile/lib/features/jewelry/jewelry_screen.dart`: Legal Iranian jewelry calculator (9% VAT on labor+profit).
- `mobile/lib/features/advisor/advisor_screen.dart`: DCA bubble evaluator and portfolio allocation advisor.
- `mobile/lib/features/settings/settings_screen.dart`: Settings, Tehran date converter, and legal reference.
- `mobile/test/shamsi_date_test.dart`: Unit tests for Shamsi calendar conversion and leap years.
- `mobile/test/persian_number_test.dart`: Unit tests for Persian numerals and words conversion.
- `mobile/test/jewelry_math_test.dart`: Unit tests for legal jewelry tax formula.
- `mobile/test/widget_test.dart`: Smoke tests for mobile terminal app.
- `contracts/AGENT.md`: Subproject Agent Manifest for Shared Contracts (Profile D).
- `contracts/project.json`: Nx target contracts (`lint`, `test`, `build`, `audit`) for OpenAPI contracts.
- `contracts/schemas/openapi/smart-bubble-calc.yaml`: Canonical OpenAPI 3.1 contract specification.
- `backend/cmd/server/app_shell.go`: Instant zero-download Swiss minimalist mobile simulator web shell.
- `backend/cmd/server/app_shell_css.go`: Modular stylesheet for mobile simulator web shell.
- `backend/cmd/server/app_shell_script.go`: Modular client logic for mobile simulator web shell.
- `backend/internal/laws/laws.go`: Official Iranian gold bazaar statutes and daily cached laws engine.
- `backend/internal/laws/laws_test.go`: Unit tests for Iranian gold bazaar laws manager.
- `scripts/dev_all.py`: Local development and Android emulator testing orchestrator for Fedora Linux.
- `scripts/dev-all.sh`: Shell executable wrapper for `dev:all`.
- `.ep/baseline.json`: Initial ratchet baseline technical debt snapshot.

### Modified Files
- `.gitignore`: Add `.ep/sessions/`, `.freebuff/`, and ephemeral test outputs.
- `package.json`: Add dev:all npm script for Fedora testing.
- `backend/project.json`: Add dev target for backend container runner.
- `mobile/project.json`: Add dev target for mobile testing runner.
- `README.md`: Update documentation and clean zero half-spaces.
- `AGENT.md`: Clean zero half-spaces and align governance instructions.
- `CLAUDE.md`: Universal manifest projection without half-spaces.
- `.cursorrules`: IDE rules without half-spaces.
- `.windsurfrules`: Windsurf rules without half-spaces.
- `backend/README.md`: Clean zero half-spaces.
- `backend/config.json`: Clean zero half-spaces.
- `backend/internal/cache/cache.go`: Add risk levels, risk labels, ISO timestamp, and Shamsi date fields.
- `backend/internal/math/bubble.go`: Export Round utility function.
- `backend/internal/provider/tgju.go`: Remove unused `"encoding/json"` and `"fmt"` imports.
- `backend/internal/math/bubble_test.go`: Fix float rounding assertion in `TestJewelryCalculation`.
- `backend/cmd/server/main.go`: Add `/api/v1/shamsi/today` and `/api/v1/historical` endpoints.
- `backend/Dockerfile`: Configure `ENV TZ=UTC` adhering to Tier 1 UTC convention.
- `mobile/README.md`: Clean zero half-spaces.
- `contracts/schemas/openapi/smart-bubble-calc.yaml`: Add ShamsiDateResponse and historical endpoints.

## 4. Test Surface

### Unit & Domain Tests
- `backend/internal/math/bubble_test.go`: Assert exact coin intrinsic and jewelry tax calculations.
- `backend/internal/cache/cache_test.go`: Race-detector concurrency tests for atomic pointer cache.
- `backend/internal/config/config_test.go`: Dynamic configuration loading and thread-safety tests.
- `backend/internal/provider/provider_test.go`: Domestic feed and Nobitex fallback circuit-breaker tests.

### Integration Tests (Real Ephemeral Containers)
- `backend/tests/container_test`: Ephemeral container execution via Podman (`golang:1.23-alpine`).

### Mechanical Governance Gates
- `scripts/verify-nx-targets.py`: 100% pass across all subproject `project.json` contracts.
- `scripts/verify-agent-manifests.py`: 100% pass across root and subproject `AGENT.md` manifests.
- `scripts/check-nc-items.py`: 0 open NC items exceeding 14-day expiration.
- `scripts/validate-change-surface.py`: Mechanical validation of this Change Surface.
- `scripts/audit-runner.py`: 10-Dimension Enterprise Audit across all affected projects.

## 5. Invariants & Non-Negotiables Preserved
- [x] Tier 1: Single Monorepo governed by root DAG task runner (Nx standard).
- [x] Tier 1: Pure domain logic remains 100% isolated from transport and frameworks.
- [x] Tier 1: Real ephemeral containers (Podman/Testcontainers) for execution; no SQLite substitution.
- [x] Tier 1: UTC Storage Convention enforced in all backend containers, timestamps, and contracts.
- [x] Tier 1: Zero-Stub / Anti-MVP Mandate: all deliverables are production-grade.
- [x] Tier 1: Directory nesting depth does not exceed 6 levels from project root.
- [x] Tier 1: Expand/Contract database migration standard enforced (0 destructive migrations).
- [x] Tier 1: 14-Day NC Expiration mechanically enforced.
- [x] Tier 1: Human-Only production gate preserved.
- [x] Tier 2: Domain test coverage maintains $\ge 95\%$ line & branch coverage; adapters $\ge 80\%$.
- [x] Tier 2: File ceiling $\le 800$ lines strictly respected; no micro-file anti-fragmentation sprawl.

## 6. Risk Matrix & Rollback Strategy
| Risk Description | Probability | Impact | Mitigation Strategy |
|---|---|---|---|
| Subproject target command failure in non-Go/non-Dart host | Low | Medium | Container-backed execution and graceful target fallback contracts |
| Divergence between AGENT.md and IDE rules | Low | High | Automated manifest projection via `ep manifest sync` |
| Blast-radius leakage during monorepo adoption | Low | High | Mechanical gate `ep surface check-diff` halts on undeclared files |

### Rollback Strategy
All changes are strictly tracked in Git on branch `main`. If needed, the entire adoption commit can be reverted cleanly via `git revert HEAD` without data loss, as existing Go backend source code logic is fully preserved and backward-compatible.
