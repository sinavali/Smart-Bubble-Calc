package main

import (
	"bytes"
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"bubble_calc/internal/cache"
	"bubble_calc/internal/config"
	"bubble_calc/internal/math"
	"bubble_calc/internal/provider"
)

type Server struct {
	cfgManager *config.ConfigManager
	cache      *cache.AtomicCache
	aggregator *provider.DomesticAggregator
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	configFile := os.Getenv("CONFIG_PATH")
	if configFile == "" {
		configFile = "config.json"
	}

	cfgMgr, err := config.NewConfigManager(configFile)
	if err != nil {
		log.Fatalf("Fatal: failed to load config: %v", err)
	}

	appCache := cache.NewAtomicCache()
	agg := provider.NewDomesticAggregator(nil)

	srv := &Server{
		cfgManager: cfgMgr,
		cache:      appCache,
		aggregator: agg,
	}

	// Initial data sync
	srv.syncMarketData()

	// Start background ticker
	go srv.startBackgroundWorker()

	// Setup HTTP router
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", srv.handleHealthz)
	mux.HandleFunc("/api/v1/market", srv.handleMarket)
	mux.HandleFunc("/api/v1/calculate/jewelry", srv.handleJewelryCalc)
	mux.HandleFunc("/api/v1/admin/config", srv.handleAdminConfig)

	httpServer := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
	}

	// Graceful shutdown channel
	stopChan := make(chan os.Signal, 1)
	signal.Notify(stopChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("🚀 Bubble Calc Backend running on :%s (PID: %d)", port, os.Getpid())
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server Listen error: %v", err)
		}
	}()

	<-stopChan
	log.Println("Shutting down gracefully...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		log.Printf("Server shutdown error: %v", err)
	}
	log.Println("Server stopped cleanly.")
}

func (s *Server) startBackgroundWorker() {
	for {
		cfg := s.cfgManager.GetConfig()
		interval := time.Duration(cfg.PollIntervalSeconds) * time.Second
		if interval < 5*time.Second {
			interval = 5 * time.Second
		}

		time.Sleep(interval)
		s.syncMarketData()
	}
}

func (s *Server) syncMarketData() {
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()

	raw, isStale, err := s.aggregator.FetchData(ctx)
	if err != nil {
		log.Printf("Warning: aggregator error: %v", err)
	}

	cfg := s.cfgManager.GetConfig()
	formulas := cfg.Formulas

	var assets []cache.MarketAsset

	for _, a := range cfg.Assets {
		if !a.Enabled {
			continue
		}

		var price, intrinsic, bubbleAmt, bubblePct float64

		switch a.ID {
		case "gold_18k":
			price = raw.Gold18k
			intrinsic = raw.Gold18k
		case "coin_emami":
			price = raw.CoinEmami
			intrinsic = math.CoinIntrinsic(raw.OunceUSD, raw.FreeUSD, a.WeightGram, a.Purity, formulas.OunceToGram, formulas.MintFeeToman)
			bubbleAmt, bubblePct = math.CoinBubble(price, intrinsic)
		case "coin_half":
			price = raw.CoinHalf
			intrinsic = math.CoinIntrinsic(raw.OunceUSD, raw.FreeUSD, a.WeightGram, a.Purity, formulas.OunceToGram, formulas.MintFeeToman)
			bubbleAmt, bubblePct = math.CoinBubble(price, intrinsic)
		case "coin_quarter":
			price = raw.CoinQuarter
			intrinsic = math.CoinIntrinsic(raw.OunceUSD, raw.FreeUSD, a.WeightGram, a.Purity, formulas.OunceToGram, formulas.MintFeeToman)
			bubbleAmt, bubblePct = math.CoinBubble(price, intrinsic)
		case "coin_gerami":
			price = raw.CoinGerami
			intrinsic = math.CoinIntrinsic(raw.OunceUSD, raw.FreeUSD, a.WeightGram, a.Purity, formulas.OunceToGram, formulas.MintFeeToman)
			bubbleAmt, bubblePct = math.CoinBubble(price, intrinsic)
		case "usd_free":
			price = raw.FreeUSD
			intrinsic = raw.FreeUSD
		case "usdt":
			price = raw.USDT
			intrinsic = raw.FreeUSD
			bubbleAmt = price - intrinsic
			if price > 0 {
				bubblePct = (bubbleAmt / price) * 100.0
			}
		case "aed_free":
			price = raw.DirhamAED
			intrinsic = raw.DirhamAED
		case "xau_ounce":
			price = raw.OunceUSD
			intrinsic = raw.OunceUSD
		case "btc":
			price = raw.BTC
			intrinsic = raw.BTC
		default:
			continue
		}

		assets = append(assets, cache.MarketAsset{
			ID:        a.ID,
			Symbol:    a.Symbol,
			NameFa:    a.NameFa,
			Category:  a.Category,
			Price:     price,
			Intrinsic: intrinsic,
			Bubble:    bubbleAmt,
			BubblePct: bubblePct,
		})
	}

	payload := cache.MarketPayload{
		UpdatedAt:       time.Now().Unix(),
		IsStale:         isStale,
		EmergencyNotice: cfg.EmergencyNotice,
		Assets:          assets,
	}

	if err := s.cache.Update(payload); err != nil {
		log.Printf("Error: failed to update cache snapshot: %v", err)
	}
}

