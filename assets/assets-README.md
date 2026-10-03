# Riung monster assets — Flutter handoff

## Contents
- 14 monster illustrations: `<monster>_<liar|jinak>.svg` (7 characters x 2 states), fully self-contained, final hex colors inlined, source space 200x210.
- 4 cosmetics: `topi_rajut.svg`, `syal_hangat.svg`, `bantal_mini.svg`, `bingkai_emas.svg` — drawn at scale 1.0 relative to the anchor system, each with a tight viewBox centered on its own origin (0,0 = the anchor point; bingkai_emas is the exception, see below).
- `anchors.json` — attachment points + compositing rules.

## Coordinate system
All anchors in `anchors.json` are normalized 0-1 against the monster's 200x210 viewBox:
`px = anchor.x * renderedWidth`, `py = anchor.y * renderedHeight`.
To place a cosmetic: translate its origin (0,0) to (px,py), then `rotate(rotationDeg)` (nonzero only for Si Mengelak's diagonal pose: head -12deg, neck -8deg), then `scale(anchor.scale)`. Anchors are identical for liar and jinak.

## Compositing order (zIndex)
1. `bantal_mini` (under the body — the monster sits on it)
2. monster body
3. `topi_rajut` / `syal_hangat` / `bingkai_emas` (over)
One cosmetic per slot; slots: head (topi), neck (syal), base (bantal). `bingkai_emas` is Cermin-only and uses absolute 200x210 coordinates (it traces the mirror outline) — overlay it 1:1 on the monster canvas instead of anchoring.

## Boss scale rule
Wherever monsters appear together (Vault, mini-game, result screens), render Si Hakim 1.3-1.5x larger than the six minions — canonical value 1.4x (`bossScale` in anchors.json). Never scale the others down to compensate.

## Small sizes
Below ~72dp, hide fine detail (truntum dots, sparkles) for a clean silhouette. The exported SVGs include full detail; produce the low-detail variant by dropping elements with opacity 0.45 dot groups, or rasterize from >=96dp and let downscaling soften them.
