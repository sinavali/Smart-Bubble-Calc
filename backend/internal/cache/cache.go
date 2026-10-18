package cache

import (
	"bytes"
	"compress/gzip"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"sync/atomic"
)

type MarketAsset struct {
	ID          string  `json:"id"`
	Symbol      string  `json:"symbol"`
	NameFa      string  `json:"name_fa"`
	Category    string  `json:"category"`
	Price       float64 `json:"price"`        // Current market price in Tomans
	Intrinsic   float64 `json:"intrinsic"`    // Theoretical gold value in Tomans
	Bubble      float64 `json:"bubble"`       // Price - Intrinsic
	BubblePct   float64 `json:"bubble_pct"`   // (Bubble / Price) * 100
	RiskLevel   string  `json:"risk_level"`   // "low_risk", "moderate", "high_risk"
	RiskLabelFa string  `json:"risk_label_fa"`// "کم ریسک", "حباب متعادل", "پر ریسک و داغ"
}

type MarketPayload struct {
	UpdatedAt       int64         `json:"updated_at"`
	UpdatedAtISO    string        `json:"updated_at_iso"`
	ShamsiDate      string        `json:"shamsi_date"`
	IsStale         bool          `json:"is_stale"`
	EmergencyNotice *string       `json:"emergency_notice,omitempty"`
	Assets          []MarketAsset `json:"assets"`
}

type CacheSnapshot struct {
	RawJSON  []byte
	GzipJSON []byte
	ETag     string
	Payload  MarketPayload
}

type AtomicCache struct {
	snapshot atomic.Pointer[CacheSnapshot]
}

func NewAtomicCache() *AtomicCache {
	return &AtomicCache{}
}

func (ac *AtomicCache) Get() *CacheSnapshot {
	return ac.snapshot.Load()
}

func (ac *AtomicCache) Update(payload MarketPayload) error {
	raw, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	// Pre-compress with Gzip for maximum serving speed
	var buf bytes.Buffer
	gz := gzip.NewWriter(&buf)
	if _, err := gz.Write(raw); err != nil {
		return err
	}
	if err := gz.Close(); err != nil {
		return err
	}
	gzBytes := buf.Bytes()

	// Compute ETag from raw MD5
	hash := md5.Sum(raw)
	etag := `"` + hex.EncodeToString(hash[:]) + `"`

	snap := &CacheSnapshot{
		RawJSON:  raw,
		GzipJSON: gzBytes,
		ETag:     etag,
		Payload:  payload,
	}

	ac.snapshot.Store(snap)
	return nil
}
