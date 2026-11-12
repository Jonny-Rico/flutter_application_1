import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/shop_category.dart';

class TripItem {
  const TripItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.category,
    required this.bought,
    required this.isStaple,
    required this.addedDuringTrip,
    this.needItemId,
    this.aisle,
  });

  final String id;
  final String title;
  final int quantity;
  final ShopCategory category;
  final bool bought;
  final bool isStaple;
  final bool addedDuringTrip;
  final String? needItemId;
  final String? aisle;

  TripItem copyWith({
    bool? bought,
    String? title,
    int? quantity,
  }) {
    return TripItem(
      id: id,
      title: title ?? this.title,
      quantity: quantity ?? this.quantity,
      category: category,
      bought: bought ?? this.bought,
      isStaple: isStaple,
      addedDuringTrip: addedDuringTrip,
      needItemId: needItemId,
      aisle: aisle,
    );
  }

  factory TripItem.fromNeed(NeedItem item) {
    return TripItem(
      id: item.id,
      title: item.title,
      quantity: item.quantity,
      category: item.category,
      bought: false,
      isStaple: item.isStaple,
      addedDuringTrip: false,
      needItemId: item.id,
      aisle: item.aisle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'quantity': quantity,
      'category': category.value,
      'bought': bought,
      'isStaple': isStaple,
      'addedDuringTrip': addedDuringTrip,
      'needItemId': needItemId,
      'aisle': aisle,
    };
  }

  factory TripItem.fromMap(Map<String, dynamic> map) {
    return TripItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      category: ShopCategory.fromValue(map['category'] as String?),
      bought: map['bought'] as bool? ?? false,
      isStaple: map['isStaple'] as bool? ?? false,
      addedDuringTrip: map['addedDuringTrip'] as bool? ?? false,
      needItemId: map['needItemId'] as String?,
      aisle: map['aisle'] as String?,
    );
  }
}
