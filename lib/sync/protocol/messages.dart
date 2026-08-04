import 'package:json_annotation/json_annotation.dart';

import '../../data/db/database.dart';

part 'messages.g.dart';

/// Wire message types (design.md §5). String values are the `type` field of
/// the envelope.
abstract final class MsgType {
  static const hello = 'HELLO';
  static const helloAck = 'HELLO_ACK';
  static const helloReject = 'HELLO_REJECT';
  static const catchUp = 'CATCH_UP';
  static const eventSubmit = 'EVENT_SUBMIT';
  static const eventAccept = 'EVENT_ACCEPT';
  static const eventReject = 'EVENT_REJECT';
  static const eventBroadcast = 'EVENT_BROADCAST';
  static const refUpdate = 'REF_UPDATE';
  static const ping = 'PING';
  static const pong = 'PONG';
  // Pairing (§6). PAIR_REQUEST is the single unauthenticated message in the
  // protocol — the single-use token is its authorization.
  static const pairRequest = 'PAIR_REQUEST';
  static const pairAccept = 'PAIR_ACCEPT';
  static const pairReject = 'PAIR_REJECT';
}

/// A stock event as it travels on the wire. Field-for-field mirror of the
/// stock_events row (§4); `hub_seq` is null until the sequencer assigns it.
@JsonSerializable(fieldRename: FieldRename.snake)
class WireEvent {
  const WireEvent({
    required this.eventId,
    required this.productId,
    required this.eventType,
    required this.quantityDelta,
    this.unitPrice,
    this.receiptId,
    required this.deviceId,
    required this.staffRef,
    this.note,
    required this.createdAt,
    this.hubSeq,
  });

  final String eventId;
  final String productId;
  final String eventType;
  final int quantityDelta;
  final int? unitPrice;
  final String? receiptId;
  final String deviceId;
  final String staffRef;
  final String? note;
  final int createdAt;
  final int? hubSeq;

  factory WireEvent.fromJson(Map<String, dynamic> json) =>
      _$WireEventFromJson(json);
  Map<String, dynamic> toJson() => _$WireEventToJson(this);

  factory WireEvent.fromRow(StockEvent row) => WireEvent(
        eventId: row.eventId,
        productId: row.productId,
        eventType: row.eventType,
        quantityDelta: row.quantityDelta,
        unitPrice: row.unitPrice,
        receiptId: row.receiptId,
        deviceId: row.deviceId,
        staffRef: row.staffRef,
        note: row.note,
        createdAt: row.createdAt,
        hubSeq: row.hubSeq,
      );

  StockEvent toRow() => StockEvent(
        eventId: eventId,
        productId: productId,
        eventType: eventType,
        quantityDelta: quantityDelta,
        unitPrice: unitPrice,
        receiptId: receiptId,
        deviceId: deviceId,
        staffRef: staffRef,
        note: note,
        createdAt: createdAt,
        hubSeq: hubSeq,
      );

  WireEvent withSeq(int seq) => WireEvent(
        eventId: eventId,
        productId: productId,
        eventType: eventType,
        quantityDelta: quantityDelta,
        unitPrice: unitPrice,
        receiptId: receiptId,
        deviceId: deviceId,
        staffRef: staffRef,
        note: note,
        createdAt: createdAt,
        hubSeq: seq,
      );
}

