# Bubble Calc Backend (حباب‌سنج و نبض بازار)

High-performance, ultra-low resource (~15MB RAM) Go backend for real-time asset pricing, coin bubble calculations, and legal jewelry purchase breakdowns.

---

## Architecture Overview

- **Zero-Cost Ingestion:** Uses Nobitex public orderbook API and domestic Iranian feeds without API keys.
- **In-Memory Atomic Cache:** Uses `sync/atomic.Pointer` for zero-lock, zero-disk I/O serving.
- **Network Optimization:** Returns HTTP `304 Not Modified` via MD5 `ETag` and delivers pre-compressed `gzip` streams.
- **Dynamic Configuration:** Zero-redeploy adjustments via authenticated Admin API (`/api/v1/admin/config`).

---

## API Endpoints

### 1. Market Overview (`GET /api/v1/market`)
- Returns the 10 core assets, prices in Tomans, intrinsic values, and bubble percentages.
- Supports `If-None-Match` for HTTP 304 caching.
- Supports `Accept-Encoding: gzip`.

### 2. Jewelry Calculator (`POST /api/v1/calculate/jewelry`)
Calculates the exact breakdown according to Iranian tax laws (9% VAT applies strictly to Labor + Profit):

```json
{
  "weight_gram": 5.0,
  "gram_18k_price": 4500000.0,
  "labor_value": 15.0,
  "is_labor_percentage": true,
  "profit_pct": 7.0,
  "vat_pct": 9.0
}
```

### 3. Dynamic Admin Config (`GET` / `POST /api/v1/admin/config`)
- Requires `Authorization: Bearer <ADMIN_SECRET_TOKEN>`.
- Enables remote toggling of assets, changing polling intervals, or adjusting mintage fees without rebuilding.

### 4. Health Check (`GET /healthz`)
- Designed for Runflare post-start checks and container probes. Returns HTTP 200 once memory cache is populated.

---

## Running & Testing

```bash
# Run unit tests
make test

# Run race condition checks
make test-race

# Build static binary
make build
```
