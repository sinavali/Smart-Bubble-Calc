package provider

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNobitexProviderMock(t *testing.T) {
	// Mock Nobitex orderbook response
	mockServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		// Best bid: 700,000,000 Rials (70,000,000 Tomans), Best ask: 700,200,000 Rials
		_, _ = w.Write([]byte(`{
			"status": "ok",
			"bids": [["700000000", "0.5"]],
			"asks": [["700200000", "1.2"]]
		}`))
	}))
	defer mockServer.Close()

	np := &NobitexProvider{
		client:  mockServer.Client(),
		baseURL: mockServer.URL,
	}

	price, err := np.FetchOrderbookPrice(context.Background(), "USDTIRT")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expectedMidToman := 70010000.0 // (700000000 + 700200000)/2 / 10
	if price != expectedMidToman {
		t.Errorf("expected price %f, got %f", expectedMidToman, price)
	}
}

func TestCleanNumber(t *testing.T) {
	cases := []struct {
		input    string
		expected float64
	}{
		{"4,500,000", 4500000},
		{"۵,۲۰۰,۰۰۰", 0}, // non-ascii returns 0 safely
		{"  12,345.67 ", 12345.67},
		{"", 0},
	}

	for _, tc := range cases {
		out := CleanNumber(tc.input)
		if out != tc.expected {
			t.Errorf("input %s: expected %f, got %f", tc.input, tc.expected, out)
		}
	}
}

func TestDomesticAggregatorFallback(t *testing.T) {
	// Create an aggregator with failing client
	failingClient := &http.Client{
		Transport: &failingRoundTripper{},
	}

	agg := NewDomesticAggregator(failingClient)
	data, isStale, err := agg.FetchData(context.Background())

	if err != nil {
		t.Fatalf("aggregator should not return fatal error on fetch failure: %v", err)
	}
	if !isStale {
		t.Error("expected isStale=true when external fetches fail")
	}
	if data.OunceUSD <= 0 || data.FreeUSD <= 0 {
		t.Error("expected fallback baseline data to be populated")
	}
}

type failingRoundTripper struct{}

func (f *failingRoundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	return nil, http.ErrHandlerTimeout
}
