package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestConfigManagerLoadAndUpdate(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "test_config.json")

	initialJSON := `{
		"poll_interval_seconds": 30,
		"admin_secret_token": "secret123",
		"ad_strategy": {
			"yektanet_enabled": true,
			"min_seconds_between_ads": 90,
			"rewarded_multiplier": 1.0
		},
		"formulas": {
			"ounce_to_gram": 31.1035,
			"mint_fee_toman": 7000.0,
			"default_jeweler_profit_pct": 7.0,
			"default_vat_pct": 9.0
		},
		"assets": [
			{
				"id": "gold_18k",
				"symbol": "GLD18K",
				"name_fa": "طلای ۱۸ عیار",
				"category": "gold",
				"enabled": true,
				"display_order": 1,
				"weight_gram": 1.0,
				"purity": 0.750
			}
		]
	}`

	if err := os.WriteFile(configPath, []byte(initialJSON), 0644); err != nil {
		t.Fatalf("failed to write test file: %v", err)
	}

	cm, err := NewConfigManager(configPath)
	if err != nil {
		t.Fatalf("failed to create config manager: %v", err)
	}

	cfg := cm.GetConfig()
	if cfg.PollIntervalSeconds != 30 {
		t.Errorf("expected 30 seconds poll interval, got %d", cfg.PollIntervalSeconds)
	}
	if len(cfg.Assets) != 1 || cfg.Assets[0].ID != "gold_18k" {
		t.Errorf("expected 1 asset with id gold_18k")
	}

	// Test update
	cfg.PollIntervalSeconds = 15
	if err := cm.UpdateConfig(cfg); err != nil {
		t.Fatalf("failed to update config: %v", err)
	}

	updated := cm.GetConfig()
	if updated.PollIntervalSeconds != 15 {
		t.Errorf("expected updated poll interval 15, got %d", updated.PollIntervalSeconds)
	}
}
