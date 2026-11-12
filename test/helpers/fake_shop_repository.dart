import 'dart:async';

import 'package:family_tasks/features/shop/data/shop_repository.dart';
import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';
import 'package:family_tasks/features/shop/domain/shop_category.dart';
import 'package:family_tasks/features/shop/domain/shop_completion.dart';
import 'package:family_tasks/features/shop/domain/shop_trip.dart';
import 'package:family_tasks/features/shop/domain/shop_trip_status.dart';
import 'package:family_tasks/features/shop/domain/trip_item.dart';

class FakeShopRepository implements ShopRepository {
  FakeShopRepository({
    List<NeedItem> needItems = const [],
    List<ShopTrip> trips = const [],
    List<PlanItem> planItems = const [],
    List<PlanItem> personalItems = const [],
  }) {
    this.needItems.addAll(needItems);
    this.trips.addAll(trips);
    this.planItems.addAll(planItems);
    this.personalItems.addAll(personalItems);
  }

  final List<NeedItem> needItems = [];
  final List<ShopTrip> trips = [];
  final List<PlanItem> planItems = [];
  final List<PlanItem> personalItems = [];
  final _needController = StreamController<List<NeedItem>>.broadcast();
  final _tripController = StreamController<List<ShopTrip>>.broadcast();
  final _planController = StreamController<List<PlanItem>>.broadcast();
  final _personalController = StreamController<List<PlanItem>>.broadcast();
  var _nextId = 1;

  void _emitNeed() => _needController.add(List<NeedItem>.from(needItems));
  void _emitTrips() => _tripController.add(List<ShopTrip>.from(trips));
  void _emitPlans() => _planController.add(List<PlanItem>.from(planItems));
  void _emitPersonal() =>
      _personalController.add(List<PlanItem>.from(personalItems));

