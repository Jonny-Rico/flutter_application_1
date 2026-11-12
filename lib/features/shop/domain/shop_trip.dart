import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/features/shop/domain/shop_trip_status.dart';
import 'package:family_tasks/features/shop/domain/trip_item.dart';

class ShopTrip {
  const ShopTrip({
    required this.id,
    required this.storeName,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.completedAt,
  });

  final String id;
  final String storeName;
  final ShopTripStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final List<TripItem> items;

  int get boughtCount => items.where((item) => item.bought).length;

  bool get isActive => status == ShopTripStatus.active;

  ShopTrip copyWith({
    String? storeName,
    ShopTripStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    List<TripItem>? items,
  }) {
    return ShopTrip(
      id: id,
      storeName: storeName ?? this.storeName,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
      'status': status.value,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeName': storeName,
      'status': status.value,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory ShopTrip.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return ShopTrip(
      id: map['id'] as String,
      storeName: map['storeName'] as String? ?? 'Store',
      status: ShopTripStatus.fromValue(map['status'] as String?),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      completedAt: _parseDate(map['completedAt']),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => TripItem.fromMap(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  factory ShopTrip.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ShopTrip.fromMap({...data, 'id': doc.id});
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
