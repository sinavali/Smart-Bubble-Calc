package provider

import (
	"context"
	"time"
)

type MarketRawData struct {
	OunceUSD   float64 // Global Gold Ounce in USD
	FreeUSD    float64 // Free US Dollar in Tomans
	Gold18k    float64 // Gram of 18k in Tomans
	USDT       float64 // Tether in Tomans
	BTC        float64 // Bitcoin in Tomans
	CoinEmami  float64 // Emami Coin in Tomans
	CoinHalf   float64 // Half Coin in Tomans
	CoinQuarter float64 // Quarter Coin in Tomans
	CoinGerami float64 // Gerami Coin in Tomans
	DirhamAED  float64 // UAE Dirham in Tomans
	FetchedAt  time.Time
}

type PriceProvider interface {
	Name() string
	FetchData(ctx context.Context) (*MarketRawData, error)
}
