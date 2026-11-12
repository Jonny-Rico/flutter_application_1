import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/core/firebase/firestore_errors.dart';
import 'package:family_tasks/features/shop/data/shop_local_storage.dart';
import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';
import 'package:family_tasks/features/shop/domain/shop_category.dart';
import 'package:family_tasks/features/shop/domain/shop_completion.dart';
import 'package:family_tasks/features/shop/domain/shop_trip.dart';
import 'package:family_tasks/features/shop/domain/shop_trip_status.dart';
import 'package:family_tasks/features/shop/domain/trip_item.dart';
import 'package:uuid/uuid.dart';

class ShopRepository {
  ShopRepository({
    FirebaseFirestore? firestore,
    this._localStorage,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final ShopLocalStorage? _localStorage;
  final Uuid _uuid;
  final Map<String, List<NeedItem>> _needMemory = {};
  final Map<String, List<ShopTrip>> _tripMemory = {};
  final Map<String, List<PlanItem>> _planMemory = {};
  final Map<String, List<PlanItem>> _personalMemory = {};

  String _cacheKey({required String userId, String? groupId}) {
    return groupId ?? 'user_$userId';
  }

  CollectionReference<Map<String, dynamic>> _needRef({
    required String userId,
    String? groupId,
  }) {
    return groupId != null
        ? _firestore.collection('groups').doc(groupId).collection('needItems')
        : _firestore.collection('users').doc(userId).collection('needItems');
  }

  CollectionReference<Map<String, dynamic>> _tripRef({
    required String userId,
    String? groupId,
  }) {
    return groupId != null
        ? _firestore.collection('groups').doc(groupId).collection('shopTrips')
        : _firestore.collection('users').doc(userId).collection('shopTrips');
  }

  CollectionReference<Map<String, dynamic>> _planRef({
    required String userId,
    String? groupId,
  }) {
    return groupId != null
        ? _firestore.collection('groups').doc(groupId).collection('planItems')
        : _firestore.collection('users').doc(userId).collection('planItems');
  }

  CollectionReference<Map<String, dynamic>> _personalRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('personalItems');
  }

  List<NeedItem> getCachedNeedItems({
    required String userId,
    String? groupId,
  }) {
    final key = _cacheKey(userId: userId, groupId: groupId);
    return List<NeedItem>.from(
      _needMemory[key] ?? _localStorage?.loadNeedItems(key) ?? const [],
    );
  }

  List<ShopTrip> getCachedTrips({
    required String userId,
    String? groupId,
  }) {
    final key = _cacheKey(userId: userId, groupId: groupId);
    return List<ShopTrip>.from(
      _tripMemory[key] ?? _localStorage?.loadTrips(key) ?? const [],
    );
  }

  List<PlanItem> getCachedPlanItems({
    required String userId,
    String? groupId,
  }) {
    final key = _cacheKey(userId: userId, groupId: groupId);
    return List<PlanItem>.from(
      _planMemory[key] ?? _localStorage?.loadPlanItems(key) ?? const [],
    );
  }

  List<PlanItem> getCachedPersonalItems({required String userId}) {
    return List<PlanItem>.from(
      _personalMemory[userId] ??
          _localStorage?.loadPersonalItems(userId) ??
          const [],
    );
  }

  Stream<List<NeedItem>> watchNeedItems({
    required String userId,
    String? groupId,
  }) {
    final key = _cacheKey(userId: userId, groupId: groupId);
    return _needRef(userId: userId, groupId: groupId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NeedItem.fromFirestore).toList())
        .asyncMap((items) async {
          _needMemory[key] = List<NeedItem>.from(items);
          await _localStorage?.saveNeedItems(key, items);
          return items;
        })
        .ignoreFirestoreAuthLoss();
  }

