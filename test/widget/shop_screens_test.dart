import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/shop/domain/shop_category.dart';
import 'package:family_tasks/features/shop/domain/shop_trip_status.dart';
import 'package:family_tasks/features/shop/presentation/providers/shop_providers.dart';
import 'package:family_tasks/features/shop/presentation/screens/need_list_screen.dart';
import 'package:family_tasks/features/shop/presentation/screens/personal_list_screen.dart';
import 'package:family_tasks/features/shop/presentation/screens/plans_list_screen.dart';
import 'package:family_tasks/features/shop/presentation/screens/shop_hub_screen.dart';
import 'package:family_tasks/features/shop/presentation/screens/shop_trip_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth_user.dart';
import '../helpers/fake_shop_repository.dart';
import '../helpers/shop_fixtures.dart';
import '../helpers/test_overrides.dart';

List<Override> _shopOverrides(FakeShopRepository repo) {
  return [
    authStateProvider.overrideWith(
      (ref) => Stream.value(FakeAuthUser(uid: testProfile.userId)),
    ),
    userProfileProvider.overrideWith((ref) => Stream.value(testProfile)),
    groupMembersProvider.overrideWith((ref) => Stream.value([])),
    taskScopeProvider.overrideWith(
      (ref) => TaskScope(userId: testProfile.userId, groupId: testProfile.groupId),
    ),
    shopRepositoryProvider.overrideWithValue(repo),
    needItemsProvider.overrideWith(
      (ref) => repo.watchNeedItems(userId: testProfile.userId),
    ),
    shopTripsProvider.overrideWith(
      (ref) => repo.watchTrips(userId: testProfile.userId),
    ),
    planItemsProvider.overrideWith(
      (ref) => repo.watchPlanItems(userId: testProfile.userId),
    ),
    personalItemsProvider.overrideWith(
      (ref) => repo.watchPersonalItems(userId: testProfile.userId),
    ),
  ];
}

