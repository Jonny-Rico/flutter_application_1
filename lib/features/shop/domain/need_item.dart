import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/features/shop/domain/shop_category.dart';

class NeedItem {
  const NeedItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.category,
    required this.isStaple,
    required this.bought,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.aisle,
  });

  final String id;
  final String title;
  final int quantity;
  final ShopCategory category;
  final bool isStaple;
  final bool bought;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? aisle;

  NeedItem copyWith({
    String? title,
    int? quantity,
    ShopCategory? category,
    bool? isStaple,
    bool? bought,
    DateTime? updatedAt,
    String? aisle,
    bool clearAisle = false,
  }) {
    return NeedItem(
      id: id,
      title: title ?? this.title,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isStaple: isStaple ?? this.isStaple,
      bought: bought ?? this.bought,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aisle: clearAisle ? null : (aisle ?? this.aisle),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'quantity': quantity,
      'category': category.value,
      'isStaple': isStaple,
      'bought': bought,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'aisle': aisle,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'quantity': quantity,
      'category': category.value,
      'isStaple': isStaple,
      'bought': bought,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'aisle': aisle,
    };
  }

  factory NeedItem.fromMap(Map<String, dynamic> map) {
    return NeedItem(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      category: ShopCategory.fromValue(map['category'] as String?),
      isStaple: map['isStaple'] as bool? ?? false,
      bought: map['bought'] as bool? ?? false,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      aisle: map['aisle'] as String?,
    );
  }

  factory NeedItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NeedItem.fromMap({...data, 'id': doc.id});
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
