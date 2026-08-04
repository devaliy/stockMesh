# design.md — StockMesh
## Build specification for Claude Code

> **Instructions for Claude Code:** This document is the single source of truth for building StockMesh end to end. Build in the milestone order defined in §10 — do not skip ahead. Each milestone has acceptance criteria; a milestone is not complete until its criteria pass. UI screens are designed in Google Stitch and exported as reference images + markup into `design/stitch/` (see §8 for the workflow); implement Flutter UI to match those references using the theme tokens in §8.2, never hardcoded colors.

---

## 1. What we are building

StockMesh is a **fully offline** inventory app for small shops. One Android phone runs as the **Hub** (embedded server + authoritative database). Other phones run as **Clients** (full local replica + attendant UI). Devices sync in real time over local Wi-Fi or the Hub's hotspot using TCP/WebSocket. No internet, no cloud, no accounts.

**Non-negotiable invariants — every code change must preserve these:**

1. Stock levels are NEVER stored as editable numbers. All stock changes are immutable, signed-delta events in an append-only log. Current stock = sum of deltas (a rebuildable projection).
2. Event ordering and correctness NEVER depend on device clocks. The Hub-assigned `hub_seq` is the only authoritative order.
3. `event_id` (UUIDv7, generated on the originating device) is the global idempotency key. Re-submitting an existing event must be a no-op that returns the existing `hub_seq`.
4. A disconnected client remains fully functional for reads and writes; reconnection replays missed data in both directions with zero data loss and zero duplicates.
5. Clients never edit reference data (products, prices, devices). Only the Hub/Admin does.
6. One codebase, one APK, two roles. Role is chosen in the first-run wizard and stored locally.

**Out of scope for v1 (do not build):** cloud sync, iOS, multi-branch, receipt printing, SQLCipher, event-log compaction.

---

## 2. Tech stack

| Concern | Choice | Version / notes |
|---|---|---|
| Framework | Flutter (Android target) | Flutter 3.x, Dart 3, min SDK Android 8.0 (API 26) |
| Local DB | drift (SQLite) | Reactive queries drive the UI; migrations from day one |
| State | Riverpod | `riverpod` + `riverpod_annotation`, codegen |
| Sockets | `dart:io` | `ServerSocket` + `WebSocketTransformer` on Hub; `WebSocket.connect` on client. Port **47800** |
| Discovery | `bonsoir` | Service type `_stockmesh._tcp`; Android `MulticastLock` + `CHANGE_WIFI_MULTICAST_STATE` |
| Barcode | `mobile_scanner` | Sell/receive/product-create flows |
| QR generate | `qr_flutter` | Pairing QR on Hub |
| IDs | `uuid` package, v7 | Time-ordered |
| Crypto | `crypto` (HMAC-SHA256) | Pairing + message auth |
| Foreground service | `flutter_foreground_task` | Keeps Hub server alive; persistent notification |
| Serialization | JSON via `json_serializable` | Every wire message has a typed model class |
| Tests | `flutter_test`, `integration_test` | Sync engine must be testable without real sockets (in-memory transport) |

---

## 3. Repository layout

