abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const tasks = '/tasks';
  static const taskCreate = '/tasks/create';
  static const family = '/family';
  static const familyInvite = '/family/invite';
  static const dashboard = '/dashboard';
  static const settings = '/settings';
  static const help = '/settings/help';

  static String taskDetail(String id) => '/tasks/$id';
  static String taskEdit(String id) => '/tasks/$id/edit';
}