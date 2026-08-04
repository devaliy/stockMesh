import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// UUIDv7 — time-ordered, generated on the originating device.
///
/// Invariant §1.3: this is the global idempotency key for stock events.
/// v7 is used (not v4) so ids sort roughly by creation time, which keeps
/// SQLite b-trees append-friendly; it is NEVER used for event ordering —
/// only the Hub-assigned `hub_seq` orders events (invariant §1.2).
String newId() => _uuid.v7();
