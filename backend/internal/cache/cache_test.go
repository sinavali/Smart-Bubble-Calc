package cache

import (
	"bytes"
	"compress/gzip"
	"io"
	"sync"
	"testing"
	"time"
)

func TestAtomicCacheUpdateAndGet(t *testing.T) {
	c := NewAtomicCache()

	if c.Get() != nil {
		t.Fatal("expected nil initial snapshot")
	}

	payload := MarketPayload{
		UpdatedAt: time.Now().Unix(),
		IsStale:   false,
		Assets: []MarketAsset{
			{
				ID:        "gold_18k",
				Symbol:    "GLD18K",
				NameFa:    "طلای ۱۸ عیار",
				Price:     4500000,
				Intrinsic: 4500000,
				Bubble:    0,
				BubblePct: 0,
			},
		},
	}

	if err := c.Update(payload); err != nil {
		t.Fatalf("failed to update cache: %v", err)
	}

	snap := c.Get()
	if snap == nil {
		t.Fatal("expected non-nil snapshot after update")
	}
	if snap.ETag == "" {
		t.Error("expected non-empty ETag")
	}
	if len(snap.RawJSON) == 0 {
		t.Error("expected non-empty RawJSON")
	}

	// Verify Gzip decompression matches raw
	gzReader, err := gzip.NewReader(bytes.NewReader(snap.GzipJSON))
	if err != nil {
		t.Fatalf("failed to create gzip reader: %v", err)
	}
	decompressed, err := io.ReadAll(gzReader)
	if err != nil {
		t.Fatalf("failed to decompress gzip data: %v", err)
	}

	if !bytes.Equal(decompressed, snap.RawJSON) {
		t.Error("decompressed data does not match RawJSON")
	}
}

// TestAtomicCacheConcurrency tests for race conditions under high concurrent access
func TestAtomicCacheConcurrency(t *testing.T) {
	c := NewAtomicCache()
	var wg sync.WaitGroup

	// Writer goroutine
	wg.Add(1)
	go func() {
		defer wg.Done()
		for i := 0; i < 100; i++ {
			_ = c.Update(MarketPayload{
				UpdatedAt: time.Now().Unix(),
				Assets: []MarketAsset{
					{ID: "test", Price: float64(i)},
				},
			})
			time.Sleep(time.Millisecond)
		}
	}()

	// 10 Reader goroutines reading simultaneously
	for r := 0; r < 10; r++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := 0; i < 200; i++ {
				_ = c.Get()
				time.Sleep(500 * time.Microsecond)
			}
		}()
	}

	wg.Wait()
}
