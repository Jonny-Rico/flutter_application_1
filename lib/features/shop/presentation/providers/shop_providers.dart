import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/shop/data/shop_local_storage.dart';
import 'package:family_tasks/features/shop/data/shop_repository.dart';
import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';
import 'package:family_tasks/features/shop/domain/shop_trip.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final shopLocalStorageProvider = Provider<ShopLocalStorage>((ref) {
  final box = Hive.box<dynamic>(TaskLocalStorage.boxName);
  return ShopLocalStorage(box);
});

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(localStorage: ref.watch(shopLocalStorageProvider));
});

final needItemsProvider = StreamProvider<List<NeedItem>>((ref) {
  final scope = ref.watch(taskScopeProvider);
  if (scope == null) return Stream.value(const []);
  return ref.watch(shopRepositoryProvider).watchNeedItems(
        userId: scope.userId,
        groupId: scope.groupId,
      );
});

final shopTripsProvider = StreamProvider<List<ShopTrip>>((ref) {
  final scope = ref.watch(taskScopeProvider);
  if (scope == null) return Stream.value(const []);
  return ref.watch(shopRepositoryProvider).watchTrips(
        userId: scope.userId,
        groupId: scope.groupId,
      );
});

final planItemsProvider = StreamProvider<List<PlanItem>>((ref) {
  final scope = ref.watch(taskScopeProvider);
  if (scope == null) return Stream.value(const []);
  return ref.watch(shopRepositoryProvider).watchPlanItems(
        userId: scope.userId,
        groupId: scope.groupId,
      );
});

final personalItemsProvider = StreamProvider<List<PlanItem>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(shopRepositoryProvider).watchPersonalItems(userId: user.uid);
});

final activeTripProvider = Provider<ShopTrip?>((ref) {
  final trips = ref.watch(shopTripsProvider).valueOrNull ?? const [];
  for (final trip in trips) {
    if (trip.isActive) return trip;
  }
  return null;
});

final recentTripsProvider = Provider<List<ShopTrip>>((ref) {
  final trips = List<ShopTrip>.from(
    ref.watch(shopTripsProvider).valueOrNull ?? const [],
  )..removeWhere((trip) => trip.isActive);
  trips.sort((a, b) {
    final aDate = a.completedAt ?? a.updatedAt;
    final bDate = b.completedAt ?? b.updatedAt;
    return bDate.compareTo(aDate);
  });
  if (trips.length <= 5) return trips;
  return trips.take(5).toList();
});

final needToBuyCountProvider = Provider<int>((ref) {
  final items = ref.watch(needItemsProvider).valueOrNull ?? const [];
  return items.where((item) => !item.bought).length;
});

final shopTripByIdProvider = Provider.family<ShopTrip?, String>((ref, id) {
  final trips = ref.watch(shopTripsProvider).valueOrNull ?? const [];
  for (final trip in trips) {
    if (trip.id == id) return trip;
  }
  return null;
});

final needSearchQueryProvider = StateProvider<String>((ref) => '');

final planSearchQueryProvider = StateProvider<String>((ref) => '');

final personalSearchQueryProvider = StateProvider<String>((ref) => '');
