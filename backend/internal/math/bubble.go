package math

import "math"

// CoinIntrinsic calculates the theoretical raw gold value of an Iranian coin in Tomans.
// Formula: ((OunceUSD * FreeUSDIRT / OunceToGram) * WeightGram * Purity) + MintFee
func CoinIntrinsic(ounceUSD, freeUSDIRT, weightGram, purity, ounceToGram, mintFee float64) float64 {
	if ounceToGram <= 0 || weightGram <= 0 || purity <= 0 || ounceUSD <= 0 || freeUSDIRT <= 0 {
		return 0
	}
	rawGramPrice := (ounceUSD * freeUSDIRT) / ounceToGram
	return (rawGramPrice * weightGram * purity) + mintFee
}

// CoinBubble calculates the bubble amount in Tomans and the bubble percentage.
func CoinBubble(marketPrice, intrinsicValue float64) (bubbleAmount float64, bubblePct float64) {
	if marketPrice <= 0 || intrinsicValue <= 0 {
		return 0, 0
	}
	bubbleAmount = marketPrice - intrinsicValue
	bubblePct = (bubbleAmount / marketPrice) * 100.0
	// Round to 2 decimal places
	bubblePct = math.Round(bubblePct*100) / 100
	return bubbleAmount, bubblePct
}

// JewelryBreakdown represents the exact Iranian legal tax & profit breakdown.
type JewelryBreakdown struct {
	RawGoldPrice float64 `json:"raw_gold_price"`
	LaborAmount  float64 `json:"labor_amount"`
	ProfitAmount float64 `json:"profit_amount"`
	VATAmount    float64 `json:"vat_amount"`
	TotalPrice   float64 `json:"total_price"`
}

// CalculateJewelry calculates the legal price of a jewelry piece according to Iranian tax laws.
// Note: 9% VAT applies strictly to (Labor + Profit), NOT to Raw Gold.
// isLaborPercentage: if true, laborValue is treated as a percentage (e.g. 15.0 for 15%); if false, as fixed Tomans.
func CalculateJewelry(weightGram, gram18kPrice, laborValue float64, isLaborPercentage bool, profitPct, vatPct float64) JewelryBreakdown {
	if weightGram <= 0 || gram18kPrice <= 0 {
		return JewelryBreakdown{}
	}

	rawGold := weightGram * gram18kPrice

	var labor float64
	if isLaborPercentage {
		labor = rawGold * (laborValue / 100.0)
	} else {
		labor = laborValue * weightGram
	}

	// Jeweler Profit (typically 7%) on (Raw Gold + Labor)
	profit := (rawGold + labor) * (profitPct / 100.0)

	// VAT (typically 9%) on (Labor + Profit) ONLY
	vat := (labor + profit) * (vatPct / 100.0)

	total := rawGold + labor + profit + vat

	return JewelryBreakdown{
		RawGoldPrice: math.Round(rawGold),
		LaborAmount:  math.Round(labor),
		ProfitAmount: math.Round(profit),
		VATAmount:    math.Round(vat),
		TotalPrice:   math.Round(total),
	}
}

// Round rounds a float64 to the nearest integer.
func Round(val float64) float64 {
	return math.Round(val)
}