```
stockmesh/
├── design/
│   └── stitch/                  # Google Stitch exports (see §8)
│       ├── tokens.md            # Extracted design tokens
│       ├── 01-onboarding/       # Per-screen: screen.png + screen.html (Stitch export)
│       ├── 02-sell/
│       └── ...
├── lib/
│   ├── main.dart
│   ├── app.dart                 # MaterialApp, router, theme
│   ├── theme/
│   │   └── app_theme.dart       # Tokens from design/stitch/tokens.md — single place colors live
│   ├── core/
│   │   ├── ids.dart             # UUIDv7 helper
│   │   ├── money.dart           # int kobo <-> display string; NEVER double for money
│   │   └── result.dart
│   ├── data/
│   │   ├── db/
│   │   │   ├── database.dart    # drift database
│   │   │   ├── tables.dart      # schema per §4
│   │   │   └── daos/            # products_dao, events_dao, devices_dao, projection_dao
│   │   └── repositories/
│   ├── domain/
│   │   ├── models/              # Product, StockEvent, Device, StockLevel
│   │   ├── inventory_service.dart   # event creation + projection rules
│   │   ├── sales_service.dart       # cart -> SALE events with shared receipt_id
│   │   └── reporting_service.dart
│   ├── sync/
│   │   ├── protocol/
│   │   │   ├── messages.dart    # All wire messages, typed, versioned
│   │   │   └── codec.dart       # JSON encode/decode + HMAC envelope
│   │   ├── transport/
│   │   │   ├── transport.dart   # Abstract interface (send/receive streams)
│   │   │   ├── ws_transport.dart
│   │   │   └── memory_transport.dart  # For tests
│   │   ├── hub/
│   │   │   ├── hub_server.dart  # Socket accept loop, session registry
│   │   │   ├── hub_session.dart # Per-client state machine
│   │   │   └── sequencer.dart   # hub_seq assignment (single writer)
│   │   ├── client/
│   │   │   ├── sync_client.dart # Connect/reconnect state machine
│   │   │   └── outbox.dart      # Pending events (hub_seq IS NULL)
│   │   └── discovery/
│   │       ├── advertiser.dart  # Hub-side bonsoir broadcast
│   │       └── browser.dart     # Client-side discovery + last-known-IP fallback
│   ├── security/
│   │   ├── pairing.dart         # QR token issue/consume, secret derivation
│   │   └── message_auth.dart    # HMAC challenge-response + payload MAC
│   └── ui/
│       ├── onboarding/          # Role choice, business setup, join-via-QR
│       ├── shell/               # Bottom nav scaffold, sync status badge
│       ├── sell/
│       ├── receive/
│       ├── products/
│       ├── stock_count/
│       ├── reports/
│       ├── devices/             # Hub: device registry, pairing QR, revoke
│       └── settings/            # Backup/restore, PINs, hub controls
├── test/                        # Unit: projector, sequencer, dedup, money
├── integration_test/            # Two-instance sync scenarios via memory_transport
└── android/                     # Manifest: permissions, foreground service config
```

---

## 4. Database schema (drift)

Money is always `INTEGER` kobo. Timestamps are `INTEGER` Unix ms. Booleans are `INTEGER` 0/1.

```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,                 -- UUIDv7
  name TEXT NOT NULL,
  sku TEXT,
  barcode TEXT,
  unit TEXT NOT NULL DEFAULT 'pcs',    -- pcs|carton|kg|litre
  cost_price INTEGER NOT NULL DEFAULT 0,
  selling_price INTEGER NOT NULL DEFAULT 0,
  low_stock_threshold INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  updated_at INTEGER NOT NULL          -- Hub-authoritative row version for REF sync
);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_name ON products(name);

CREATE TABLE stock_events (
  event_id TEXT PRIMARY KEY,           -- UUIDv7 from originating device
  product_id TEXT NOT NULL REFERENCES products(id),
  event_type TEXT NOT NULL,            -- SALE|RECEIVE|ADJUST|COUNT_ADJUST|RETURN|TRANSFER_OUT|DAMAGE
  quantity_delta INTEGER NOT NULL,     -- signed; SALE negative, RECEIVE positive
  unit_price INTEGER,                  -- kobo at time of sale
  receipt_id TEXT,                     -- groups multi-line sales into one receipt
  device_id TEXT NOT NULL,
  staff_ref TEXT NOT NULL,             -- which staff PIN authored it
  note TEXT,
  created_at INTEGER NOT NULL,         -- display only, NEVER for ordering
  hub_seq INTEGER UNIQUE               -- NULL while pending; assigned by Hub
);
CREATE INDEX idx_events_pending ON stock_events(hub_seq) WHERE hub_seq IS NULL;
CREATE INDEX idx_events_product ON stock_events(product_id);
CREATE INDEX idx_events_receipt ON stock_events(receipt_id);

CREATE TABLE devices (
  device_id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL,                  -- HUB|ATTENDANT|STOCKTAKER
  secret_hash TEXT NOT NULL,           -- HMAC key material (Hub stores hash-verifiable form)
  is_revoked INTEGER NOT NULL DEFAULT 0,
  last_seen_at INTEGER,
  last_acked_seq INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE staff (
  staff_ref TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  pin_hash TEXT NOT NULL,              -- salted SHA-256
  is_admin INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  updated_at INTEGER NOT NULL
);

CREATE TABLE stock_levels (             -- projection cache; rebuildable from events
  product_id TEXT PRIMARY KEY,
  quantity INTEGER NOT NULL DEFAULT 0,
  projected_through_seq INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE app_state (                -- single-row key/value
  key TEXT PRIMARY KEY,                 -- role, business_name, currency, own_device_id,
  value TEXT NOT NULL                   -- own_secret, hub_last_known_ip, last_acked_seq (client)
);
```

