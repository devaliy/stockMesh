// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<int> costPrice = GeneratedColumn<int>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellingPriceMeta = const VerificationMeta(
    'sellingPrice',
  );
  @override
  late final GeneratedColumn<int> sellingPrice = GeneratedColumn<int>(
    'selling_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lowStockThresholdMeta = const VerificationMeta(
    'lowStockThreshold',
  );
  @override
  late final GeneratedColumn<int> lowStockThreshold = GeneratedColumn<int>(
    'low_stock_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sku,
    barcode,
    unit,
    costPrice,
    sellingPrice,
    lowStockThreshold,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('selling_price')) {
      context.handle(
        _sellingPriceMeta,
        sellingPrice.isAcceptableOrUnknown(
          data['selling_price']!,
          _sellingPriceMeta,
        ),
      );
    }
    if (data.containsKey('low_stock_threshold')) {
      context.handle(
        _lowStockThresholdMeta,
        lowStockThreshold.isAcceptableOrUnknown(
          data['low_stock_threshold']!,
          _lowStockThresholdMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_price'],
      )!,
      sellingPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}selling_price'],
      )!,
      lowStockThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_stock_threshold'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
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
  const Product({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['unit'] = Variable<String>(unit);
    map['cost_price'] = Variable<int>(costPrice);
    map['selling_price'] = Variable<int>(sellingPrice);
    map['low_stock_threshold'] = Variable<int>(lowStockThreshold);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      unit: Value(unit),
      costPrice: Value(costPrice),
      sellingPrice: Value(sellingPrice),
      lowStockThreshold: Value(lowStockThreshold),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      unit: serializer.fromJson<String>(json['unit']),
      costPrice: serializer.fromJson<int>(json['costPrice']),
      sellingPrice: serializer.fromJson<int>(json['sellingPrice']),
      lowStockThreshold: serializer.fromJson<int>(json['lowStockThreshold']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'unit': serializer.toJson<String>(unit),
      'costPrice': serializer.toJson<int>(costPrice),
      'sellingPrice': serializer.toJson<int>(sellingPrice),
      'lowStockThreshold': serializer.toJson<int>(lowStockThreshold),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    Value<String?> sku = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    String? unit,
    int? costPrice,
    int? sellingPrice,
    int? lowStockThreshold,
    bool? isActive,
    int? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    sku: sku.present ? sku.value : this.sku,
    barcode: barcode.present ? barcode.value : this.barcode,
    unit: unit ?? this.unit,
    costPrice: costPrice ?? this.costPrice,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      unit: data.unit.present ? data.unit.value : this.unit,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('unit: $unit, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sku,
    barcode,
    unit,
    costPrice,
    sellingPrice,
    lowStockThreshold,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.unit == this.unit &&
          other.costPrice == this.costPrice &&
          other.sellingPrice == this.sellingPrice &&
          other.lowStockThreshold == this.lowStockThreshold &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<String> unit;
  final Value<int> costPrice;
  final Value<int> sellingPrice;
  final Value<int> lowStockThreshold;
  final Value<bool> isActive;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.unit = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.unit = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.isActive = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<String>? unit,
    Expression<int>? costPrice,
    Expression<int>? sellingPrice,
    Expression<int>? lowStockThreshold,
    Expression<bool>? isActive,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (unit != null) 'unit': unit,
      if (costPrice != null) 'cost_price': costPrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? sku,
    Value<String?>? barcode,
    Value<String>? unit,
    Value<int>? costPrice,
    Value<int>? sellingPrice,
    Value<int>? lowStockThreshold,
    Value<bool>? isActive,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<int>(costPrice.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<int>(sellingPrice.value);
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<int>(lowStockThreshold.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('unit: $unit, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockEventsTable extends StockEvents
    with TableInfo<$StockEventsTable, StockEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityDeltaMeta = const VerificationMeta(
    'quantityDelta',
  );
  @override
  late final GeneratedColumn<int> quantityDelta = GeneratedColumn<int>(
    'quantity_delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staffRefMeta = const VerificationMeta(
    'staffRef',
  );
  @override
  late final GeneratedColumn<String> staffRef = GeneratedColumn<String>(
    'staff_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hubSeqMeta = const VerificationMeta('hubSeq');
  @override
  late final GeneratedColumn<int> hubSeq = GeneratedColumn<int>(
    'hub_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    productId,
    eventType,
    quantityDelta,
    unitPrice,
    receiptId,
    deviceId,
    staffRef,
    note,
    createdAt,
    hubSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('quantity_delta')) {
      context.handle(
        _quantityDeltaMeta,
        quantityDelta.isAcceptableOrUnknown(
          data['quantity_delta']!,
          _quantityDeltaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityDeltaMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('staff_ref')) {
      context.handle(
        _staffRefMeta,
        staffRef.isAcceptableOrUnknown(data['staff_ref']!, _staffRefMeta),
      );
    } else if (isInserting) {
      context.missing(_staffRefMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('hub_seq')) {
      context.handle(
        _hubSeqMeta,
        hubSeq.isAcceptableOrUnknown(data['hub_seq']!, _hubSeqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  StockEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockEvent(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      quantityDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_delta'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price'],
      ),
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      staffRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_ref'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      hubSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hub_seq'],
      ),
    );
  }

  @override
  $StockEventsTable createAlias(String alias) {
    return $StockEventsTable(attachedDatabase, alias);
  }
}

class StockEvent extends DataClass implements Insertable<StockEvent> {
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
  const StockEvent({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['product_id'] = Variable<String>(productId);
    map['event_type'] = Variable<String>(eventType);
    map['quantity_delta'] = Variable<int>(quantityDelta);
    if (!nullToAbsent || unitPrice != null) {
      map['unit_price'] = Variable<int>(unitPrice);
    }
    if (!nullToAbsent || receiptId != null) {
      map['receipt_id'] = Variable<String>(receiptId);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['staff_ref'] = Variable<String>(staffRef);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || hubSeq != null) {
      map['hub_seq'] = Variable<int>(hubSeq);
    }
    return map;
  }

  StockEventsCompanion toCompanion(bool nullToAbsent) {
    return StockEventsCompanion(
      eventId: Value(eventId),
      productId: Value(productId),
      eventType: Value(eventType),
      quantityDelta: Value(quantityDelta),
      unitPrice: unitPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPrice),
      receiptId: receiptId == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptId),
      deviceId: Value(deviceId),
      staffRef: Value(staffRef),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      hubSeq: hubSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(hubSeq),
    );
  }

  factory StockEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      productId: serializer.fromJson<String>(json['productId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      quantityDelta: serializer.fromJson<int>(json['quantityDelta']),
      unitPrice: serializer.fromJson<int?>(json['unitPrice']),
      receiptId: serializer.fromJson<String?>(json['receiptId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      staffRef: serializer.fromJson<String>(json['staffRef']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      hubSeq: serializer.fromJson<int?>(json['hubSeq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'productId': serializer.toJson<String>(productId),
      'eventType': serializer.toJson<String>(eventType),
      'quantityDelta': serializer.toJson<int>(quantityDelta),
      'unitPrice': serializer.toJson<int?>(unitPrice),
      'receiptId': serializer.toJson<String?>(receiptId),
      'deviceId': serializer.toJson<String>(deviceId),
      'staffRef': serializer.toJson<String>(staffRef),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'hubSeq': serializer.toJson<int?>(hubSeq),
    };
  }

  StockEvent copyWith({
    String? eventId,
    String? productId,
    String? eventType,
    int? quantityDelta,
    Value<int?> unitPrice = const Value.absent(),
    Value<String?> receiptId = const Value.absent(),
    String? deviceId,
    String? staffRef,
    Value<String?> note = const Value.absent(),
    int? createdAt,
    Value<int?> hubSeq = const Value.absent(),
  }) => StockEvent(
    eventId: eventId ?? this.eventId,
    productId: productId ?? this.productId,
    eventType: eventType ?? this.eventType,
    quantityDelta: quantityDelta ?? this.quantityDelta,
    unitPrice: unitPrice.present ? unitPrice.value : this.unitPrice,
    receiptId: receiptId.present ? receiptId.value : this.receiptId,
    deviceId: deviceId ?? this.deviceId,
    staffRef: staffRef ?? this.staffRef,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    hubSeq: hubSeq.present ? hubSeq.value : this.hubSeq,
  );
  StockEvent copyWithCompanion(StockEventsCompanion data) {
    return StockEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      productId: data.productId.present ? data.productId.value : this.productId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      quantityDelta: data.quantityDelta.present
          ? data.quantityDelta.value
          : this.quantityDelta,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      staffRef: data.staffRef.present ? data.staffRef.value : this.staffRef,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      hubSeq: data.hubSeq.present ? data.hubSeq.value : this.hubSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockEvent(')
          ..write('eventId: $eventId, ')
          ..write('productId: $productId, ')
          ..write('eventType: $eventType, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('receiptId: $receiptId, ')
          ..write('deviceId: $deviceId, ')
          ..write('staffRef: $staffRef, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('hubSeq: $hubSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    productId,
    eventType,
    quantityDelta,
    unitPrice,
    receiptId,
    deviceId,
    staffRef,
    note,
    createdAt,
    hubSeq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockEvent &&
          other.eventId == this.eventId &&
          other.productId == this.productId &&
          other.eventType == this.eventType &&
          other.quantityDelta == this.quantityDelta &&
          other.unitPrice == this.unitPrice &&
          other.receiptId == this.receiptId &&
          other.deviceId == this.deviceId &&
          other.staffRef == this.staffRef &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.hubSeq == this.hubSeq);
}

class StockEventsCompanion extends UpdateCompanion<StockEvent> {
  final Value<String> eventId;
  final Value<String> productId;
  final Value<String> eventType;
  final Value<int> quantityDelta;
  final Value<int?> unitPrice;
  final Value<String?> receiptId;
  final Value<String> deviceId;
  final Value<String> staffRef;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int?> hubSeq;
  final Value<int> rowid;
  const StockEventsCompanion({
    this.eventId = const Value.absent(),
    this.productId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.quantityDelta = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.staffRef = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.hubSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockEventsCompanion.insert({
    required String eventId,
    required String productId,
    required String eventType,
    required int quantityDelta,
    this.unitPrice = const Value.absent(),
    this.receiptId = const Value.absent(),
    required String deviceId,
    required String staffRef,
    this.note = const Value.absent(),
    required int createdAt,
    this.hubSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       productId = Value(productId),
       eventType = Value(eventType),
       quantityDelta = Value(quantityDelta),
       deviceId = Value(deviceId),
       staffRef = Value(staffRef),
       createdAt = Value(createdAt);
  static Insertable<StockEvent> custom({
    Expression<String>? eventId,
    Expression<String>? productId,
    Expression<String>? eventType,
    Expression<int>? quantityDelta,
    Expression<int>? unitPrice,
    Expression<String>? receiptId,
    Expression<String>? deviceId,
    Expression<String>? staffRef,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? hubSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (productId != null) 'product_id': productId,
      if (eventType != null) 'event_type': eventType,
      if (quantityDelta != null) 'quantity_delta': quantityDelta,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (receiptId != null) 'receipt_id': receiptId,
      if (deviceId != null) 'device_id': deviceId,
      if (staffRef != null) 'staff_ref': staffRef,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (hubSeq != null) 'hub_seq': hubSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockEventsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? productId,
    Value<String>? eventType,
    Value<int>? quantityDelta,
    Value<int?>? unitPrice,
    Value<String?>? receiptId,
    Value<String>? deviceId,
    Value<String>? staffRef,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int?>? hubSeq,
    Value<int>? rowid,
  }) {
    return StockEventsCompanion(
      eventId: eventId ?? this.eventId,
      productId: productId ?? this.productId,
      eventType: eventType ?? this.eventType,
      quantityDelta: quantityDelta ?? this.quantityDelta,
      unitPrice: unitPrice ?? this.unitPrice,
      receiptId: receiptId ?? this.receiptId,
      deviceId: deviceId ?? this.deviceId,
      staffRef: staffRef ?? this.staffRef,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      hubSeq: hubSeq ?? this.hubSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (quantityDelta.present) {
      map['quantity_delta'] = Variable<int>(quantityDelta.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (staffRef.present) {
      map['staff_ref'] = Variable<String>(staffRef.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (hubSeq.present) {
      map['hub_seq'] = Variable<int>(hubSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('productId: $productId, ')
          ..write('eventType: $eventType, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('receiptId: $receiptId, ')
          ..write('deviceId: $deviceId, ')
          ..write('staffRef: $staffRef, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('hubSeq: $hubSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secretHashMeta = const VerificationMeta(
    'secretHash',
  );
  @override
  late final GeneratedColumn<String> secretHash = GeneratedColumn<String>(
    'secret_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRevokedMeta = const VerificationMeta(
    'isRevoked',
  );
  @override
  late final GeneratedColumn<bool> isRevoked = GeneratedColumn<bool>(
    'is_revoked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_revoked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAckedSeqMeta = const VerificationMeta(
    'lastAckedSeq',
  );
  @override
  late final GeneratedColumn<int> lastAckedSeq = GeneratedColumn<int>(
    'last_acked_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    displayName,
    role,
    secretHash,
    isRevoked,
    lastSeenAt,
    lastAckedSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('secret_hash')) {
      context.handle(
        _secretHashMeta,
        secretHash.isAcceptableOrUnknown(data['secret_hash']!, _secretHashMeta),
      );
    } else if (isInserting) {
      context.missing(_secretHashMeta);
    }
    if (data.containsKey('is_revoked')) {
      context.handle(
        _isRevokedMeta,
        isRevoked.isAcceptableOrUnknown(data['is_revoked']!, _isRevokedMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('last_acked_seq')) {
      context.handle(
        _lastAckedSeqMeta,
        lastAckedSeq.isAcceptableOrUnknown(
          data['last_acked_seq']!,
          _lastAckedSeqMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      secretHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_hash'],
      )!,
      isRevoked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_revoked'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      ),
      lastAckedSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_acked_seq'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String deviceId;
  final String displayName;
  final String role;
  final String secretHash;
  final bool isRevoked;
  final int? lastSeenAt;
  final int lastAckedSeq;
  const Device({
    required this.deviceId,
    required this.displayName,
    required this.role,
    required this.secretHash,
    required this.isRevoked,
    this.lastSeenAt,
    required this.lastAckedSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['display_name'] = Variable<String>(displayName);
    map['role'] = Variable<String>(role);
    map['secret_hash'] = Variable<String>(secretHash);
    map['is_revoked'] = Variable<bool>(isRevoked);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<int>(lastSeenAt);
    }
    map['last_acked_seq'] = Variable<int>(lastAckedSeq);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      deviceId: Value(deviceId),
      displayName: Value(displayName),
      role: Value(role),
      secretHash: Value(secretHash),
      isRevoked: Value(isRevoked),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      lastAckedSeq: Value(lastAckedSeq),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      secretHash: serializer.fromJson<String>(json['secretHash']),
      isRevoked: serializer.fromJson<bool>(json['isRevoked']),
      lastSeenAt: serializer.fromJson<int?>(json['lastSeenAt']),
      lastAckedSeq: serializer.fromJson<int>(json['lastAckedSeq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(role),
      'secretHash': serializer.toJson<String>(secretHash),
      'isRevoked': serializer.toJson<bool>(isRevoked),
      'lastSeenAt': serializer.toJson<int?>(lastSeenAt),
      'lastAckedSeq': serializer.toJson<int>(lastAckedSeq),
    };
  }

  Device copyWith({
    String? deviceId,
    String? displayName,
    String? role,
    String? secretHash,
    bool? isRevoked,
    Value<int?> lastSeenAt = const Value.absent(),
    int? lastAckedSeq,
  }) => Device(
    deviceId: deviceId ?? this.deviceId,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    secretHash: secretHash ?? this.secretHash,
    isRevoked: isRevoked ?? this.isRevoked,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    lastAckedSeq: lastAckedSeq ?? this.lastAckedSeq,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      secretHash: data.secretHash.present
          ? data.secretHash.value
          : this.secretHash,
      isRevoked: data.isRevoked.present ? data.isRevoked.value : this.isRevoked,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      lastAckedSeq: data.lastAckedSeq.present
          ? data.lastAckedSeq.value
          : this.lastAckedSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('secretHash: $secretHash, ')
          ..write('isRevoked: $isRevoked, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastAckedSeq: $lastAckedSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    displayName,
    role,
    secretHash,
    isRevoked,
    lastSeenAt,
    lastAckedSeq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.deviceId == this.deviceId &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.secretHash == this.secretHash &&
          other.isRevoked == this.isRevoked &&
          other.lastSeenAt == this.lastSeenAt &&
          other.lastAckedSeq == this.lastAckedSeq);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> deviceId;
  final Value<String> displayName;
  final Value<String> role;
  final Value<String> secretHash;
  final Value<bool> isRevoked;
  final Value<int?> lastSeenAt;
  final Value<int> lastAckedSeq;
  final Value<int> rowid;
  const DevicesCompanion({
    this.deviceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.secretHash = const Value.absent(),
    this.isRevoked = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.lastAckedSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String deviceId,
    required String displayName,
    required String role,
    required String secretHash,
    this.isRevoked = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.lastAckedSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       displayName = Value(displayName),
       role = Value(role),
       secretHash = Value(secretHash);
  static Insertable<Device> custom({
    Expression<String>? deviceId,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<String>? secretHash,
    Expression<bool>? isRevoked,
    Expression<int>? lastSeenAt,
    Expression<int>? lastAckedSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (secretHash != null) 'secret_hash': secretHash,
      if (isRevoked != null) 'is_revoked': isRevoked,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (lastAckedSeq != null) 'last_acked_seq': lastAckedSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? displayName,
    Value<String>? role,
    Value<String>? secretHash,
    Value<bool>? isRevoked,
    Value<int?>? lastSeenAt,
    Value<int>? lastAckedSeq,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      secretHash: secretHash ?? this.secretHash,
      isRevoked: isRevoked ?? this.isRevoked,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastAckedSeq: lastAckedSeq ?? this.lastAckedSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (secretHash.present) {
      map['secret_hash'] = Variable<String>(secretHash.value);
    }
    if (isRevoked.present) {
      map['is_revoked'] = Variable<bool>(isRevoked.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (lastAckedSeq.present) {
      map['last_acked_seq'] = Variable<int>(lastAckedSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('secretHash: $secretHash, ')
          ..write('isRevoked: $isRevoked, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastAckedSeq: $lastAckedSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffTable extends Staff with TableInfo<$StaffTable, StaffData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _staffRefMeta = const VerificationMeta(
    'staffRef',
  );
  @override
  late final GeneratedColumn<String> staffRef = GeneratedColumn<String>(
    'staff_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAdminMeta = const VerificationMeta(
    'isAdmin',
  );
  @override
  late final GeneratedColumn<bool> isAdmin = GeneratedColumn<bool>(
    'is_admin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_admin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    staffRef,
    displayName,
    pinHash,
    isAdmin,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('staff_ref')) {
      context.handle(
        _staffRefMeta,
        staffRef.isAcceptableOrUnknown(data['staff_ref']!, _staffRefMeta),
      );
    } else if (isInserting) {
      context.missing(_staffRefMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    } else if (isInserting) {
      context.missing(_pinHashMeta);
    }
    if (data.containsKey('is_admin')) {
      context.handle(
        _isAdminMeta,
        isAdmin.isAcceptableOrUnknown(data['is_admin']!, _isAdminMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {staffRef};
  @override
  StaffData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffData(
      staffRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_ref'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      )!,
      isAdmin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_admin'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StaffTable createAlias(String alias) {
    return $StaffTable(attachedDatabase, alias);
  }
}

class StaffData extends DataClass implements Insertable<StaffData> {
  final String staffRef;
  final String displayName;
  final String pinHash;
  final bool isAdmin;
  final bool isActive;
  final int updatedAt;
  const StaffData({
    required this.staffRef,
    required this.displayName,
    required this.pinHash,
    required this.isAdmin,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['staff_ref'] = Variable<String>(staffRef);
    map['display_name'] = Variable<String>(displayName);
    map['pin_hash'] = Variable<String>(pinHash);
    map['is_admin'] = Variable<bool>(isAdmin);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  StaffCompanion toCompanion(bool nullToAbsent) {
    return StaffCompanion(
      staffRef: Value(staffRef),
      displayName: Value(displayName),
      pinHash: Value(pinHash),
      isAdmin: Value(isAdmin),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory StaffData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffData(
      staffRef: serializer.fromJson<String>(json['staffRef']),
      displayName: serializer.fromJson<String>(json['displayName']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
      isAdmin: serializer.fromJson<bool>(json['isAdmin']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'staffRef': serializer.toJson<String>(staffRef),
      'displayName': serializer.toJson<String>(displayName),
      'pinHash': serializer.toJson<String>(pinHash),
      'isAdmin': serializer.toJson<bool>(isAdmin),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  StaffData copyWith({
    String? staffRef,
    String? displayName,
    String? pinHash,
    bool? isAdmin,
    bool? isActive,
    int? updatedAt,
  }) => StaffData(
    staffRef: staffRef ?? this.staffRef,
    displayName: displayName ?? this.displayName,
    pinHash: pinHash ?? this.pinHash,
    isAdmin: isAdmin ?? this.isAdmin,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StaffData copyWithCompanion(StaffCompanion data) {
    return StaffData(
      staffRef: data.staffRef.present ? data.staffRef.value : this.staffRef,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      isAdmin: data.isAdmin.present ? data.isAdmin.value : this.isAdmin,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffData(')
          ..write('staffRef: $staffRef, ')
          ..write('displayName: $displayName, ')
          ..write('pinHash: $pinHash, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(staffRef, displayName, pinHash, isAdmin, isActive, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffData &&
          other.staffRef == this.staffRef &&
          other.displayName == this.displayName &&
          other.pinHash == this.pinHash &&
          other.isAdmin == this.isAdmin &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class StaffCompanion extends UpdateCompanion<StaffData> {
  final Value<String> staffRef;
  final Value<String> displayName;
  final Value<String> pinHash;
  final Value<bool> isAdmin;
  final Value<bool> isActive;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const StaffCompanion({
    this.staffRef = const Value.absent(),
    this.displayName = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.isAdmin = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffCompanion.insert({
    required String staffRef,
    required String displayName,
    required String pinHash,
    this.isAdmin = const Value.absent(),
    this.isActive = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : staffRef = Value(staffRef),
       displayName = Value(displayName),
       pinHash = Value(pinHash),
       updatedAt = Value(updatedAt);
  static Insertable<StaffData> custom({
    Expression<String>? staffRef,
    Expression<String>? displayName,
    Expression<String>? pinHash,
    Expression<bool>? isAdmin,
    Expression<bool>? isActive,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (staffRef != null) 'staff_ref': staffRef,
      if (displayName != null) 'display_name': displayName,
      if (pinHash != null) 'pin_hash': pinHash,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffCompanion copyWith({
    Value<String>? staffRef,
    Value<String>? displayName,
    Value<String>? pinHash,
    Value<bool>? isAdmin,
    Value<bool>? isActive,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return StaffCompanion(
      staffRef: staffRef ?? this.staffRef,
      displayName: displayName ?? this.displayName,
      pinHash: pinHash ?? this.pinHash,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (staffRef.present) {
      map['staff_ref'] = Variable<String>(staffRef.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (isAdmin.present) {
      map['is_admin'] = Variable<bool>(isAdmin.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffCompanion(')
          ..write('staffRef: $staffRef, ')
          ..write('displayName: $displayName, ')
          ..write('pinHash: $pinHash, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockLevelsTable extends StockLevels
    with TableInfo<$StockLevelsTable, StockLevel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _projectedThroughSeqMeta =
      const VerificationMeta('projectedThroughSeq');
  @override
  late final GeneratedColumn<int> projectedThroughSeq = GeneratedColumn<int>(
    'projected_through_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    quantity,
    projectedThroughSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_levels';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockLevel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('projected_through_seq')) {
      context.handle(
        _projectedThroughSeqMeta,
        projectedThroughSeq.isAcceptableOrUnknown(
          data['projected_through_seq']!,
          _projectedThroughSeqMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  StockLevel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockLevel(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      projectedThroughSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}projected_through_seq'],
      )!,
    );
  }

  @override
  $StockLevelsTable createAlias(String alias) {
    return $StockLevelsTable(attachedDatabase, alias);
  }
}

class StockLevel extends DataClass implements Insertable<StockLevel> {
  final String productId;
  final int quantity;
  final int projectedThroughSeq;
  const StockLevel({
    required this.productId,
    required this.quantity,
    required this.projectedThroughSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['projected_through_seq'] = Variable<int>(projectedThroughSeq);
    return map;
  }

  StockLevelsCompanion toCompanion(bool nullToAbsent) {
    return StockLevelsCompanion(
      productId: Value(productId),
      quantity: Value(quantity),
      projectedThroughSeq: Value(projectedThroughSeq),
    );
  }

  factory StockLevel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockLevel(
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      projectedThroughSeq: serializer.fromJson<int>(
        json['projectedThroughSeq'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'projectedThroughSeq': serializer.toJson<int>(projectedThroughSeq),
    };
  }

  StockLevel copyWith({
    String? productId,
    int? quantity,
    int? projectedThroughSeq,
  }) => StockLevel(
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    projectedThroughSeq: projectedThroughSeq ?? this.projectedThroughSeq,
  );
  StockLevel copyWithCompanion(StockLevelsCompanion data) {
    return StockLevel(
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      projectedThroughSeq: data.projectedThroughSeq.present
          ? data.projectedThroughSeq.value
          : this.projectedThroughSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockLevel(')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('projectedThroughSeq: $projectedThroughSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, quantity, projectedThroughSeq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockLevel &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.projectedThroughSeq == this.projectedThroughSeq);
}

class StockLevelsCompanion extends UpdateCompanion<StockLevel> {
  final Value<String> productId;
  final Value<int> quantity;
  final Value<int> projectedThroughSeq;
  final Value<int> rowid;
  const StockLevelsCompanion({
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.projectedThroughSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockLevelsCompanion.insert({
    required String productId,
    this.quantity = const Value.absent(),
    this.projectedThroughSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : productId = Value(productId);
  static Insertable<StockLevel> custom({
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<int>? projectedThroughSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (projectedThroughSeq != null)
        'projected_through_seq': projectedThroughSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockLevelsCompanion copyWith({
    Value<String>? productId,
    Value<int>? quantity,
    Value<int>? projectedThroughSeq,
    Value<int>? rowid,
  }) {
    return StockLevelsCompanion(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      projectedThroughSeq: projectedThroughSeq ?? this.projectedThroughSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (projectedThroughSeq.present) {
      map['projected_through_seq'] = Variable<int>(projectedThroughSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockLevelsCompanion(')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('projectedThroughSeq: $projectedThroughSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppStateTable extends AppState
    with TableInfo<$AppStateTable, AppStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppStateData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppStateTable createAlias(String alias) {
    return $AppStateTable(attachedDatabase, alias);
  }
}

class AppStateData extends DataClass implements Insertable<AppStateData> {
  final String key;
  final String value;
  const AppStateData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppStateCompanion toCompanion(bool nullToAbsent) {
    return AppStateCompanion(key: Value(key), value: Value(value));
  }

  factory AppStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppStateData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppStateData copyWith({String? key, String? value}) =>
      AppStateData(key: key ?? this.key, value: value ?? this.value);
  AppStateData copyWithCompanion(AppStateCompanion data) {
    return AppStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppStateData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppStateData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppStateCompanion extends UpdateCompanion<AppStateData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppStateData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $StockEventsTable stockEvents = $StockEventsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $StaffTable staff = $StaffTable(this);
  late final $StockLevelsTable stockLevels = $StockLevelsTable(this);
  late final $AppStateTable appState = $AppStateTable(this);
  late final ProductsDao productsDao = ProductsDao(this as AppDatabase);
  late final EventsDao eventsDao = EventsDao(this as AppDatabase);
  late final DevicesDao devicesDao = DevicesDao(this as AppDatabase);
  late final StaffDao staffDao = StaffDao(this as AppDatabase);
  late final ProjectionDao projectionDao = ProjectionDao(this as AppDatabase);
  late final AppStateDao appStateDao = AppStateDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    stockEvents,
    devices,
    staff,
    stockLevels,
    appState,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String name,
      Value<String?> sku,
      Value<String?> barcode,
      Value<String> unit,
      Value<int> costPrice,
      Value<int> sellingPrice,
      Value<int> lowStockThreshold,
      Value<bool> isActive,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> sku,
      Value<String?> barcode,
      Value<String> unit,
      Value<int> costPrice,
      Value<int> sellingPrice,
      Value<int> lowStockThreshold,
      Value<bool> isActive,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StockEventsTable, List<StockEvent>>
  _stockEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stockEvents,
    aliasName: $_aliasNameGenerator(db.products.id, db.stockEvents.productId),
  );

  $$StockEventsTableProcessedTableManager get stockEventsRefs {
    final manager = $$StockEventsTableTableManager(
      $_db,
      $_db.stockEvents,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stockEventsRefs(
    Expression<bool> Function($$StockEventsTableFilterComposer f) f,
  ) {
    final $$StockEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockEvents,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockEventsTableFilterComposer(
            $db: $db,
            $table: $db.stockEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<int> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> stockEventsRefs<T extends Object>(
    Expression<T> Function($$StockEventsTableAnnotationComposer a) f,
  ) {
    final $$StockEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockEvents,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.stockEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({bool stockEventsRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> costPrice = const Value.absent(),
                Value<int> sellingPrice = const Value.absent(),
                Value<int> lowStockThreshold = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
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
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> costPrice = const Value.absent(),
                Value<int> sellingPrice = const Value.absent(),
                Value<int> lowStockThreshold = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
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
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stockEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (stockEventsRefs) db.stockEvents],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockEventsRefs)
                    await $_getPrefetchedData<
                      Product,
                      $ProductsTable,
                      StockEvent
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableReferences
                          ._stockEventsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProductsTableReferences(
                        db,
                        table,
                        p0,
                      ).stockEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.productId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({bool stockEventsRefs})
    >;
typedef $$StockEventsTableCreateCompanionBuilder =
    StockEventsCompanion Function({
      required String eventId,
      required String productId,
      required String eventType,
      required int quantityDelta,
      Value<int?> unitPrice,
      Value<String?> receiptId,
      required String deviceId,
      required String staffRef,
      Value<String?> note,
      required int createdAt,
      Value<int?> hubSeq,
      Value<int> rowid,
    });
typedef $$StockEventsTableUpdateCompanionBuilder =
    StockEventsCompanion Function({
      Value<String> eventId,
      Value<String> productId,
      Value<String> eventType,
      Value<int> quantityDelta,
      Value<int?> unitPrice,
      Value<String?> receiptId,
      Value<String> deviceId,
      Value<String> staffRef,
      Value<String?> note,
      Value<int> createdAt,
      Value<int?> hubSeq,
      Value<int> rowid,
    });

final class $$StockEventsTableReferences
    extends BaseReferences<_$AppDatabase, $StockEventsTable, StockEvent> {
  $$StockEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.stockEvents.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockEventsTableFilterComposer
    extends Composer<_$AppDatabase, $StockEventsTable> {
  $$StockEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staffRef => $composableBuilder(
    column: $table.staffRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hubSeq => $composableBuilder(
    column: $table.hubSeq,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockEventsTable> {
  $$StockEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staffRef => $composableBuilder(
    column: $table.staffRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hubSeq => $composableBuilder(
    column: $table.hubSeq,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockEventsTable> {
  $$StockEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get staffRef =>
      $composableBuilder(column: $table.staffRef, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get hubSeq =>
      $composableBuilder(column: $table.hubSeq, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockEventsTable,
          StockEvent,
          $$StockEventsTableFilterComposer,
          $$StockEventsTableOrderingComposer,
          $$StockEventsTableAnnotationComposer,
          $$StockEventsTableCreateCompanionBuilder,
          $$StockEventsTableUpdateCompanionBuilder,
          (StockEvent, $$StockEventsTableReferences),
          StockEvent,
          PrefetchHooks Function({bool productId})
        > {
  $$StockEventsTableTableManager(_$AppDatabase db, $StockEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> quantityDelta = const Value.absent(),
                Value<int?> unitPrice = const Value.absent(),
                Value<String?> receiptId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> staffRef = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> hubSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockEventsCompanion(
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
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String productId,
                required String eventType,
                required int quantityDelta,
                Value<int?> unitPrice = const Value.absent(),
                Value<String?> receiptId = const Value.absent(),
                required String deviceId,
                required String staffRef,
                Value<String?> note = const Value.absent(),
                required int createdAt,
                Value<int?> hubSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockEventsCompanion.insert(
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
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StockEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$StockEventsTableReferences
                                    ._productIdTable(db),
                                referencedColumn: $$StockEventsTableReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StockEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockEventsTable,
      StockEvent,
      $$StockEventsTableFilterComposer,
      $$StockEventsTableOrderingComposer,
      $$StockEventsTableAnnotationComposer,
      $$StockEventsTableCreateCompanionBuilder,
      $$StockEventsTableUpdateCompanionBuilder,
      (StockEvent, $$StockEventsTableReferences),
      StockEvent,
      PrefetchHooks Function({bool productId})
    >;
typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      required String deviceId,
      required String displayName,
      required String role,
      required String secretHash,
      Value<bool> isRevoked,
      Value<int?> lastSeenAt,
      Value<int> lastAckedSeq,
      Value<int> rowid,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<String> deviceId,
      Value<String> displayName,
      Value<String> role,
      Value<String> secretHash,
      Value<bool> isRevoked,
      Value<int?> lastSeenAt,
      Value<int> lastAckedSeq,
      Value<int> rowid,
    });

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secretHash => $composableBuilder(
    column: $table.secretHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secretHash => $composableBuilder(
    column: $table.secretHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get secretHash => $composableBuilder(
    column: $table.secretHash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRevoked =>
      $composableBuilder(column: $table.isRevoked, builder: (column) => column);

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => column,
  );
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          Device,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
          Device,
          PrefetchHooks Function()
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> secretHash = const Value.absent(),
                Value<bool> isRevoked = const Value.absent(),
                Value<int?> lastSeenAt = const Value.absent(),
                Value<int> lastAckedSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                deviceId: deviceId,
                displayName: displayName,
                role: role,
                secretHash: secretHash,
                isRevoked: isRevoked,
                lastSeenAt: lastSeenAt,
                lastAckedSeq: lastAckedSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String displayName,
                required String role,
                required String secretHash,
                Value<bool> isRevoked = const Value.absent(),
                Value<int?> lastSeenAt = const Value.absent(),
                Value<int> lastAckedSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                deviceId: deviceId,
                displayName: displayName,
                role: role,
                secretHash: secretHash,
                isRevoked: isRevoked,
                lastSeenAt: lastSeenAt,
                lastAckedSeq: lastAckedSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      Device,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
      Device,
      PrefetchHooks Function()
    >;
typedef $$StaffTableCreateCompanionBuilder =
    StaffCompanion Function({
      required String staffRef,
      required String displayName,
      required String pinHash,
      Value<bool> isAdmin,
      Value<bool> isActive,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$StaffTableUpdateCompanionBuilder =
    StaffCompanion Function({
      Value<String> staffRef,
      Value<String> displayName,
      Value<String> pinHash,
      Value<bool> isAdmin,
      Value<bool> isActive,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$StaffTableFilterComposer extends Composer<_$AppDatabase, $StaffTable> {
  $$StaffTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get staffRef => $composableBuilder(
    column: $table.staffRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaffTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffTable> {
  $$StaffTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get staffRef => $composableBuilder(
    column: $table.staffRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffTable> {
  $$StaffTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get staffRef =>
      $composableBuilder(column: $table.staffRef, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<bool> get isAdmin =>
      $composableBuilder(column: $table.isAdmin, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StaffTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffTable,
          StaffData,
          $$StaffTableFilterComposer,
          $$StaffTableOrderingComposer,
          $$StaffTableAnnotationComposer,
          $$StaffTableCreateCompanionBuilder,
          $$StaffTableUpdateCompanionBuilder,
          (StaffData, BaseReferences<_$AppDatabase, $StaffTable, StaffData>),
          StaffData,
          PrefetchHooks Function()
        > {
  $$StaffTableTableManager(_$AppDatabase db, $StaffTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StaffTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StaffTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> staffRef = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> pinHash = const Value.absent(),
                Value<bool> isAdmin = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffCompanion(
                staffRef: staffRef,
                displayName: displayName,
                pinHash: pinHash,
                isAdmin: isAdmin,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String staffRef,
                required String displayName,
                required String pinHash,
                Value<bool> isAdmin = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StaffCompanion.insert(
                staffRef: staffRef,
                displayName: displayName,
                pinHash: pinHash,
                isAdmin: isAdmin,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaffTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffTable,
      StaffData,
      $$StaffTableFilterComposer,
      $$StaffTableOrderingComposer,
      $$StaffTableAnnotationComposer,
      $$StaffTableCreateCompanionBuilder,
      $$StaffTableUpdateCompanionBuilder,
      (StaffData, BaseReferences<_$AppDatabase, $StaffTable, StaffData>),
      StaffData,
      PrefetchHooks Function()
    >;
typedef $$StockLevelsTableCreateCompanionBuilder =
    StockLevelsCompanion Function({
      required String productId,
      Value<int> quantity,
      Value<int> projectedThroughSeq,
      Value<int> rowid,
    });
typedef $$StockLevelsTableUpdateCompanionBuilder =
    StockLevelsCompanion Function({
      Value<String> productId,
      Value<int> quantity,
      Value<int> projectedThroughSeq,
      Value<int> rowid,
    });

class $$StockLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $StockLevelsTable> {
  $$StockLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get projectedThroughSeq => $composableBuilder(
    column: $table.projectedThroughSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockLevelsTable> {
  $$StockLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get projectedThroughSeq => $composableBuilder(
    column: $table.projectedThroughSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockLevelsTable> {
  $$StockLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get projectedThroughSeq => $composableBuilder(
    column: $table.projectedThroughSeq,
    builder: (column) => column,
  );
}

class $$StockLevelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockLevelsTable,
          StockLevel,
          $$StockLevelsTableFilterComposer,
          $$StockLevelsTableOrderingComposer,
          $$StockLevelsTableAnnotationComposer,
          $$StockLevelsTableCreateCompanionBuilder,
          $$StockLevelsTableUpdateCompanionBuilder,
          (
            StockLevel,
            BaseReferences<_$AppDatabase, $StockLevelsTable, StockLevel>,
          ),
          StockLevel,
          PrefetchHooks Function()
        > {
  $$StockLevelsTableTableManager(_$AppDatabase db, $StockLevelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> projectedThroughSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockLevelsCompanion(
                productId: productId,
                quantity: quantity,
                projectedThroughSeq: projectedThroughSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                Value<int> quantity = const Value.absent(),
                Value<int> projectedThroughSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockLevelsCompanion.insert(
                productId: productId,
                quantity: quantity,
                projectedThroughSeq: projectedThroughSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockLevelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockLevelsTable,
      StockLevel,
      $$StockLevelsTableFilterComposer,
      $$StockLevelsTableOrderingComposer,
      $$StockLevelsTableAnnotationComposer,
      $$StockLevelsTableCreateCompanionBuilder,
      $$StockLevelsTableUpdateCompanionBuilder,
      (
        StockLevel,
        BaseReferences<_$AppDatabase, $StockLevelsTable, StockLevel>,
      ),
      StockLevel,
      PrefetchHooks Function()
    >;
typedef $$AppStateTableCreateCompanionBuilder =
    AppStateCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppStateTableUpdateCompanionBuilder =
    AppStateCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppStateTableFilterComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppStateTableOrderingComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppStateTable,
          AppStateData,
          $$AppStateTableFilterComposer,
          $$AppStateTableOrderingComposer,
          $$AppStateTableAnnotationComposer,
          $$AppStateTableCreateCompanionBuilder,
          $$AppStateTableUpdateCompanionBuilder,
          (
            AppStateData,
            BaseReferences<_$AppDatabase, $AppStateTable, AppStateData>,
          ),
          AppStateData,
          PrefetchHooks Function()
        > {
  $$AppStateTableTableManager(_$AppDatabase db, $AppStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppStateCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppStateTable,
      AppStateData,
      $$AppStateTableFilterComposer,
      $$AppStateTableOrderingComposer,
      $$AppStateTableAnnotationComposer,
      $$AppStateTableCreateCompanionBuilder,
      $$AppStateTableUpdateCompanionBuilder,
      (
        AppStateData,
        BaseReferences<_$AppDatabase, $AppStateTable, AppStateData>,
      ),
      AppStateData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$StockEventsTableTableManager get stockEvents =>
      $$StockEventsTableTableManager(_db, _db.stockEvents);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$StaffTableTableManager get staff =>
      $$StaffTableTableManager(_db, _db.staff);
  $$StockLevelsTableTableManager get stockLevels =>
      $$StockLevelsTableTableManager(_db, _db.stockLevels);
  $$AppStateTableTableManager get appState =>
      $$AppStateTableTableManager(_db, _db.appState);
}
