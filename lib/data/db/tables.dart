import 'package:drift/drift.dart';

/// Schema per design.md §4. Money is INTEGER kobo, timestamps INTEGER Unix
/// ms, booleans INTEGER 0/1 (drift maps those automatically).

/// Reference data — owned by the Hub, mirrored read-only on clients
/// (invariant §1.5). `updatedAt` is the Hub-authoritative row version used
/// by REF sync.
class Products extends Table {
  TextColumn get id => text()(); // UUIDv7
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get sellingPrice => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only event log — the source of truth for all stock movement
/// (invariant §1.1). Rows are never updated except to fill in `hubSeq`
/// (NULL while pending → assigned exactly once by the Hub sequencer).
class StockEvents extends Table {
  TextColumn get eventId => text()(); // UUIDv7 from originating device
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get eventType =>
      text()(); // SALE|RECEIVE|ADJUST|COUNT_ADJUST|RETURN|TRANSFER_OUT|DAMAGE
  IntColumn get quantityDelta => integer()(); // signed
  IntColumn get unitPrice => integer().nullable()(); // kobo at time of sale
  TextColumn get receiptId => text().nullable()();
  TextColumn get deviceId => text()();
  TextColumn get staffRef => text()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()(); // display only, NEVER for ordering
  IntColumn get hubSeq => integer().nullable().unique()();

  @override
  Set<Column> get primaryKey => {eventId};
}

/// Device registry — Hub-owned reference data. `secretHash` holds the HMAC
/// key material; on the Hub it is the shared secret used to verify MACs.
class Devices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text()(); // HUB|ATTENDANT|STOCKTAKER
  TextColumn get secretHash => text()();
  BoolColumn get isRevoked => boolean().withDefault(const Constant(false))();
  IntColumn get lastSeenAt => integer().nullable()();
  IntColumn get lastAckedSeq => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {deviceId};
}

/// Staff PINs — 4 digits, salted SHA-256, verified locally (§6.4).
class Staff extends Table {
  TextColumn get staffRef => text()();
  TextColumn get displayName => text()();
  TextColumn get pinHash => text()(); // "salt:hash" hex
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {staffRef};
}

/// Projection cache — rebuildable from stock_events at any time
/// (invariant §1.1: current stock = sum of deltas).
class StockLevels extends Table {
  TextColumn get productId => text()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get projectedThroughSeq => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {productId};
}

/// Single-row key/value store: role, business_name, currency, own_device_id,
/// own_secret, hub_last_known_ip, last_acked_seq (client), admin_pin_set, …
class AppState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
