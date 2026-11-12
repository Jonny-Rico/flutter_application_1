import 'package:cloud_firestore/cloud_firestore.dart';

class PlanItem {
  const PlanItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.bought,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  final String id;
  final String title;
  final int quantity;
  final bool bought;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  PlanItem copyWith({
    String? title,
    int? quantity,
    bool? bought,
    DateTime? updatedAt,
    String? note,
    bool clearNote = false,
  }) {
    return PlanItem(
      id: id,
      title: title ?? this.title,
      quantity: quantity ?? this.quantity,
      bought: bought ?? this.bought,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'quantity': quantity,
      'bought': bought,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'note': note,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'quantity': quantity,
      'bought': bought,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'note': note,
    };
  }

  factory PlanItem.fromMap(Map<String, dynamic> map) {
    return PlanItem(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      bought: map['bought'] as bool? ?? false,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      note: map['note'] as String?,
    );
  }

  factory PlanItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PlanItem.fromMap({...data, 'id': doc.id});
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