Widget _shopApp({
  required List<Override> overrides,
  String location = '/shop',
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.shop,
        builder: (context, state) => const ShopHubScreen(),
        routes: [
          GoRoute(
            path: 'need',
            builder: (context, state) => const NeedListScreen(),
          ),
          GoRoute(
            path: 'plans',
            builder: (context, state) => const PlansListScreen(),
          ),
          GoRoute(
            path: 'personal',
            builder: (context, state) => const PersonalListScreen(),
          ),
          GoRoute(
            path: 'trip/:id',
            builder: (context, state) => ShopTripScreen(
              tripId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() => AppHaptics.enabled = false);
  tearDown(() => AppHaptics.enabled = true);

  test('createPersonalItem does not write to Plans', () async {
    final repo = FakeShopRepository(
      planItems: [buildPlanItem(id: 'sofa', title: 'Sofa')],
    );
    await repo.createPersonalItem(
      userId: 'user-a',
      createdBy: 'user-a',
      title: 'Secret book',
    );
    expect(repo.personalItems.single.title, 'Secret book');
    expect(repo.planItems.single.title, 'Sofa');
  });

  testWidgets('hub shows Need count and empty trip', (tester) async {
    final repo = FakeShopRepository(
      needItems: [
        buildNeedItem(id: 'm', title: 'Milk'),
        buildNeedItem(id: 's', title: 'Soap', category: ShopCategory.household),
      ],
    );
    await tester.pumpWidget(_shopApp(overrides: _shopOverrides(repo)));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('account-menu')), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('NEED'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('No trip yet'), findsOneWidget);
    expect(find.text('PLANS'), findsOneWidget);
    expect(find.text('Nothing planned'), findsOneWidget);
    expect(find.text('PERSONAL'), findsOneWidget);
    expect(find.text('Just you — not the family'), findsOneWidget);
  });

  testWidgets('hub shows live trip and recent history', (tester) async {
    final repo = FakeShopRepository(
      needItems: [buildNeedItem()],
      trips: [
        buildTrip(id: 'live', items: [buildTripItem(), buildTripItem(id: 'b')]),
        buildTrip(
          id: 'old',
          storeName: 'DM',
          status: ShopTripStatus.completed,
          items: [buildTripItem(bought: true)],
        ),
      ],
    );
    await tester.pumpWidget(_shopApp(overrides: _shopOverrides(repo)));
    await tester.pump();
    await tester.pump();

    expect(find.text('QA User A is shopping'), findsOneWidget);
    expect(find.text('RECENT TRIPS'), findsOneWidget);
    expect(find.text('DM'), findsOneWidget);
  });

  testWidgets('Need list toggles bought', (tester) async {
    final repo = FakeShopRepository(
      needItems: [buildNeedItem(id: 'm', title: 'Milk')],
    );
    await tester.pumpWidget(
      _shopApp(overrides: _shopOverrides(repo), location: '/shop/need'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('1 to buy · personal list'), findsOneWidget);

    await tester.tap(find.text('Milk'));
    await tester.pump();
    await tester.pump();

    expect(repo.needItems.single.bought, isTrue);
    expect(find.text('bought'), findsOneWidget);
  });

  testWidgets('complete trip marks non-staple bought and keeps staple', (
    tester,
  ) async {
    final milk = buildNeedItem(id: 'milk', title: 'Milk', isStaple: true);
    final soap = buildNeedItem(
      id: 'soap',
      title: 'Soap',
      category: ShopCategory.household,
    );
    final repo = FakeShopRepository(
      needItems: [milk, soap],
      trips: [
        buildTrip(
          items: [
            buildTripItem(id: 'milk', title: 'Milk', bought: true, isStaple: true),
            buildTripItem(id: 'soap', title: 'Soap', bought: true),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      _shopApp(overrides: _shopOverrides(repo), location: '/shop/trip/trip-1'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Lidl'), findsOneWidget);
    await tester.tap(find.text('Complete trip'));
    await tester.pump();
    await tester.pump();

    expect(
      repo.needItems.firstWhere((item) => item.id == 'milk').bought,
      isFalse,
    );
    expect(
      repo.needItems.firstWhere((item) => item.id == 'soap').bought,
      isTrue,
    );
    expect(repo.trips.single.status, ShopTripStatus.completed);
  });

  testWidgets('Plans list toggles bought', (tester) async {
    final repo = FakeShopRepository(
      planItems: [buildPlanItem(id: 'sofa', title: 'Sofa', note: 'IKEA')],
    );
    await tester.pumpWidget(
      _shopApp(overrides: _shopOverrides(repo), location: '/shop/plans'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Sofa'), findsOneWidget);
    expect(find.text('IKEA'), findsOneWidget);
    expect(find.text('1 planned · personal list'), findsOneWidget);

    await tester.tap(find.text('Sofa'));
    await tester.pump();
    await tester.pump();

    expect(repo.planItems.single.bought, isTrue);
    expect(find.text('bought'), findsOneWidget);
  });

  testWidgets('Need Clear all removes every item including Regular', (
    tester,
  ) async {
    final repo = FakeShopRepository(
      needItems: [
        buildNeedItem(id: 'm', title: 'Milk', isStaple: true),
        buildNeedItem(id: 's', title: 'Soap', bought: true),
      ],
    );
    await tester.pumpWidget(
      _shopApp(overrides: _shopOverrides(repo), location: '/shop/need'),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.pump();
    await tester.pump();

    expect(repo.needItems, isEmpty);
    expect(find.text('Need is empty'), findsOneWidget);
  });

  testWidgets('Personal list is private and toggles bought', (tester) async {
    final repo = FakeShopRepository(
      personalItems: [buildPlanItem(id: 'book', title: 'A book')],
    );
    await tester.pumpWidget(
      _shopApp(overrides: _shopOverrides(repo), location: '/shop/personal'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('A book'), findsOneWidget);
    expect(find.text('1 to buy · just you'), findsOneWidget);

    await tester.tap(find.text('A book'));
    await tester.pump();
    await tester.pump();

    expect(repo.personalItems.single.bought, isTrue);
    expect(repo.planItems, isEmpty);
  });
}