  NeedItem? _needById(String id) {
    for (final item in needItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  ShopTrip? _tripById(String id) {
    for (final trip in trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  @override
  List<NeedItem> getCachedNeedItems({required String userId, String? groupId}) {
    return List<NeedItem>.from(needItems);
  }

  @override
  List<ShopTrip> getCachedTrips({required String userId, String? groupId}) {
    return List<ShopTrip>.from(trips);
  }

  @override
  List<PlanItem> getCachedPlanItems({required String userId, String? groupId}) {
    return List<PlanItem>.from(planItems);
  }

  @override
  List<PlanItem> getCachedPersonalItems({required String userId}) {
    return List<PlanItem>.from(personalItems);
  }

  @override
  Stream<List<NeedItem>> watchNeedItems({
    required String userId,
    String? groupId,
  }) {
    return Stream<List<NeedItem>>.multi((listener) {
      listener.add(List<NeedItem>.from(needItems));
      final sub = _needController.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<ShopTrip>> watchTrips({
    required String userId,
    String? groupId,
  }) {
    return Stream<List<ShopTrip>>.multi((listener) {
      listener.add(List<ShopTrip>.from(trips));
      final sub = _tripController.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = sub.cancel;
    });
  }

  @override
  Future<NeedItem> createNeedItem({
    required String userId,
    String? groupId,
    required String createdBy,
    required String title,
    int quantity = 1,
    ShopCategory category = ShopCategory.groceries,
    bool isStaple = false,
    String? aisle,
  }) async {
    final now = DateTime.now();
    final item = NeedItem(
      id: 'need-${_nextId++}',
      title: title.trim(),
      quantity: quantity < 1 ? 1 : quantity,
      category: category,
      isStaple: isStaple,
      bought: false,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      aisle: aisle,
    );
    needItems.insert(0, item);
    _emitNeed();
    return item;
  }

  @override
  Future<void> toggleNeedBought({
    required String userId,
    String? groupId,
    required String itemId,
    required bool bought,
  }) async {
    final existing = _needById(itemId);
    if (existing == null) throw Exception('Item not found');
    final index = needItems.indexOf(existing);
    needItems[index] = existing.copyWith(bought: bought, updatedAt: DateTime.now());
    _emitNeed();
  }

  @override
  Future<void> deleteNeedItem({
    required String userId,
    String? groupId,
    required String itemId,
  }) async {
    needItems.removeWhere((item) => item.id == itemId);
    _emitNeed();
  }

  @override
  Future<void> clearNeedItems({
    required String userId,
    String? groupId,
    required bool boughtOnly,
  }) async {
    needItems.removeWhere((item) => boughtOnly ? item.bought : true);
    _emitNeed();
  }

  @override
  Stream<List<PlanItem>> watchPlanItems({
    required String userId,
    String? groupId,
  }) {
    return Stream<List<PlanItem>>.multi((listener) {
      listener.add(List<PlanItem>.from(planItems));
      final sub = _planController.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = sub.cancel;
    });
  }

  @override
  Future<PlanItem> createPlanItem({
    required String userId,
    String? groupId,
    required String createdBy,
    required String title,
    int quantity = 1,
    String? note,
  }) async {
    final now = DateTime.now();
    final trimmed = note?.trim();
    final item = PlanItem(
      id: 'plan-${_nextId++}',
      title: title.trim(),
      quantity: quantity < 1 ? 1 : quantity,
      bought: false,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    planItems.insert(0, item);
    _emitPlans();
    return item;
  }

  @override
  Future<void> togglePlanBought({
    required String userId,
    String? groupId,
    required String itemId,
    required bool bought,
  }) async {
    final index = planItems.indexWhere((item) => item.id == itemId);
    if (index < 0) throw Exception('Item not found');
    planItems[index] =
        planItems[index].copyWith(bought: bought, updatedAt: DateTime.now());
    _emitPlans();
  }

  @override
  Future<void> deletePlanItem({
    required String userId,
    String? groupId,
    required String itemId,
  }) async {
    planItems.removeWhere((item) => item.id == itemId);
    _emitPlans();
  }

  @override
  Stream<List<PlanItem>> watchPersonalItems({required String userId}) {
    return Stream<List<PlanItem>>.multi((listener) {
      listener.add(List<PlanItem>.from(personalItems));
      final sub = _personalController.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = sub.cancel;
    });
  }

  @override
  Future<PlanItem> createPersonalItem({
    required String userId,
    required String createdBy,
    required String title,
    int quantity = 1,
    String? note,
  }) async {
    final now = DateTime.now();
    final trimmed = note?.trim();
    final item = PlanItem(
      id: 'mine-${_nextId++}',
      title: title.trim(),
      quantity: quantity < 1 ? 1 : quantity,
      bought: false,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    personalItems.insert(0, item);
    _emitPersonal();
    return item;
  }

  @override
  Future<void> togglePersonalBought({
    required String userId,
    required String itemId,
    required bool bought,
  }) async {
    final index = personalItems.indexWhere((item) => item.id == itemId);
    if (index < 0) throw Exception('Item not found');
    personalItems[index] =
        personalItems[index].copyWith(bought: bought, updatedAt: DateTime.now());
    _emitPersonal();
  }

  @override
  Future<void> deletePersonalItem({
    required String userId,
    required String itemId,
  }) async {
    personalItems.removeWhere((item) => item.id == itemId);
    _emitPersonal();
  }

  @override
  Future<ShopTrip> startTrip({
    required String userId,
    String? groupId,
    required String createdBy,
    required String storeName,
    required List<NeedItem> selectedNeedItems,
  }) async {
    for (final trip in trips) {
      if (trip.isActive) return trip;
    }
    final now = DateTime.now();
    final trip = ShopTrip(
      id: 'trip-${_nextId++}',
      storeName: storeName.trim().isEmpty ? 'Store' : storeName.trim(),
      status: ShopTripStatus.active,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      items: selectedNeedItems.map(TripItem.fromNeed).toList(),
    );
    trips.insert(0, trip);
    _emitTrips();
    return trip;
  }

  @override
  Future<void> toggleTripItemBought({
    required String userId,
    String? groupId,
    required String tripId,
    required String itemId,
    required bool bought,
  }) async {
    final trip = _tripById(tripId);
    if (trip == null) throw Exception('Trip not found');
    final items = [
      for (final item in trip.items)
        if (item.id == itemId) item.copyWith(bought: bought) else item,
    ];
    final index = trips.indexOf(trip);
    trips[index] = trip.copyWith(items: items, updatedAt: DateTime.now());
    _emitTrips();
  }

  @override
  Future<TripItem> addItemToActiveTrip({
    required String userId,
    String? groupId,
    required String createdBy,
    required String tripId,
    required String title,
    int quantity = 1,
    ShopCategory category = ShopCategory.groceries,
  }) async {
    final need = await createNeedItem(
      userId: userId,
      groupId: groupId,
      createdBy: createdBy,
      title: title,
      quantity: quantity,
      category: category,
    );
    final trip = _tripById(tripId);
    if (trip == null) throw Exception('Trip not found');
    final tripItem = TripItem(
      id: need.id,
      title: need.title,
      quantity: need.quantity,
      category: need.category,
      bought: false,
      isStaple: need.isStaple,
      addedDuringTrip: true,
      needItemId: need.id,
    );
    final index = trips.indexOf(trip);
    trips[index] = trip.copyWith(
      items: [...trip.items, tripItem],
      updatedAt: DateTime.now(),
    );
    _emitTrips();
    return tripItem;
  }

  @override
  Future<void> completeTrip({
    required String userId,
    String? groupId,
    required String tripId,
  }) async {
    final trip = _tripById(tripId);
    if (trip == null) throw Exception('Trip not found');
    final now = DateTime.now();
    for (final tripItem in trip.items) {
      final needId = tripItem.needItemId;
      if (needId == null || !tripItem.bought) continue;
      final need = _needById(needId);
      if (need == null) continue;
      final next = applyTripPurchaseToNeed(need: need, tripItem: tripItem)
          .copyWith(updatedAt: now);
      needItems[needItems.indexOf(need)] = next;
    }
    _emitNeed();
    trips[trips.indexOf(trip)] = trip.copyWith(
      status: ShopTripStatus.completed,
      completedAt: now,
      updatedAt: now,
    );
    _emitTrips();
  }

  @override
  Future<void> endTrip({
    required String userId,
    String? groupId,
    required String tripId,
  }) async {
    final trip = _tripById(tripId);
    if (trip == null) throw Exception('Trip not found');
    final now = DateTime.now();
    trips[trips.indexOf(trip)] = trip.copyWith(
      status: ShopTripStatus.ended,
      completedAt: now,
      updatedAt: now,
    );
    _emitTrips();
  }
}