// /healthz endpoint for Runflare post-start command and liveness probes
func (s *Server) handleHealthz(w http.ResponseWriter, r *http.Request) {
	snap := s.cache.Get()
	if snap == nil {
		http.Error(w, `{"status":"initializing"}`, http.StatusServiceUnavailable)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"healthy","uptime_sec":1}`))
}

// /api/v1/market main mobile client endpoint
func (s *Server) handleMarket(w http.ResponseWriter, r *http.Request) {
	snap := s.cache.Get()
	if snap == nil {
		http.Error(w, `{"error":"cache initializing"}`, http.StatusServiceUnavailable)
		return
	}

	// Check ETag
	if match := r.Header.Get("If-None-Match"); match != "" && match == snap.ETag {
		w.WriteHeader(http.StatusNotModified)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("ETag", snap.ETag)
	w.Header().Set("Cache-Control", "public, max-age=15")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	// Gzip support
	if acceptsGzip(r) {
		w.Header().Set("Content-Encoding", "gzip")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(snap.GzipJSON)
	} else {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(snap.RawJSON)
	}
}

type JewelryCalcRequest struct {
	WeightGram        float64 `json:"weight_gram"`
	Gram18kPrice      float64 `json:"gram_18k_price"`
	LaborValue        float64 `json:"labor_value"`
	IsLaborPercentage bool    `json:"is_labor_percentage"`
	ProfitPct         float64 `json:"profit_pct"`
	VATPct            float64 `json:"vat_pct"`
}

// /api/v1/calculate/jewelry
func (s *Server) handleJewelryCalc(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req JewelryCalcRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	cfg := s.cfgManager.GetConfig()
	if req.ProfitPct <= 0 {
		req.ProfitPct = cfg.Formulas.DefaultJewelerProfitPct
	}
	if req.VATPct <= 0 {
		req.VATPct = cfg.Formulas.DefaultVATPct
	}

	breakdown := math.CalculateJewelry(
		req.WeightGram,
		req.Gram18kPrice,
		req.LaborValue,
		req.IsLaborPercentage,
		req.ProfitPct,
		req.VATPct,
	)

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(breakdown)
}

// /api/v1/admin/config (Bearer Auth)
func (s *Server) handleAdminConfig(w http.ResponseWriter, r *http.Request) {
	cfg := s.cfgManager.GetConfig()
	token := r.Header.Get("Authorization")

	expectedToken := "Bearer " + cfg.AdminSecretToken
	if token == "" || token != expectedToken {
		http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
		return
	}

	switch r.Method {
	case http.MethodGet:
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(cfg)
	case http.MethodPost:
		var newCfg config.RuntimeConfig
		if err := json.NewDecoder(r.Body).Decode(&newCfg); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		if err := s.cfgManager.UpdateConfig(newCfg); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		s.syncMarketData() // immediate refresh
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"config updated successfully"}`))
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func acceptsGzip(r *http.Request) bool {
	return bytes.Contains([]byte(r.Header.Get("Accept-Encoding")), []byte("gzip"))
}