**Projector rules (`inventory_service.dart`):**
- Applying an event: `UPDATE stock_levels SET quantity = quantity + :delta` (upsert). Idempotent at the call site: never apply the same `event_id` twice — check existence in `stock_events` first, insert event and update projection in one transaction.
- Pending local events (hub_seq NULL) ARE included in the projection (optimistic UI). Because deltas are commutative, later hub_seq assignment changes nothing about totals.
- `rebuildProjection()` must exist: truncate `stock_levels`, re-sum all events. Used after restore and in tests to assert projection == sum(events).
- Physical counts: UI captures counted quantity; Hub computes variance vs projection and emits a `COUNT_ADJUST` event with the delta. The raw count is stored in `note`.

---

## 5. Wire protocol

All messages are JSON with an authenticated envelope:

```json
{
  "v": 1,
  "type": "EVENT_SUBMIT",
  "device_id": "…",
  "nonce": "…",
  "payload": { },
  "mac": "hex(HMAC-SHA256(device_secret, v|type|device_id|nonce|payload_json))"
}
```

Implement every message as a typed class in `sync/protocol/messages.dart`:

| Type | Direction | Payload |
|---|---|---|
| `HELLO` | C→H | `{device_id, last_acked_seq, ref_snapshot_at, challenge_response}` |
| `HELLO_ACK` | H→C | `{hub_time_ms, latest_seq, session_id}` |
| `HELLO_REJECT` | H→C | `{reason: BAD_AUTH\|REVOKED\|VERSION}` |
| `CATCH_UP` | H→C | `{events: [...], ref_products: [...], ref_staff: [...], through_seq}` — chunk at 500 events/message |
| `EVENT_SUBMIT` | C→H | `{events: [...]}` — batch of pending events |
| `EVENT_ACCEPT` | H→C | `{assignments: [{event_id, hub_seq}]}` |
| `EVENT_REJECT` | H→C | `{rejections: [{event_id, reason}]}` |
| `EVENT_BROADCAST` | H→C(all others) | `{events: [...]}` — with hub_seq set |
| `REF_UPDATE` | H→C(all) | `{products: [...], staff: [...]}` |
| `PING`/`PONG` | both | `{}` — every 15 s; dead after 2 misses |

**Hub session state machine (`hub_session.dart`):** `AWAIT_HELLO → AUTHED → STREAMING`. On HELLO: verify HMAC challenge against device registry, reject if revoked; send HELLO_ACK; stream CATCH_UP from `last_acked_seq`; then STREAMING (accept submits, forward broadcasts).

