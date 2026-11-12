abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const tasks = '/tasks';
  static const taskCreate = '/tasks/create';
  static const family = '/family';
  static const familyInvite = '/family/invite';
  static const shop = '/shop';
  static const shopNeed = '/shop/need';
  static const shopPlans = '/shop/plans';
  static const shopPersonal = '/shop/personal';
  static const dashboard = '/dashboard';
  static const notes = '/notes';
  static const settings = '/settings';
  static const help = '/settings/help';

  static String noteDetail(String id) => '/notes/$id';

  static String shopTrip(String id) => '/shop/trip/$id';

  static String taskDetail(String id) => '/tasks/$id';
  static String taskEdit(String id) => '/tasks/$id/edit';
}