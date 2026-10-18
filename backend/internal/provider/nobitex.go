package provider

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"
)

// NobitexProvider fetches public market rates for USDT and BTC directly from Nobitex API
type NobitexProvider struct {
	client  *http.Client
	baseURL string
}

func NewNobitexProvider(client *http.Client) *NobitexProvider {
	if client == nil {
		client = &http.Client{Timeout: 5 * time.Second}
	}
	return &NobitexProvider{
		client:  client,
		baseURL: "https://api.nobitex.ir",
	}
}

func (np *NobitexProvider) Name() string {
	return "Nobitex"
}

type nobitexOrderbookResponse struct {
	Status string     `json:"status"`
	Bids   [][]string `json:"bids"` // [[price, volume]]
	Asks   [][]string `json:"asks"`
}

func (np *NobitexProvider) FetchOrderbookPrice(ctx context.Context, symbol string) (float64, error) {
	url := fmt.Sprintf("%s/v2/orderbook/%s", np.baseURL, symbol)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return 0, err
	}

	resp, err := np.client.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("nobitex returned status %d", resp.StatusCode)
	}

	var ob nobitexOrderbookResponse
	if err := json.NewDecoder(resp.Body).Decode(&ob); err != nil {
		return 0, err
	}

	if len(ob.Bids) == 0 || len(ob.Asks) == 0 {
		return 0, fmt.Errorf("empty orderbook for %s", symbol)
	}

	// Mid-market price between best bid and best ask (in Rials, converted to Tomans)
	bestBidRial, _ := strconv.ParseFloat(ob.Bids[0][0], 64)
	bestAskRial, _ := strconv.ParseFloat(ob.Asks[0][0], 64)
	if bestBidRial <= 0 || bestAskRial <= 0 {
		return 0, fmt.Errorf("invalid orderbook prices")
	}

	midMarketToman := ((bestBidRial + bestAskRial) / 2.0) / 10.0
	return midMarketToman, nil
}