**Sequencer (`sequencer.dart`):** single async queue — one event accepted at a time: validate (product exists & active; event_type known; delta sign matches type) → dedup check by event_id (if exists, return existing hub_seq) → assign next hub_seq → persist → fan out EVENT_BROADCAST to all other STREAMING sessions. This serialization is what makes hub_seq gapless and total.

**Client state machine (`sync_client.dart`):** `DISCONNECTED → DISCOVERING → CONNECTING → SYNCING (catch-up + outbox flush) → LIVE`. Reconnect with exponential backoff 1s→2s→4s… cap 30s. On any socket error, drop to DISCONNECTED and loop. Discovery order: last-known IP direct attempt (2 s timeout) → mDNS browse → manual IP entry UI as last resort.

**Client apply rule:** events arriving via EVENT_BROADCAST or CATCH_UP are inserted with their hub_seq and applied to the projection unless event_id already exists locally (in which case only update its hub_seq from NULL — this is how a client's own submitted events are confirmed). Advance `last_acked_seq` to the highest contiguous hub_seq held.

---

## 6. Pairing & security

1. Hub → *Add device*: generate `pairing_token` (32 random bytes, 5-min expiry, single use). Show QR encoding `{ip, port, token}`.
2. Client scans QR → connects → sends `PAIR_REQUEST {token, device_id, device_name, role_requested}` (this one message is unauthenticated; token is the auth).
3. Hub validates token → generates `device_secret` (32 bytes) → stores registry row → returns `PAIR_ACCEPT {device_secret, business_name, currency}` → burns token. All future HELLOs use HMAC challenge-response with this secret; the secret never crosses the wire again.
4. Staff PINs: 4 digits, salted SHA-256, verified locally; every event carries `staff_ref`. Admin-gated actions: product/price edits, adjustments, device revoke, backup, restore.
5. Revocation: Hub sets `is_revoked=1`; next HELLO gets `HELLO_REJECT{REVOKED}`; client wipes its replica and returns to onboarding.

---

## 7. Backup & restore

- Backup = single file: JSON dump of all tables, zipped, AES-encrypted with a key derived (PBKDF2) from Admin PIN. Saved via share sheet / SAF. Prompt weekly via notification.
- Restore (onboarding option "Restore a business"): decrypt, load, `rebuildProjection()`, restart Hub role. Old client pairings are invalid — clients must re-pair.

---

## 8. UI — Google Stitch workflow

The visual design is produced in **Google Stitch** (stitch.withgoogle.com), exported, and committed to `design/stitch/`. Claude Code implements Flutter screens **to match the Stitch references**, using the extracted token file — never colors/spacing invented ad hoc.

### 8.1 Process

1. Each screen in §8.3 is generated in Stitch (mobile mode) using the listed prompt, iterated until approved, then exported: screenshot as `screen.png` + Stitch's HTML/CSS export as `screen.html`, placed in `design/stitch/NN-screen-name/`.
2. **Claude Code task — tokens first:** read all `screen.html` exports, extract the palette, type scale, radii, and spacing into `design/stitch/tokens.md`, then implement `lib/theme/app_theme.dart` (ThemeData + a `StockMeshTokens` ThemeExtension). If exports disagree, the Sell screen wins; note discrepancies in tokens.md.
3. **Per screen:** treat `screen.png` as the layout/visual spec and `screen.html` as the source of exact values (hex, px, weights). Translate to Flutter widgets — do NOT embed webviews and do NOT literally transpile the HTML. Map px→dp 1:1. Use theme tokens exclusively.
4. If a Stitch export is missing for a screen, build a functional version with the app theme and mark it `// TODO(stitch): restyle when export lands` — never block a milestone on design assets.

### 8.2 Design direction (baked into every Stitch prompt)

- Mobile, Android, portrait. High-contrast, big touch targets (min 48dp) — used in bright shops by non-technical staff.
- Clean utilitarian style; deep green primary, warm off-white background, amber for warnings/low stock, red only for destructive actions.
- Currency shown as ₦ with thousands separators. Numbers use tabular figures.
- Persistent elements on every post-onboarding screen: bottom nav (Sell · Stock · Products · Reports · More) and a sync status pill in the app bar (LIVE green / SYNCING amber / OFFLINE gray with pending count, e.g. "OFFLINE · 12 unsynced").

### 8.3 Screens

| # | Screen | Stitch prompt (paste into Stitch, prepend §8.2 direction) | Key behaviors to implement |
|---|---|---|---|
| 01 | Role choice | "Onboarding screen for an inventory app: app logo, two large tappable cards — 'Set up main business phone' and 'Join an existing business' — with one-line descriptions" | Writes `role` to app_state |
| 02 | Business setup (Hub) | "3-step wizard: business name + currency; create admin PIN (4-digit pad); done screen with 'Start adding products'" | Creates staff admin row, own device row, starts foreground service |
| 03 | Join business (Client) | "Screen instructing user to join the shop Wi-Fi, then a full-screen QR scanner with torch toggle; success state showing business name and 'Downloading data…' progress" | Pairing flow §6, then CATCH_UP with progress |
| 04 | Sell | "Point-of-sale screen: search bar with barcode scan icon, product result list with name, price, stock left; a cart bar pinned above bottom nav showing item count and total; tapping a product adds qty stepper" | Cart → one receipt_id, one SALE event per line; instant local apply; works offline |
| 05 | Cart / checkout | "Slide-up cart sheet: line items with qty steppers, total in large type, staff PIN pad confirm button" | PIN verifies staff_ref; success snackbar |
| 06 | Products list | "Inventory list: search, each row shows product name, stock quantity badge (amber if low), selling price; FAB to add product (admin only)" | Reactive drift stream; low-stock = qty ≤ threshold |
| 07 | Product form (Hub) | "Add/edit product form: name, unit dropdown, cost price, selling price, low stock threshold, barcode field with scan button" | Hub only; bumps updated_at; triggers REF_UPDATE |
| 08 | Receive stock | "Receive stock screen: product picker with scan, quantity keypad, optional cost per unit, big green 'Receive' button" | RECEIVE event |
| 09 | Stock count | "Stock take mode: checklist of products, tap to enter counted quantity on a keypad, progress indicator, submit button; then a variance review list showing expected vs counted with differences highlighted" | Stock-taker submits counts; Hub/Admin approves → COUNT_ADJUST events |
| 10 | Reports (Hub) | "Reports dashboard: today's sales total card, top products list, low stock list, per-staff sales; date range picker; export CSV button" | reporting_service queries; CSV via share sheet |
| 11 | Devices (Hub) | "Connected devices screen: list with device name, role, online dot, last seen; 'Add device' button opening a full-screen pairing QR with 5-minute countdown" | Registry CRUD, revoke with confirm dialog |
| 12 | Settings / More | "Settings list: business profile, staff & PINs, backup now, restore, hub status (running, connected count), manual hub IP entry, about" | Backup §7; manual IP feeds discovery fallback |

### 8.4 UI rules

- Every screen reads from Riverpod providers backed by drift streams — UI updates automatically when a broadcast event lands. No manual refresh anywhere.
- All writes are optimistic: apply locally, show immediately, sync in background. The only sync UI is the status pill and per-item "pending" subtlety (dimmed check icon).
- Empty states, loading states, and error states for every list. Offline is a normal state, not an error state.

---

## 9. Android specifics

- Manifest permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, `CAMERA`, `POST_NOTIFICATIONS`, foreground service type `dataSync`.
- Hub server runs inside `flutter_foreground_task` with persistent notification "StockMesh Hub — N devices connected". On service start/restart, rebind the ServerSocket and restart the bonsoir advertiser.
- Acquire `MulticastLock` while discovery/advertising is active; release after.
- On Hub role, prompt for battery-optimization exemption (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` flow) during onboarding step 2, with a plain-language explanation.
- Handle OEM task killers gracefully: client shows "Hub unreachable" banner with a "Troubleshoot" link explaining per-OEM settings (static text page).

---

## 10. Build order & acceptance criteria

Work strictly in this order. Write tests alongside each milestone, not after.

### M1 — Foundation & data layer
Scaffold project, theme from Stitch tokens (§8.1 step 2), drift schema §4, DAOs, ids/money helpers, projector with `rebuildProjection()`.
**Accept:** unit tests prove (a) applying N random events then rebuilding projection yields identical stock_levels; (b) double-applying an event_id is a no-op; (c) money round-trips kobo↔display with no floats anywhere (`grep -r "double" lib/core/money.dart` finds nothing).

### M2 — Single-device app
Onboarding role choice + Hub wizard (screens 01–02), products CRUD (06–07), sell flow (04–05), receive (08), reports basics (10). No networking yet.
**Accept:** full manual flow on one device/emulator: create business → add 3 products → sell 2 → receive 5 → report shows correct totals and stock; kill and reopen app, state intact.

### M3 — Protocol & sync engine (transport-agnostic)
Messages + codec + HMAC envelope, sequencer, hub_session, sync_client, outbox — all against `memory_transport`.
**Accept:** integration tests with 1 hub + 2 simulated clients: (a) event submitted by C1 appears at C2 with hub_seq; (b) C2 offline during 50 events → reconnect → converges exactly; (c) C1 submits, ACK dropped, C1 resubmits → no duplicate, same hub_seq returned; (d) interleaved concurrent submits from both clients → gapless hub_seq, identical projections on all three nodes; (e) revoked device HELLO rejected.

### M4 — Real networking
ws_transport over dart:io, Hub foreground service + ServerSocket accept loop, bonsoir advertiser/browser + MulticastLock, last-known-IP fallback, manual IP entry, PING/PONG liveness, reconnect backoff.
**Accept:** two physical devices (or emulators with port forwarding) on one Wi-Fi: pair via QR, sale on client appears on Hub < 3 s; toggle client airplane mode, make 5 sales, reconnect → converges; kill Hub app → clients show OFFLINE and keep selling → restart Hub → converges.

### M5 — Pairing, staff, devices, security
Screens 03 + 11, pairing token flow §6, staff PIN management, revocation, message MAC verification on every frame (drop invalid silently, log locally).
**Accept:** expired/reused pairing token rejected; revoked client is bounced and wiped; tampered payload (flip one byte) is dropped.

### M6 — Stock count, backup, polish
Screens 09 + 12, variance→COUNT_ADJUST flow, encrypted backup/restore, weekly backup reminder, empty/error states, sync status pill everywhere, low-stock badges.
**Accept:** backup on device A, restore on device B, `rebuildProjection()` matches; count of 57 vs expected 60 produces COUNT_ADJUST −3 visible on all devices.

### M7 — Hardening
8-client load test script (headless Dart clients), 2,000-event catch-up < 10 s, battery sanity check on Hub, `flutter analyze` clean, README with setup + pairing guide.
**Accept:** all prior tests green; load test converges; no analyzer warnings.

---

## 11. Testing rules

- The sync engine must never require real sockets in unit/integration tests — everything through `transport.dart` abstraction.
- Property-style test: random interleavings of events/disconnects across 3 simulated nodes must always converge (run 100 seeds in CI).
- Golden rule assertion available everywhere: `sum(stock_events.quantity_delta) per product == stock_levels.quantity`.

## 12. Conventions

- Small commits per component; conventional commit messages (`feat(sync): …`).
- No TODOs left in merged code except `TODO(stitch)` restyle markers.
- Every public class in `sync/` and `domain/` gets a doc comment explaining its role in the invariants (§1).
- If any instruction here conflicts with something discovered during build (e.g. a plugin limitation), stop and surface the conflict with a proposed alternative — do not silently deviate from the invariants.
