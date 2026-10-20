package laws

import (
	"context"
	"testing"
)

func TestLawsManager_Initialization(t *testing.T) {
	lm := NewLawsManager()
	defer lm.Stop()

	snap := lm.GetSnapshot()
	if snap == nil {
		t.Fatal("expected non-nil laws snapshot")
	}

	if len(snap.Payload.Articles) < 5 {
		t.Fatalf("expected at least 5 verified laws, got %d", len(snap.Payload.Articles))
	}

	foundVat := false
	foundGuild := false
	foundAML := false

	for _, a := range snap.Payload.Articles {
		if a.ID == "law-vat-article-26" {
			foundVat = true
		}
		if a.ID == "law-guild-profit-cap" {
			foundGuild = true
		}
		if a.ID == "law-aml-cash-limit" {
			foundAML = true
		}
	}

	if !foundVat || !foundGuild || !foundAML {
		t.Errorf("missing core verified laws: vat=%v, guild=%v, aml=%v", foundVat, foundGuild, foundAML)
	}
}

func TestLawsManager_Refresh(t *testing.T) {
	lm := NewLawsManager()
	defer lm.Stop()

	lm.RefreshLaws(context.Background())
	snap := lm.GetSnapshot()
	if snap == nil || len(snap.Payload.Articles) == 0 {
		t.Fatal("expected non-empty snapshot after refresh")
	}
}