  Stream<List<ShopTrip>> watchTrips({
    required String userId,
    String? groupId,
  }) {
    final key = _cacheKey(userId: userId, groupId: groupId);
    return _tripRef(userId: userId, groupId: groupId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ShopTrip.fromFirestore).toList())
        .asyncMap((trips) async {
          _tripMemory[key] = List<ShopTrip>.from(trips);
          await _localStorage?.saveTrips(key, trips);
          return trips;
        })
        .ignoreFirestoreAuthLoss();
  }

  Stream<List<PlanItem>> watchPlanItems({
    required String userId,
    String? groupId,
  }) {
    final key = _cacheKey(userId: userId, groupId: groupId);
    return _planRef(userId: userId, groupId: groupId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PlanItem.fromFirestore).toList())
        .asyncMap((items) async {
          _planMemory[key] = List<PlanItem>.from(items);
          await _localStorage?.savePlanItems(key, items);
          return items;
        })
        .ignoreFirestoreAuthLoss();
  }

  Stream<List<PlanItem>> watchPersonalItems({required String userId}) {
    return _personalRef(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PlanItem.fromFirestore).toList())
        .asyncMap((items) async {
          _personalMemory[userId] = List<PlanItem>.from(items);
          await _localStorage?.savePersonalItems(userId, items);
          return items;
        })
        .ignoreFirestoreAuthLoss();
  }

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
      id: _uuid.v4(),
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
    await _needRef(userId: userId, groupId: groupId)
        .doc(item.id)
        .set(item.toFirestore());
    await _upsertNeed(userId: userId, groupId: groupId, item: item);
    return item;
  }

  Future<void> toggleNeedBought({
    required String userId,
    String? groupId,
    required String itemId,
    required bool bought,
  }) async {
    final existing = _findNeed(userId: userId, groupId: groupId, itemId: itemId);
    if (existing == null) throw Exception('Item not found');
    final updated = existing.copyWith(bought: bought, updatedAt: DateTime.now());
    await _needRef(userId: userId, groupId: groupId)
        .doc(itemId)
        .update(updated.toFirestore());
    await _upsertNeed(userId: userId, groupId: groupId, item: updated);
  }

  Future<void> deleteNeedItem({
    required String userId,
    String? groupId,
    required String itemId,
  }) async {
    await _needRef(userId: userId, groupId: groupId).doc(itemId).delete();
    final key = _cacheKey(userId: userId, groupId: groupId);
    final next = getCachedNeedItems(userId: userId, groupId: groupId)
        .where((item) => item.id != itemId)
        .toList();
    _needMemory[key] = next;
    await _localStorage?.saveNeedItems(key, next);
  }

  Future<void> clearNeedItems({
    required String userId,
    String? groupId,
    required bool boughtOnly,
  }) async {
    final current = getCachedNeedItems(userId: userId, groupId: groupId);
    final toDelete = [
      for (final item in current)
        if (!boughtOnly || item.bought) item,
    ];
    if (toDelete.isEmpty) return;

    final ref = _needRef(userId: userId, groupId: groupId);
    final batch = _firestore.batch();
    for (final item in toDelete) {
      batch.delete(ref.doc(item.id));
    }
    await batch.commit();

    final remaining = [
      for (final item in current)
        if (!toDelete.any((deleted) => deleted.id == item.id)) item,
    ];
    final key = _cacheKey(userId: userId, groupId: groupId);
    _needMemory[key] = remaining;
    await _localStorage?.saveNeedItems(key, remaining);
  }

  Future<ShopTrip> startTrip({
    required String userId,
    String? groupId,
    required String createdBy,
    required String storeName,
    required List<NeedItem> selectedNeedItems,
  }) async {
    final active = getCachedTrips(userId: userId, groupId: groupId)
        .where((trip) => trip.isActive)
        .toList();
    if (active.isNotEmpty) return active.first;

    final now = DateTime.now();
    final trip = ShopTrip(
      id: _uuid.v4(),
      storeName: storeName.trim().isEmpty ? 'Store' : storeName.trim(),
      status: ShopTripStatus.active,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      items: selectedNeedItems.map(TripItem.fromNeed).toList(),
    );
    await _tripRef(userId: userId, groupId: groupId)
        .doc(trip.id)
        .set(trip.toFirestore());
    await _upsertTrip(userId: userId, groupId: groupId, trip: trip);
    return trip;
  }

  Future<void> toggleTripItemBought({
    required String userId,
    String? groupId,
    required String tripId,
    required String itemId,
    required bool bought,
  }) async {
    final trip = _findTrip(userId: userId, groupId: groupId, tripId: tripId);
    if (trip == null) throw Exception('Trip not found');
    if (!trip.isActive) throw Exception('This trip is closed.');

    final items = [
      for (final item in trip.items)
        if (item.id == itemId) item.copyWith(bought: bought) else item,
    ];
    final updated = trip.copyWith(items: items, updatedAt: DateTime.now());
    await _tripRef(userId: userId, groupId: groupId)
        .doc(tripId)
        .update(updated.toFirestore());
    await _upsertTrip(userId: userId, groupId: groupId, trip: updated);
  }

  Future<TripItem> addItemToActiveTrip({
    required String userId,
    String? groupId,
    required String createdBy,
    required String tripId,
    required String title,
    int quantity = 1,
    ShopCategory category = ShopCategory.groceries,
  }) async {
    final trip = _findTrip(userId: userId, groupId: groupId, tripId: tripId);
    if (trip == null) throw Exception('Trip not found');
    if (!trip.isActive) throw Exception('This trip is closed.');

    final need = await createNeedItem(
      userId: userId,
      groupId: groupId,
      createdBy: createdBy,
      title: title,
      quantity: quantity,
      category: category,
    );
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
    final updated = trip.copyWith(
      items: [...trip.items, tripItem],
      updatedAt: DateTime.now(),
    );
    await _tripRef(userId: userId, groupId: groupId)
        .doc(tripId)
        .update(updated.toFirestore());
    await _upsertTrip(userId: userId, groupId: groupId, trip: updated);
    return tripItem;
  }

  Future<void> completeTrip({
    required String userId,
    String? groupId,
    required String tripId,
  }) async {
    final trip = _findTrip(userId: userId, groupId: groupId, tripId: tripId);
    if (trip == null) throw Exception('Trip not found');
    if (!trip.isActive) return;

    final now = DateTime.now();
    for (final tripItem in trip.items) {
      final needId = tripItem.needItemId;
      if (needId == null || !tripItem.bought) continue;
      final need = _findNeed(userId: userId, groupId: groupId, itemId: needId);
      if (need == null) continue;
      final next = applyTripPurchaseToNeed(need: need, tripItem: tripItem)
          .copyWith(updatedAt: now);
      await _needRef(userId: userId, groupId: groupId)
          .doc(need.id)
          .update(next.toFirestore());
      await _upsertNeed(userId: userId, groupId: groupId, item: next);
    }

    final closed = trip.copyWith(
      status: ShopTripStatus.completed,
      completedAt: now,
      updatedAt: now,
    );
    await _tripRef(userId: userId, groupId: groupId)
        .doc(tripId)
        .update(closed.toFirestore());
    await _upsertTrip(userId: userId, groupId: groupId, trip: closed);
  }

  Future<void> endTrip({
    required String userId,
    String? groupId,
    required String tripId,
  }) async {
    final trip = _findTrip(userId: userId, groupId: groupId, tripId: tripId);
    if (trip == null) throw Exception('Trip not found');
    if (!trip.isActive) return;
    final now = DateTime.now();
    final closed = trip.copyWith(
      status: ShopTripStatus.ended,
      completedAt: now,
      updatedAt: now,
    );
    await _tripRef(userId: userId, groupId: groupId)
        .doc(tripId)
        .update(closed.toFirestore());
    await _upsertTrip(userId: userId, groupId: groupId, trip: closed);
  }

  Future<PlanItem> createPlanItem({
    required String userId,
    String? groupId,
    required String createdBy,
    required String title,
    int quantity = 1,
    String? note,
  }) async {
    final now = DateTime.now();
    final trimmedNote = note?.trim();
    final item = PlanItem(
      id: _uuid.v4(),
      title: title.trim(),
      quantity: quantity < 1 ? 1 : quantity,
      bought: false,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
    );
    await _planRef(userId: userId, groupId: groupId)
        .doc(item.id)
        .set(item.toFirestore());
    await _upsertPlan(userId: userId, groupId: groupId, item: item);
    return item;
  }

  Future<void> togglePlanBought({
    required String userId,
    String? groupId,
    required String itemId,
    required bool bought,
  }) async {
    final existing = _findPlan(userId: userId, groupId: groupId, itemId: itemId);
    if (existing == null) throw Exception('Item not found');
    final updated = existing.copyWith(bought: bought, updatedAt: DateTime.now());
    await _planRef(userId: userId, groupId: groupId)
        .doc(itemId)
        .update(updated.toFirestore());
    await _upsertPlan(userId: userId, groupId: groupId, item: updated);
  }

  Future<void> deletePlanItem({
    required String userId,
    String? groupId,
    required String itemId,
  }) async {
    await _planRef(userId: userId, groupId: groupId).doc(itemId).delete();
    final key = _cacheKey(userId: userId, groupId: groupId);
    final next = getCachedPlanItems(userId: userId, groupId: groupId)
        .where((item) => item.id != itemId)
        .toList();
    _planMemory[key] = next;
    await _localStorage?.savePlanItems(key, next);
  }

  Future<PlanItem> createPersonalItem({
    required String userId,
    required String createdBy,
    required String title,
    int quantity = 1,
    String? note,
  }) async {
    final now = DateTime.now();
    final trimmedNote = note?.trim();
    final item = PlanItem(
      id: _uuid.v4(),
      title: title.trim(),
      quantity: quantity < 1 ? 1 : quantity,
      bought: false,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
    );
    await _personalRef(userId).doc(item.id).set(item.toFirestore());
    await _upsertPersonal(userId, item);
    return item;
  }

  Future<void> togglePersonalBought({
    required String userId,
    required String itemId,
    required bool bought,
  }) async {
    final existing = _findPersonal(userId, itemId);
    if (existing == null) throw Exception('Item not found');
    final updated = existing.copyWith(bought: bought, updatedAt: DateTime.now());
    await _personalRef(userId).doc(itemId).update(updated.toFirestore());
    await _upsertPersonal(userId, updated);
  }

  Future<void> deletePersonalItem({
    required String userId,
    required String itemId,
  }) async {
    await _personalRef(userId).doc(itemId).delete();
    final next = getCachedPersonalItems(userId: userId)
        .where((item) => item.id != itemId)
        .toList();
    _personalMemory[userId] = next;
    await _localStorage?.savePersonalItems(userId, next);
  }

  NeedItem? _findNeed({
    required String userId,
    String? groupId,
    required String itemId,
  }) {
    for (final item in getCachedNeedItems(userId: userId, groupId: groupId)) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  PlanItem? _findPlan({
    required String userId,
    String? groupId,
    required String itemId,
  }) {
    for (final item in getCachedPlanItems(userId: userId, groupId: groupId)) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  PlanItem? _findPersonal(String userId, String itemId) {
    for (final item in getCachedPersonalItems(userId: userId)) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  ShopTrip? _findTrip({
    required String userId,
    String? groupId,
    required String tripId,
  }) {
    for (final trip in getCachedTrips(userId: userId, groupId: groupId)) {
      if (trip.id == tripId) return trip;
    }
    return null;
  }

  Future<void> _upsertNeed({
    required String userId,
    String? groupId,
    required NeedItem item,
  }) async {
    final key = _cacheKey(userId: userId, groupId: groupId);
    final next = getCachedNeedItems(userId: userId, groupId: groupId);
    final index = next.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      next[index] = item;
    } else {
      next.insert(0, item);
    }
    _needMemory[key] = next;
    await _localStorage?.saveNeedItems(key, next);
  }

  Future<void> _upsertTrip({
    required String userId,
    String? groupId,
    required ShopTrip trip,
  }) async {
    final key = _cacheKey(userId: userId, groupId: groupId);
    final next = getCachedTrips(userId: userId, groupId: groupId);
    final index = next.indexWhere((entry) => entry.id == trip.id);
    if (index >= 0) {
      next[index] = trip;
    } else {
      next.insert(0, trip);
    }
    _tripMemory[key] = next;
    await _localStorage?.saveTrips(key, next);
  }

  Future<void> _upsertPlan({
    required String userId,
    String? groupId,
    required PlanItem item,
  }) async {
    final key = _cacheKey(userId: userId, groupId: groupId);
    final next = getCachedPlanItems(userId: userId, groupId: groupId);
    final index = next.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      next[index] = item;
    } else {
      next.insert(0, item);
    }
    _planMemory[key] = next;
    await _localStorage?.savePlanItems(key, next);
  }

  Future<void> _upsertPersonal(String userId, PlanItem item) async {
    final next = getCachedPersonalItems(userId: userId);
    final index = next.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      next[index] = item;
    } else {
      next.insert(0, item);
    }
    _personalMemory[userId] = next;
    await _localStorage?.savePersonalItems(userId, next);
  }
}
