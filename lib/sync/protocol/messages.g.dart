// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WireEvent _$WireEventFromJson(Map<String, dynamic> json) => WireEvent(
  eventId: json['event_id'] as String,
  productId: json['product_id'] as String,
  eventType: json['event_type'] as String,
  quantityDelta: (json['quantity_delta'] as num).toInt(),
  unitPrice: (json['unit_price'] as num?)?.toInt(),
  receiptId: json['receipt_id'] as String?,
  deviceId: json['device_id'] as String,
  staffRef: json['staff_ref'] as String,
  note: json['note'] as String?,
  createdAt: (json['created_at'] as num).toInt(),
  hubSeq: (json['hub_seq'] as num?)?.toInt(),
);

Map<String, dynamic> _$WireEventToJson(WireEvent instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'product_id': instance.productId,
  'event_type': instance.eventType,
  'quantity_delta': instance.quantityDelta,
  'unit_price': instance.unitPrice,
  'receipt_id': instance.receiptId,
  'device_id': instance.deviceId,
  'staff_ref': instance.staffRef,
  'note': instance.note,
  'created_at': instance.createdAt,
  'hub_seq': instance.hubSeq,
};

WireProduct _$WireProductFromJson(Map<String, dynamic> json) => WireProduct(
  id: json['id'] as String,
  name: json['name'] as String,
  sku: json['sku'] as String?,
  barcode: json['barcode'] as String?,
  unit: json['unit'] as String,
  costPrice: (json['cost_price'] as num).toInt(),
  sellingPrice: (json['selling_price'] as num).toInt(),
  lowStockThreshold: (json['low_stock_threshold'] as num).toInt(),
  isActive: json['is_active'] as bool,
  updatedAt: (json['updated_at'] as num).toInt(),
);

Map<String, dynamic> _$WireProductToJson(WireProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sku': instance.sku,
      'barcode': instance.barcode,
      'unit': instance.unit,
      'cost_price': instance.costPrice,
      'selling_price': instance.sellingPrice,
      'low_stock_threshold': instance.lowStockThreshold,
      'is_active': instance.isActive,
      'updated_at': instance.updatedAt,
    };

WireStaff _$WireStaffFromJson(Map<String, dynamic> json) => WireStaff(
  staffRef: json['staff_ref'] as String,
  displayName: json['display_name'] as String,
  pinHash: json['pin_hash'] as String,
  isAdmin: json['is_admin'] as bool,
  isActive: json['is_active'] as bool,
  updatedAt: (json['updated_at'] as num).toInt(),
);

Map<String, dynamic> _$WireStaffToJson(WireStaff instance) => <String, dynamic>{
  'staff_ref': instance.staffRef,
  'display_name': instance.displayName,
  'pin_hash': instance.pinHash,
  'is_admin': instance.isAdmin,
  'is_active': instance.isActive,
  'updated_at': instance.updatedAt,
};

HelloPayload _$HelloPayloadFromJson(Map<String, dynamic> json) => HelloPayload(
  deviceId: json['device_id'] as String,
  lastAckedSeq: (json['last_acked_seq'] as num).toInt(),
  refSnapshotAt: (json['ref_snapshot_at'] as num).toInt(),
  challengeResponse: json['challenge_response'] as String,
);

Map<String, dynamic> _$HelloPayloadToJson(HelloPayload instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'last_acked_seq': instance.lastAckedSeq,
      'ref_snapshot_at': instance.refSnapshotAt,
      'challenge_response': instance.challengeResponse,
    };

HelloAckPayload _$HelloAckPayloadFromJson(Map<String, dynamic> json) =>
    HelloAckPayload(
      hubTimeMs: (json['hub_time_ms'] as num).toInt(),
      latestSeq: (json['latest_seq'] as num).toInt(),
      sessionId: json['session_id'] as String,
    );

Map<String, dynamic> _$HelloAckPayloadToJson(HelloAckPayload instance) =>
    <String, dynamic>{
      'hub_time_ms': instance.hubTimeMs,
      'latest_seq': instance.latestSeq,
      'session_id': instance.sessionId,
    };

HelloRejectPayload _$HelloRejectPayloadFromJson(Map<String, dynamic> json) =>
    HelloRejectPayload(reason: json['reason'] as String);

Map<String, dynamic> _$HelloRejectPayloadToJson(HelloRejectPayload instance) =>
    <String, dynamic>{'reason': instance.reason};

