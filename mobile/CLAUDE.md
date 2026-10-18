<!-- AUTO-GENERATED FROM AGENT.md by ep manifest sync -->

---
project_name: "mobile"
profile: "C"
stack: "flutter-3.24"
scope: "mobile"
owner: "engineering"
tier_overrides: []
slo:
  tier: "tier-2"
  availability_target: "0.995"
dr:
  rto: "1h"
  rpo: "15m"
resources:
  cpu_limit: "1000m"
  memory_limit: "512Mi"
---

# Project Agent Manifest: mobile

## 1. Scope & Business Intent
The `mobile` client is a cross-platform Flutter application tailored for Iranian users (targeting Cafe Bazaar, Myket, and Google Play). It features an "Anti-AI-Slop" Swiss minimalist financial terminal UI using neutral tones and tabular typography. It provides real-time tickers for 10 core Iranian financial assets, an on-device micro-MLP neural network isolate for DCA entry evaluation without server compute cost, a legal 18k gold jewelry tax calculator, and Yektanet In-App SDK monetization.

## 2. Architectural Profile & Boundaries
- **Profile**: C (Mobile Clients: Clean Architecture / BLoC)
- **Primary Inputs**:
  - User touch gestures and parameter inputs.
  - Periodic background polling of backend `/api/v1/market`.
- **Allowed Outbound Dependencies**:
  - `contracts`: Canonical OpenAPI 3.1 DTO schemas.
  - Backend API (`/api/v1/market`, `/api/v1/calculate/jewelry`).
  - Device local secure storage (shared_preferences / flutter_secure_storage).
- **Forbidden Dependencies**:
  - Direct database connections or cloud backend SDKs bypassing the backend API.
  - Server-side runtime packages.

## 3. Local Nx Target Delegations
- `nx lint mobile` -> Flutter / Dart static analysis (`flutter analyze` or Dart linter).
- `nx test mobile` -> Flutter widget and isolate unit test suite (`flutter test`).
- `nx build mobile` -> Flutter release packaging (`flutter build apk`).
- `nx audit mobile` -> Dart package dependency and security audit (`dart pub outdated`).

## 4. Test & Verification Rules
- Clean architecture separation: presentation, domain (use cases, entities), data (repository implementations).
- On-device neural network DCA isolate must operate without blocking UI frame rendering (60/120 fps fluid motion).
- All timestamps converted from UTC to Iranian Solar Hijri / local time (`Asia/Tehran`) strictly in the presentation layer.
- Single-turn context ingestion: run `python3 scripts/ep.py pack --surface` before editing.

## 5. Approved Tier 2 Deviations
| Rule | Justification | ADR Reference |
|---|---|---|
| *(None)* | Fully compliant with Tier 1 and Tier 2 EP-OS standards | - |

## 6. Project Invariants
- Iranian jewelry calculation UI must clearly display separate itemized rows for Raw Gold, Labor, Jeweler Profit, and 9% VAT.
- Offline-first cache: cached market rates must display a clear "Stale / Offline" visual indicator when connectivity is lost.
- Zero frame drops on ticker updates.
