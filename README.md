# Smart Bubble Calc (حباب سنج و نبض بازار)

A production-grade, zero-cost monorepo for real-time asset pricing, coin bubble calculations, jewelry shopping protection, and on-device machine learning for Iranian users.

---

## Monorepo Structure

```text
.
├── backend/                  # High-performance Go micro-service (~15MB RAM)
│   ├── cmd/server/           # Application entrypoint & HTTP server
│   ├── internal/
│   │   ├── cache/            # In-memory atomic cache with ETag & Gzip
│   │   ├── config/           # Dynamic runtime config (admin control)
│   │   ├── math/             # Deterministic bubble & jewelry formulas
│   │   └── provider/         # Free Iranian data ingestion adapters (Nobitex, TGJU)
│   ├── config.json           # Dynamic runtime configuration
│   ├── Dockerfile            # Lightweight multi-stage container
│   ├── Makefile              # Local build and test targets
│   └── README.md             # Backend specific documentation
│
├── mobile/                   # Flutter cross-platform mobile client
│   └── README.md             # Mobile client architecture & setup
│
└── .github/workflows/        # Automated CI/CD pipeline
    └── ci.yml                # Unit tests, race detector & build validation
```

---

## Key Architectural Principles

1. **Zero-Cost Operation:** Ingests live financial data exclusively via free, public domestic APIs (**Nobitex** for USDT/BTC and **TGJU** for Gold/Coins/FX) with built-in circuit-breaker fallback.
2. **Ultra-Low Resource Footprint:** The Go backend idles at **~15MB of RAM**, serving pre-compressed Gzip payloads and HTTP `304 Not Modified` via MD5 `ETag` hashes.
3. **High Dynamicity (Zero-Redeploy Control):** Asset configuration, formulas, and emergency notices are managed at runtime via protected admin endpoints.
4. **On-Device Machine Learning:** The mobile client trains a lightweight neural network directly on-device to classify bubble regimes, eliminating expensive server-side GPU costs.
5. **Anti-"AI Slop" Design System:** Minimalist flat Swiss/Nordic aesthetic with dense information hierarchy, mechanical haptics, and tabular Vazirmatn figures.

---

## CI/CD Pipeline

Automated unit tests and race detection (`go test -v -race ./...`) run automatically on GitHub Actions on every push to `main`.

---

## Local Development & Android Testing (Fedora Linux)

To run and test the complete product on your local Fedora machine:

```bash
# Run full product testing suite (Backend + Android Emulator + Flutter)
pnpm dev:all
# or
python3 scripts/dev_all.py
```

### Fedora Prerequisites & Android Emulation
- **Hardware Acceleration**: Automatically uses `/dev/kvm` hardware virtualization.
- **Backend Service**: Bootstrapped inside an ephemeral container on `http://127.0.0.1:8080` with Tehran Shamsi datetime support.
- **Android Port Mapping**: Automatically configures `adb reverse tcp:8080 tcp:8080` so the mobile app inside the emulator communicates with the local Iranian financial backend.
- **Fedora Toolchain Installation**:
  ```bash
  sudo dnf install -y android-tools java-17-openjdk-devel
  ```

