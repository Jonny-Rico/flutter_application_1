import 'package:family_tasks/features/shop/domain/shop_completion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/shop_fixtures.dart';

void main() {
  test('bought staple stays on Need as to-buy', () {
    final need = buildNeedItem(isStaple: true, bought: false);
    final tripItem = buildTripItem(bought: true, isStaple: true);
    final next = applyTripPurchaseToNeed(need: need, tripItem: tripItem);
    expect(next.bought, isFalse);
  });

  test('bought non-staple is marked bought on Need', () {
    final need = buildNeedItem(id: 'soap', title: 'Soap', isStaple: false);
    final tripItem = buildTripItem(id: 'soap', bought: true, isStaple: false);
    final next = applyTripPurchaseToNeed(need: need, tripItem: tripItem);
    expect(next.bought, isTrue);
  });

  test('unbought trip item does not change Need', () {
    final need = buildNeedItem();
    final tripItem = buildTripItem(bought: false);
    final next = applyTripPurchaseToNeed(need: need, tripItem: tripItem);
    expect(next.bought, isFalse);
    expect(identical(next, need) || next.bought == need.bought, isTrue);
  });
}
