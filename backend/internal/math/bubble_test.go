package math

import (
	"math"
	"testing"
)

func TestCoinIntrinsicAndBubble(t *testing.T) {
	ounceUSD := 2650.0
	freeUSDIRT := 70000.0
	ounceToGram := 31.1035
	mintFee := 7000.0

	// Full Emami Coin (8.133g, 0.900 purity)
	intrinsic := CoinIntrinsic(ounceUSD, freeUSDIRT, 8.133, 0.900, ounceToGram, mintFee)
	if intrinsic <= 0 {
		t.Fatalf("expected positive intrinsic value, got %f", intrinsic)
	}

	// Expected intrinsic approx ~43.6M Toman
	marketPrice := 52000000.0
	bubbleAmt, bubblePct := CoinBubble(marketPrice, intrinsic)

	if bubbleAmt <= 0 {
		t.Errorf("expected positive bubble amount, got %f", bubbleAmt)
	}
	if bubblePct <= 0 || bubblePct >= 100 {
		t.Errorf("expected reasonable bubble percentage between 0 and 100, got %f", bubblePct)
	}

	// Verify exact formula integrity: BubbleAmt == MarketPrice - Intrinsic
	diff := math.Abs(bubbleAmt - (marketPrice - intrinsic))
	if diff > 0.001 {
		t.Errorf("bubble amount mismatch: diff=%f", diff)
	}
}

func TestCoinIntrinsicEdgeCases(t *testing.T) {
	// Zero or negative values should not crash or produce NaN
	tests := []struct {
		ounce, usd, weight, purity, ounceToGram, mintFee float64
	}{
		{0, 70000, 8.133, 0.900, 31.1035, 7000},
		{2650, 0, 8.133, 0.900, 31.1035, 7000},
		{2650, 70000, 0, 0.900, 31.1035, 7000},
		{2650, 70000, 8.133, 0, 31.1035, 7000},
		{2650, 70000, 8.133, 0.900, 0, 7000},
		{-100, 70000, 8.133, 0.900, 31.1035, 7000},
	}

	for i, tc := range tests {
		val := CoinIntrinsic(tc.ounce, tc.usd, tc.weight, tc.purity, tc.ounceToGram, tc.mintFee)
		if val != 0 {
			t.Errorf("test case %d: expected 0 for invalid inputs, got %f", i, val)
		}
	}
}

func TestJewelryCalculation(t *testing.T) {
	weightGram := 5.0
	gram18k := 4500000.0
	laborPct := 15.0
	profitPct := 7.0
	vatPct := 9.0

	res := CalculateJewelry(weightGram, gram18k, laborPct, true, profitPct, vatPct)

	expectedRaw := 5.0 * 4500000.0 // 22,500,000
	if res.RawGoldPrice != expectedRaw {
		t.Errorf("expected raw gold %f, got %f", expectedRaw, res.RawGoldPrice)
	}

	expectedLabor := expectedRaw * 0.15 // 3,375,000
	if res.LaborAmount != expectedLabor {
		t.Errorf("expected labor %f, got %f", expectedLabor, res.LaborAmount)
	}

	expectedProfit := (expectedRaw + expectedLabor) * 0.07 // (25,875,000) * 0.07 = 1,811,250
	if res.ProfitAmount != expectedProfit {
		t.Errorf("expected profit %f, got %f", expectedProfit, res.ProfitAmount)
	}

	// Legal VAT must be on Labor + Profit ONLY
	expectedVAT := (expectedLabor + expectedProfit) * 0.09 // (3,375,000 + 1,811,250) * 0.09 = 466,763
	if math.Abs(res.VATAmount-expectedVAT) > 1 {
		t.Errorf("expected VAT %f, got %f", expectedVAT, res.VATAmount)
	}

	expectedTotal := expectedRaw + expectedLabor + expectedProfit + res.VATAmount
	if math.Abs(res.TotalPrice-expectedTotal) > 1 {
		t.Errorf("expected total %f, got %f", expectedTotal, res.TotalPrice)
	}
}
