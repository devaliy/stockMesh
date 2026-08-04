# StockMesh design tokens

Extracted from the Google Stitch exports in
`stitch_stockmesh_inventory_hub_ui_ux_designs/` (all `code.html` files plus
`stockmesh_terminal/DESIGN.md`). Per design.md §8.1, the **Sell screen**
(`sell_product/code.html`) is the authority where exports disagree.

Implemented in `lib/theme/app_theme.dart` as `ThemeData` + the
`StockMeshTokens` `ThemeExtension`. UI code must never hardcode colors.

## Palette (Material 3 roles, light)

| Token | Hex |
|---|---|
| primary | `#006B2C` |
| on-primary | `#FFFFFF` |
| primary-container | `#00873A` |
| on-primary-container | `#F7FFF2` |
| inverse-primary | `#62DF7D` |
| secondary | `#0051D5` |
| on-secondary | `#FFFFFF` |
| secondary-container | `#316BF3` |
| on-secondary-container | `#FEFCFF` |
| tertiary (analytics purple) | `#712AE2` |
| tertiary-container | `#8A4CFC` |
| error | `#BA1A1A` |
| on-error | `#FFFFFF` |
| error-container | `#FFDAD6` |
| on-error-container | `#93000A` |
| background / surface | `#F8F9FF` |
| on-background / on-surface | `#0B1C30` |
| surface-dim | `#CBDBF5` |
| surface-container-lowest | `#FFFFFF` |
| surface-container-low | `#EFF4FF` |
| surface-container | `#E5EEFF` |
| surface-container-high | `#DCE9FF` |
| surface-container-highest / surface-variant | `#D3E4FE` |
| on-surface-variant | `#3E4A3D` |
| outline | `#6E7B6C` |
| outline-variant | `#BDCABA` |
| inverse-surface | `#213145` |
| inverse-on-surface | `#EAF1FF` |
| surface-tint | `#006E2D` |

### Semantic extras (StockMeshTokens)

| Token | Hex | Use |
|---|---|---|
| warning | `#B45309` | low stock, SYNCING pill (amber, from §8.2 direction) |
| warning-container | `#FEF3C7` | low-stock badge background |
| on-warning-container | `#78350F` | low-stock badge text |
| success | `#006B2C` | LIVE pill, synced dot (= primary) |
| offline | `#64748B` | OFFLINE pill (slate gray) |
| offline-container | `#E2E8F0` | OFFLINE pill background |

## Typography — Inter everywhere; numbers use tabular figures

| Style | Size/Line | Weight | Tracking |
|---|---|---|---|
| display-lg | 48/56 | 700 | -0.02em |
| headline-lg | 32/40 | 600 | -0.01em |
| headline-md (mobile) | 24/32 | 600 | 0 |
| title-md | 18/24 | 600 | 0 |
| body-md | 16/24 | 400 | 0 |
| label-sm | 12/16 | 500 | +0.05em, uppercase for metadata |

## Radii

`sm` 4 · `md` 8 (inputs, buttons) · `lg` 12 · `xl` 16 (cards) · `2xl` 24 (sheets, big CTAs) · `full` pill.

## Spacing

8px base unit. Screen margin 16. Gutter 16. Card padding 20. Min touch target 48. Primary CTA height 56–64.

## Elevation

- Level 1 cards: `0 1px 3px rgba(0,0,0,0.05)` + 1px outline-variant border at ~30% alpha.
- Level 2 floating: `0 8px 20px rgba(0,0,0,0.08)`.
- Flat-but-layered; no heavy blurs.

## Discrepancies noted

- `stockmesh_terminal/DESIGN.md` prose mentions a `#F8FAFC` canvas; the Sell
  screen config uses `#F8F9FF` → **`#F8F9FF` wins** (Sell screen is authority).
- DESIGN.md says radius `lg` = 16px while the Sell config's `xl` = 12px
  (0.75rem); resolved to the scale above (cards 16, inputs/buttons 8).
- Dashboard mock shows `$` currency; product spec (§8.2) requires `₦` — spec wins.
- Icons: Material Symbols in Stitch → Material Icons (rounded style) in Flutter.
