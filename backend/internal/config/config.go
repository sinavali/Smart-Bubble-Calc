package config

import (
	"encoding/json"
	"fmt"
	"os"
	"sync"
)

type RuntimeConfig struct {
	PollIntervalSeconds int               `json:"poll_interval_seconds"`
	AdminSecretToken    string            `json:"admin_secret_token"`
	EmergencyNotice     *string           `json:"emergency_notice"`
	AdStrategy          AdStrategyConfig  `json:"ad_strategy"`
	Formulas            FormulaParameters `json:"formulas"`
	Assets              []AssetConfig     `json:"assets"`
}

type AdStrategyConfig struct {
	YektanetEnabled      bool    `json:"yektanet_enabled"`
	MinSecondsBetweenAds int     `json:"min_seconds_between_ads"`
	RewardedMultiplier   float64 `json:"rewarded_multiplier"`
}

type FormulaParameters struct {
	OunceToGram              float64 `json:"ounce_to_gram"`
	MintFeeToman             float64 `json:"mint_fee_toman"`
	DefaultJewelerProfitPct  float64 `json:"default_jeweler_profit_pct"`
	DefaultVATPct            float64 `json:"default_vat_pct"`
}

type AssetConfig struct {
	ID           string  `json:"id"`
	Symbol       string  `json:"symbol"`
	NameFa       string  `json:"name_fa"`
	Category     string  `json:"category"` // "coin", "gold", "fx", "crypto", "benchmark"
	Enabled      bool    `json:"enabled"`
	DisplayOrder int     `json:"display_order"`
	WeightGram   float64 `json:"weight_gram"`
	Purity       float64 `json:"purity"`
}

type ConfigManager struct {
	mu       sync.RWMutex
	filePath string
	config   RuntimeConfig
}

func NewConfigManager(filePath string) (*ConfigManager, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg RuntimeConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config json: %w", err)
	}

	// Environment variable overrides if present (e.g. Runflare injection)
	if token := os.Getenv("ADMIN_SECRET_TOKEN"); token != "" {
		cfg.AdminSecretToken = token
	}

	return &ConfigManager{
		filePath: filePath,
		config:   cfg,
	}, nil
}

func (cm *ConfigManager) GetConfig() RuntimeConfig {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	return cm.config
}

func (cm *ConfigManager) UpdateConfig(newCfg RuntimeConfig) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	data, err := json.MarshalIndent(newCfg, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal new config: %w", err)
	}

	// Write to disk so restarts preserve admin updates
	if err := os.WriteFile(cm.filePath, data, 0644); err != nil {
		return fmt.Errorf("failed to persist config to disk: %w", err)
	}

	cm.config = newCfg
	return nil
}
