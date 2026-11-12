import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/trip_item.dart';

/// How a finished trip writes back to the standing Need list.
NeedItem applyTripPurchaseToNeed({
  required NeedItem need,
  required TripItem tripItem,
}) {
  if (!tripItem.bought) return need;
  if (need.isStaple) {
    return need.copyWith(bought: false);
  }
  return need.copyWith(bought: true);
}
