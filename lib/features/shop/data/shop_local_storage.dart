import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';
import 'package:family_tasks/features/shop/domain/shop_trip.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ShopLocalStorage {
  ShopLocalStorage(this._box);

  final Box<dynamic> _box;

  String _needKey(String cacheKey) => 'shop_need_$cacheKey';
  String _tripKey(String cacheKey) => 'shop_trips_$cacheKey';
  String _planKey(String cacheKey) => 'shop_plans_$cacheKey';
  String _personalKey(String userId) => 'shop_personal_$userId';

  Future<void> saveNeedItems(String cacheKey, List<NeedItem> items) async {
    await _box.put(
      _needKey(cacheKey),
      items.map((item) => item.toMap()).toList(),
    );
  }

  List<NeedItem> loadNeedItems(String cacheKey) {
    final raw = _box.get(_needKey(cacheKey));
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((entry) => NeedItem.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<void> saveTrips(String cacheKey, List<ShopTrip> trips) async {
    await _box.put(
      _tripKey(cacheKey),
      trips.map((trip) => trip.toMap()).toList(),
    );
  }

  List<ShopTrip> loadTrips(String cacheKey) {
    final raw = _box.get(_tripKey(cacheKey));
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((entry) => ShopTrip.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<void> savePlanItems(String cacheKey, List<PlanItem> items) async {
    await _box.put(
      _planKey(cacheKey),
      items.map((item) => item.toMap()).toList(),
    );
  }

  List<PlanItem> loadPlanItems(String cacheKey) {
    final raw = _box.get(_planKey(cacheKey));
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((entry) => PlanItem.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<void> savePersonalItems(String userId, List<PlanItem> items) async {
    await _box.put(
      _personalKey(userId),
      items.map((item) => item.toMap()).toList(),
    );
  }

  List<PlanItem> loadPersonalItems(String userId) {
    final raw = _box.get(_personalKey(userId));
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((entry) => PlanItem.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }
}