CatchUpPayload _$CatchUpPayloadFromJson(Map<String, dynamic> json) =>
    CatchUpPayload(
      events: (json['events'] as List<dynamic>)
          .map((e) => WireEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      refProducts: (json['ref_products'] as List<dynamic>)
          .map((e) => WireProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      refStaff: (json['ref_staff'] as List<dynamic>)
          .map((e) => WireStaff.fromJson(e as Map<String, dynamic>))
          .toList(),
      throughSeq: (json['through_seq'] as num).toInt(),
      done: json['done'] as bool,
    );

Map<String, dynamic> _$CatchUpPayloadToJson(CatchUpPayload instance) =>
    <String, dynamic>{
      'events': instance.events.map((e) => e.toJson()).toList(),
      'ref_products': instance.refProducts.map((e) => e.toJson()).toList(),
      'ref_staff': instance.refStaff.map((e) => e.toJson()).toList(),
      'through_seq': instance.throughSeq,
      'done': instance.done,
    };

EventSubmitPayload _$EventSubmitPayloadFromJson(Map<String, dynamic> json) =>
    EventSubmitPayload(
      events: (json['events'] as List<dynamic>)
          .map((e) => WireEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EventSubmitPayloadToJson(EventSubmitPayload instance) =>
    <String, dynamic>{
      'events': instance.events.map((e) => e.toJson()).toList(),
    };

SeqAssignment _$SeqAssignmentFromJson(Map<String, dynamic> json) =>
    SeqAssignment(
      eventId: json['event_id'] as String,
      hubSeq: (json['hub_seq'] as num).toInt(),
    );

Map<String, dynamic> _$SeqAssignmentToJson(SeqAssignment instance) =>
    <String, dynamic>{'event_id': instance.eventId, 'hub_seq': instance.hubSeq};

EventAcceptPayload _$EventAcceptPayloadFromJson(Map<String, dynamic> json) =>
    EventAcceptPayload(
      assignments: (json['assignments'] as List<dynamic>)
          .map((e) => SeqAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EventAcceptPayloadToJson(EventAcceptPayload instance) =>
    <String, dynamic>{
      'assignments': instance.assignments.map((e) => e.toJson()).toList(),
    };

EventRejection _$EventRejectionFromJson(Map<String, dynamic> json) =>
    EventRejection(
      eventId: json['event_id'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$EventRejectionToJson(EventRejection instance) =>
    <String, dynamic>{'event_id': instance.eventId, 'reason': instance.reason};

EventRejectPayload _$EventRejectPayloadFromJson(Map<String, dynamic> json) =>
    EventRejectPayload(
      rejections: (json['rejections'] as List<dynamic>)
          .map((e) => EventRejection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EventRejectPayloadToJson(EventRejectPayload instance) =>
    <String, dynamic>{
      'rejections': instance.rejections.map((e) => e.toJson()).toList(),
    };

EventBroadcastPayload _$EventBroadcastPayloadFromJson(
  Map<String, dynamic> json,
) => EventBroadcastPayload(
  events: (json['events'] as List<dynamic>)
      .map((e) => WireEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EventBroadcastPayloadToJson(
  EventBroadcastPayload instance,
) => <String, dynamic>{
  'events': instance.events.map((e) => e.toJson()).toList(),
};

RefUpdatePayload _$RefUpdatePayloadFromJson(Map<String, dynamic> json) =>
    RefUpdatePayload(
      products: (json['products'] as List<dynamic>)
          .map((e) => WireProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      staff: (json['staff'] as List<dynamic>)
          .map((e) => WireStaff.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RefUpdatePayloadToJson(RefUpdatePayload instance) =>
    <String, dynamic>{
      'products': instance.products.map((e) => e.toJson()).toList(),
      'staff': instance.staff.map((e) => e.toJson()).toList(),
    };

PairRequestPayload _$PairRequestPayloadFromJson(Map<String, dynamic> json) =>
    PairRequestPayload(
      token: json['token'] as String,
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      roleRequested: json['role_requested'] as String,
    );

Map<String, dynamic> _$PairRequestPayloadToJson(PairRequestPayload instance) =>
    <String, dynamic>{
      'token': instance.token,
      'device_id': instance.deviceId,
      'device_name': instance.deviceName,
      'role_requested': instance.roleRequested,
    };

PairAcceptPayload _$PairAcceptPayloadFromJson(Map<String, dynamic> json) =>
    PairAcceptPayload(
      deviceSecret: json['device_secret'] as String,
      businessName: json['business_name'] as String,
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$PairAcceptPayloadToJson(PairAcceptPayload instance) =>
    <String, dynamic>{
      'device_secret': instance.deviceSecret,
      'business_name': instance.businessName,
      'currency': instance.currency,
    };

PairRejectPayload _$PairRejectPayloadFromJson(Map<String, dynamic> json) =>
    PairRejectPayload(reason: json['reason'] as String);

Map<String, dynamic> _$PairRejectPayloadToJson(PairRejectPayload instance) =>
    <String, dynamic>{'reason': instance.reason};
