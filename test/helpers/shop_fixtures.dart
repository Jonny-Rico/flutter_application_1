import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';
import 'package:family_tasks/features/shop/domain/shop_category.dart';
import 'package:family_tasks/features/shop/domain/shop_trip.dart';
import 'package:family_tasks/features/shop/domain/shop_trip_status.dart';
import 'package:family_tasks/features/shop/domain/trip_item.dart';

final _now = DateTime(2026, 8, 18, 12);

NeedItem buildNeedItem({
  String id = 'n1',
  String title = 'Milk',
  int quantity = 1,
  ShopCategory category = ShopCategory.groceries,
  bool isStaple = false,
  bool bought = false,
  String createdBy = 'user-a',
}) {
  return NeedItem(
    id: id,
    title: title,
    quantity: quantity,
    category: category,
    isStaple: isStaple,
    bought: bought,
    createdBy: createdBy,
    createdAt: _now,
    updatedAt: _now,
  );
}

PlanItem buildPlanItem({
  String id = 'p1',
  String title = 'Sofa',
  int quantity = 1,
  bool bought = false,
  String? note,
  String createdBy = 'user-a',
}) {
  return PlanItem(
    id: id,
    title: title,
    quantity: quantity,
    bought: bought,
    createdBy: createdBy,
    createdAt: _now,
    updatedAt: _now,
    note: note,
  );
}

TripItem buildTripItem({
  String id = 'n1',
  String title = 'Milk',
  bool bought = false,
  bool isStaple = false,
  bool addedDuringTrip = false,
  String? needItemId,
  ShopCategory category = ShopCategory.groceries,
}) {
  return TripItem(
    id: id,
    title: title,
    quantity: 1,
    category: category,
    bought: bought,
    isStaple: isStaple,
    addedDuringTrip: addedDuringTrip,
    needItemId: needItemId ?? id,
  );
}

ShopTrip buildTrip({
  String id = 'trip-1',
  String storeName = 'Lidl',
  ShopTripStatus status = ShopTripStatus.active,
  List<TripItem>? items,
  String createdBy = 'user-a',
}) {
  return ShopTrip(
    id: id,
    storeName: storeName,
    status: status,
    createdBy: createdBy,
    createdAt: _now,
    updatedAt: _now,
    completedAt: status == ShopTripStatus.active ? null : _now,
    items: items ?? [buildTripItem()],
  );
}