/// Product reference row on the wire (REF_UPDATE / CATCH_UP).
@JsonSerializable(fieldRename: FieldRename.snake)
class WireProduct {
  const WireProduct({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.lowStockThreshold,
    required this.isActive,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String unit;
  final int costPrice;
  final int sellingPrice;
  final int lowStockThreshold;
  final bool isActive;
  final int updatedAt;

  factory WireProduct.fromJson(Map<String, dynamic> json) =>
      _$WireProductFromJson(json);
  Map<String, dynamic> toJson() => _$WireProductToJson(this);

  factory WireProduct.fromRow(Product row) => WireProduct(
        id: row.id,
        name: row.name,
        sku: row.sku,
        barcode: row.barcode,
        unit: row.unit,
        costPrice: row.costPrice,
        sellingPrice: row.sellingPrice,
        lowStockThreshold: row.lowStockThreshold,
        isActive: row.isActive,
        updatedAt: row.updatedAt,
      );

  Product toRow() => Product(
        id: id,
        name: name,
        sku: sku,
        barcode: barcode,
        unit: unit,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        lowStockThreshold: lowStockThreshold,
        isActive: isActive,
        updatedAt: updatedAt,
      );
}

/// Staff reference row on the wire. The salted PIN hash syncs so attendants
/// can verify PINs locally while offline (§6.4).
@JsonSerializable(fieldRename: FieldRename.snake)
class WireStaff {
  const WireStaff({
    required this.staffRef,
    required this.displayName,
    required this.pinHash,
    required this.isAdmin,
    required this.isActive,
    required this.updatedAt,
  });

  final String staffRef;
  final String displayName;
  final String pinHash;
  final bool isAdmin;
  final bool isActive;
  final int updatedAt;

  factory WireStaff.fromJson(Map<String, dynamic> json) =>
      _$WireStaffFromJson(json);
  Map<String, dynamic> toJson() => _$WireStaffToJson(this);

  factory WireStaff.fromRow(StaffData row) => WireStaff(
        staffRef: row.staffRef,
        displayName: row.displayName,
        pinHash: row.pinHash,
        isAdmin: row.isAdmin,
        isActive: row.isActive,
        updatedAt: row.updatedAt,
      );

  StaffData toRow() => StaffData(
        staffRef: staffRef,
        displayName: displayName,
        pinHash: pinHash,
        isAdmin: isAdmin,
        isActive: isActive,
        updatedAt: updatedAt,
      );
}

// ---------------------------------------------------------------------------
// Payloads
// ---------------------------------------------------------------------------

@JsonSerializable(fieldRename: FieldRename.snake)
class HelloPayload {
  const HelloPayload({
    required this.deviceId,
    required this.lastAckedSeq,
    required this.refSnapshotAt,
    required this.challengeResponse,
  });

  final String deviceId;
  final int lastAckedSeq;

  /// Highest products/staff updated_at the client holds — lets the Hub skip
  /// unchanged reference data in CATCH_UP.
  final int refSnapshotAt;
  final String challengeResponse;

  factory HelloPayload.fromJson(Map<String, dynamic> json) =>
      _$HelloPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$HelloPayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class HelloAckPayload {
  const HelloAckPayload({
    required this.hubTimeMs,
    required this.latestSeq,
    required this.sessionId,
  });

  final int hubTimeMs;
  final int latestSeq;
  final String sessionId;

  factory HelloAckPayload.fromJson(Map<String, dynamic> json) =>
      _$HelloAckPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$HelloAckPayloadToJson(this);
}

/// HELLO_REJECT reasons (§5).
abstract final class RejectReason {
  static const badAuth = 'BAD_AUTH';
  static const revoked = 'REVOKED';
  static const version = 'VERSION';
}

@JsonSerializable(fieldRename: FieldRename.snake)
class HelloRejectPayload {
  const HelloRejectPayload({required this.reason});

  final String reason;

  factory HelloRejectPayload.fromJson(Map<String, dynamic> json) =>
      _$HelloRejectPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$HelloRejectPayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CatchUpPayload {
  const CatchUpPayload({
    required this.events,
    required this.refProducts,
    required this.refStaff,
    required this.throughSeq,
    required this.done,
  });

  final List<WireEvent> events;
  final List<WireProduct> refProducts;
  final List<WireStaff> refStaff;
  final int throughSeq;

  /// True on the final chunk — the client may flush its outbox now.
  final bool done;

  factory CatchUpPayload.fromJson(Map<String, dynamic> json) =>
      _$CatchUpPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$CatchUpPayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class EventSubmitPayload {
  const EventSubmitPayload({required this.events});

  final List<WireEvent> events;

  factory EventSubmitPayload.fromJson(Map<String, dynamic> json) =>
      _$EventSubmitPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$EventSubmitPayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SeqAssignment {
  const SeqAssignment({required this.eventId, required this.hubSeq});

  final String eventId;
  final int hubSeq;

  factory SeqAssignment.fromJson(Map<String, dynamic> json) =>
      _$SeqAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$SeqAssignmentToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class EventAcceptPayload {
  const EventAcceptPayload({required this.assignments});

  final List<SeqAssignment> assignments;

  factory EventAcceptPayload.fromJson(Map<String, dynamic> json) =>
      _$EventAcceptPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$EventAcceptPayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EventRejection {
  const EventRejection({required this.eventId, required this.reason});

  final String eventId;
  final String reason;

  factory EventRejection.fromJson(Map<String, dynamic> json) =>
      _$EventRejectionFromJson(json);
  Map<String, dynamic> toJson() => _$EventRejectionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class EventRejectPayload {
  const EventRejectPayload({required this.rejections});

  final List<EventRejection> rejections;

  factory EventRejectPayload.fromJson(Map<String, dynamic> json) =>
      _$EventRejectPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$EventRejectPayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class EventBroadcastPayload {
  const EventBroadcastPayload({required this.events});

  final List<WireEvent> events;

  factory EventBroadcastPayload.fromJson(Map<String, dynamic> json) =>
      _$EventBroadcastPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$EventBroadcastPayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class RefUpdatePayload {
  const RefUpdatePayload({required this.products, required this.staff});

  final List<WireProduct> products;
  final List<WireStaff> staff;

  factory RefUpdatePayload.fromJson(Map<String, dynamic> json) =>
      _$RefUpdatePayloadFromJson(json);
  Map<String, dynamic> toJson() => _$RefUpdatePayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PairRequestPayload {
  const PairRequestPayload({
    required this.token,
    required this.deviceId,
    required this.deviceName,
    required this.roleRequested,
  });

  final String token;
  final String deviceId;
  final String deviceName;
  final String roleRequested;

  factory PairRequestPayload.fromJson(Map<String, dynamic> json) =>
      _$PairRequestPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$PairRequestPayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PairAcceptPayload {
  const PairAcceptPayload({
    required this.deviceSecret,
    required this.businessName,
    required this.currency,
  });

  final String deviceSecret;
  final String businessName;
  final String currency;

  factory PairAcceptPayload.fromJson(Map<String, dynamic> json) =>
      _$PairAcceptPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$PairAcceptPayloadToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PairRejectPayload {
  const PairRejectPayload({required this.reason});

  final String reason;

  factory PairRejectPayload.fromJson(Map<String, dynamic> json) =>
      _$PairRejectPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$PairRejectPayloadToJson(this);
}
