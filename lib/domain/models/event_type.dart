/// Stock event taxonomy (design.md §4). The wire/DB value is [wire]; the
/// enum name differs where Dart keywords collide (RETURN → saleReturn).
enum StockEventType {
  sale('SALE', DeltaSign.negative),
  receive('RECEIVE', DeltaSign.positive),
  adjust('ADJUST', DeltaSign.any),
  countAdjust('COUNT_ADJUST', DeltaSign.any),
  saleReturn('RETURN', DeltaSign.positive),
  transferOut('TRANSFER_OUT', DeltaSign.negative),
  damage('DAMAGE', DeltaSign.negative);

  const StockEventType(this.wire, this.sign);

  /// The exact string stored in stock_events.event_type and sent on the wire.
  final String wire;

  /// Sign constraint the Hub sequencer validates before accepting an event.
  final DeltaSign sign;

  static StockEventType? fromWire(String value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }

  /// True when [delta] respects this type's sign rule (never zero).
  bool allowsDelta(int delta) {
    if (delta == 0) return false;
    return switch (sign) {
      DeltaSign.positive => delta > 0,
      DeltaSign.negative => delta < 0,
      DeltaSign.any => true,
    };
  }
}

enum DeltaSign { positive, negative, any }

/// Device roles (design.md §4 devices.role).
enum DeviceRole {
  hub('HUB'),
  attendant('ATTENDANT'),
  stocktaker('STOCKTAKER');

  const DeviceRole(this.wire);
  final String wire;

  static DeviceRole? fromWire(String value) {
    for (final r in values) {
      if (r.wire == value) return r;
    }
    return null;
  }
}
