package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"sort"

	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// seedKinds maps seed-file sections to content kinds (GET /v1/content/{kind}).
var seedKinds = []string{"saboteurs", "affirmations", "research_facts", "meditations", "sleep_stories", "betterme_lessons"}

// runSeedContent replaces public content from a seed JSON shaped like
// docs/dummy-data-seed.json. Sections not listed in seedKinds (sample users,
// transactions, …) are ignored. src "-" reads stdin, so it works inside the
// distroless container:  docker exec -i riung-api /riung seed-content - < seed.json
func runSeedContent(ctx context.Context, cfg config.Config, src string, logger *slog.Logger) error {
	if cfg.DatabaseURL == "" {
		return errors.New("DATABASE_URL is required")
	}
	var r io.Reader = os.Stdin
	if src != "-" {
		f, err := os.Open(src) //nolint:gosec // G304: operator-supplied seed path
		if err != nil {
			return err
		}
		defer func() { _ = f.Close() }()
		r = f
	}
	raw, err := io.ReadAll(io.LimitReader(r, 16<<20))
	if err != nil {
		return err
	}
	var doc map[string]json.RawMessage
	if err := json.Unmarshal(raw, &doc); err != nil {
		return fmt.Errorf("seed: %w", err)
	}
	locale := "id"
	if meta, ok := doc["_meta"]; ok {
		var m struct {
			Locale string `json:"locale"`
		}
		if json.Unmarshal(meta, &m) == nil && (m.Locale == "id" || m.Locale == "en") {
			locale = m.Locale
		}
	}

	st, closeStore, err := openStore(ctx, cfg)
	if err != nil {
		return err
	}
	defer closeStore()

	sorted := append([]string(nil), seedKinds...)
	sort.Strings(sorted)
	for _, kind := range sorted {
		section, ok := doc[kind]
		if !ok {
			continue
		}
		var items []json.RawMessage
		if err := json.Unmarshal(section, &items); err != nil {
			return fmt.Errorf("seed %s: %w", kind, err)
		}
		out := make([]store.ContentItem, 0, len(items))
		seen := map[string]bool{}
		for i, it := range items {
			var head struct {
				ID string `json:"id"`
			}
			if err := json.Unmarshal(it, &head); err != nil || head.ID == "" || len(head.ID) > 64 {
				return fmt.Errorf("seed %s[%d]: every item needs an id (<= 64 chars)", kind, i)
			}
			if seen[head.ID] {
				return fmt.Errorf("seed %s: duplicate id %q", kind, head.ID)
			}
			seen[head.ID] = true
			out = append(out, store.ContentItem{ID: head.ID, Position: i, Data: it})
		}
		if err := st.ReplaceContent(ctx, kind, locale, out); err != nil {
			return fmt.Errorf("seed %s: %w", kind, err)
		}
		logger.Info("content seeded", logx.KeyEvent, logx.EventContentSeeded, "kind", kind, "locale", locale, "items", len(out))
	}
	return nil
}
