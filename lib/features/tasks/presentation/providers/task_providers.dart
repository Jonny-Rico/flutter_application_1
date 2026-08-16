import 'package:family_tasks/core/bootstrap.dart';
import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/core/notifications/task_notification_service.dart';
import 'package:family_tasks/core/router/app_router.dart';
import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:family_tasks/features/tasks/data/task_new_assignment_notification_storage.dart';
import 'package:family_tasks/features/tasks/data/task_new_assignment_notifier.dart';
import 'package:family_tasks/features/tasks/data/task_notification_scheduler.dart';
import 'package:family_tasks/features/tasks/data/task_repository.dart';
import 'package:family_tasks/features/tasks/data/task_ui_preferences_storage.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_list_metrics.dart';
import 'package:family_tasks/features/tasks/domain/task_sort.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/domain/task_view_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

export 'package:family_tasks/features/tasks/domain/task_list_metrics.dart';
export 'package:family_tasks/features/tasks/domain/task_view_filter.dart';

final taskLocalStorageProvider = Provider<TaskLocalStorage>((ref) {
  final box = Hive.box<dynamic>(TaskLocalStorage.boxName);
  return TaskLocalStorage(box);
});

final taskUiPreferencesStorageProvider =
    Provider<TaskUiPreferencesStorage>((ref) {
  final box = Hive.box<dynamic>(TaskLocalStorage.boxName);
  return TaskUiPreferencesStorage(box);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    localStorage: ref.watch(taskLocalStorageProvider),
  );
});

final taskNotificationServiceProvider =
    Provider<TaskNotificationService>((ref) => taskNotificationService);

final taskNotificationSchedulerProvider =
    Provider<TaskNotificationScheduler>((ref) {
  return TaskNotificationScheduler(ref.watch(taskNotificationServiceProvider));
});

final taskNewAssignmentNotificationStorageProvider =
    Provider<TaskNewAssignmentNotificationStorage>((ref) {
  final box = Hive.box<dynamic>(TaskLocalStorage.boxName);
  return TaskNewAssignmentNotificationStorage(box);
});

final taskNewAssignmentNotifierProvider =
    Provider<TaskNewAssignmentNotifier>((ref) {
  return TaskNewAssignmentNotifier(
    notificationService: ref.watch(taskNotificationServiceProvider),
    storage: ref.watch(taskNewAssignmentNotificationStorageProvider),
  );
});

final taskViewFilterProvider =
    StateProvider<TaskViewFilter>((ref) => TaskViewFilter.assignedToMe);

final taskStatusFilterProvider =
    StateProvider<TaskStatus?>((ref) => TaskStatus.todo);

final taskPersistFiltersProvider = StateProvider<bool>((ref) => true);

final taskNotifyNewTasksProvider = StateProvider<bool>((ref) => true);

/// Vibration / haptic on Done and Delete. Default on; Settings toggle.
final appHapticsEnabledProvider = StateProvider<bool>((ref) => true);

/// Set when opening Tasks from Dashboard Overview (My / Family).
final taskDashboardScopeProvider =
    StateProvider<TaskDashboardScope>((ref) => TaskDashboardScope.none);

/// Open-only / overdue-only (Dashboard Overview tiles).
final taskMetricFilterProvider =
    StateProvider<TaskMetricFilter>((ref) => TaskMetricFilter.none);

/// Temporary list opened from Dashboard; cleared when user changes Tasks filters.
final taskDashboardNavActiveProvider = StateProvider<bool>((ref) => false);

/// Client-side search query (title + description).
final taskSearchQueryProvider = StateProvider<String>((ref) => '');

final _taskByIdServerProvider = FutureProvider.family<Task?, String>((ref, taskId) async {
  final scope = ref.watch(taskScopeProvider);
  if (scope == null) return null;

  return ref.watch(taskRepositoryProvider).getTask(
        userId: scope.userId,
        groupId: scope.groupId,
        taskId: taskId,
        fromServer: true,
      );
});

/// Loads and persists per-user task filters across app restarts and relogin.
final taskFiltersPersistenceProvider = Provider<void>((ref) {
  final storage = ref.watch(taskUiPreferencesStorageProvider);
  var isRestoring = false;

  TaskViewFilter fallbackViewFilter() {
    return ref.read(taskPersistFiltersProvider)
        ? TaskViewFilter.assignedToMe
        : TaskViewFilter.all;
  }

  void applyViewFilter(TaskViewFilter filter) {
    final hasGroup = ref.read(userProfileProvider).valueOrNull?.hasGroup ?? false;
    final resolved = !hasGroup && filter == TaskViewFilter.group
        ? fallbackViewFilter()
        : filter;
    ref.read(taskViewFilterProvider.notifier).state = resolved;
  }

  void applyPreferences(TaskUiPreferences preferences) {
    isRestoring = true;
    ref.read(taskPersistFiltersProvider.notifier).state =
        preferences.persistFilters;
    ref.read(taskNotifyNewTasksProvider.notifier).state =
        preferences.notifyNewTasks;
    ref.read(appHapticsEnabledProvider.notifier).state =
        preferences.hapticsEnabled;
    AppHaptics.enabled = preferences.hapticsEnabled;

    if (!preferences.persistFilters) {
      ref.read(taskViewFilterProvider.notifier).state = TaskViewFilter.all;
      ref.read(taskStatusFilterProvider.notifier).state = null;
    } else {
      applyViewFilter(preferences.viewFilter);
      ref.read(taskStatusFilterProvider.notifier).state =
          preferences.statusFilter;
    }
    isRestoring = false;
  }

  void persistForCurrentUser() {
    if (isRestoring) return;
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;

    final persistFilters = ref.read(taskPersistFiltersProvider);
    storage.save(
      userId,
      TaskUiPreferences(
        persistFilters: persistFilters,
        viewFilter: persistFilters
            ? ref.read(taskViewFilterProvider)
            : TaskUiPreferences.loginDefaults.viewFilter,
        statusFilter: persistFilters
            ? ref.read(taskStatusFilterProvider)
            : TaskUiPreferences.loginDefaults.statusFilter,
        notifyNewTasks: ref.read(taskNotifyNewTasksProvider),
        hapticsEnabled: ref.read(appHapticsEnabledProvider),
      ),
    );
  }

  ref.listen(authStateProvider, (previous, next) {
    final userId = next.valueOrNull?.uid;
    if (userId == null) return;
    applyPreferences(storage.load(userId));
  }, fireImmediately: true);

  ref.listen(userProfileProvider, (previous, next) {
    if (isRestoring) return;
    final hasGroup = next.valueOrNull?.hasGroup ?? false;
    if (hasGroup) return;
    if (ref.read(taskViewFilterProvider) != TaskViewFilter.group) return;
    ref.read(taskViewFilterProvider.notifier).state = fallbackViewFilter();
  });

  ref.listen(taskPersistFiltersProvider, (_, _) => persistForCurrentUser());
  ref.listen(taskViewFilterProvider, (_, _) => persistForCurrentUser());
  ref.listen(taskStatusFilterProvider, (_, _) => persistForCurrentUser());
  ref.listen(taskNotifyNewTasksProvider, (_, _) => persistForCurrentUser());
  ref.listen(appHapticsEnabledProvider, (_, next) {
    AppHaptics.enabled = next;
    persistForCurrentUser();
  });
});

final tasksProvider = StreamProvider<List<Task>>((ref) async* {
  final scope = ref.watch(taskScopeProvider);
  if (scope == null) {
    yield [];
    return;
  }

  final repository = ref.watch(taskRepositoryProvider);
  yield repository.getCachedTasks(
    userId: scope.userId,
    groupId: scope.groupId,
  );

  yield* repository.watchTasks(
    userId: scope.userId,
    groupId: scope.groupId,
  );
});

/// Shows a local notification when a new personal or group task appears.
final taskNewAssignmentNotificationProvider = Provider<void>((ref) {
  final notifier = ref.watch(taskNewAssignmentNotifierProvider);
  var emissionCount = 0;
  String? trackedUserId;
  String? trackedScopeKey;

  ref.listen(authStateProvider, (previous, next) {
    final previousId = previous?.valueOrNull?.uid;
    final nextId = next.valueOrNull?.uid;
    if (previousId != nextId) {
      emissionCount = 0;
      trackedUserId = null;
      trackedScopeKey = null;
    }
  });

  ref.listen(tasksProvider, (previous, next) {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    final scope = ref.read(taskScopeProvider);
    if (userId == null || scope == null) return;

    final tasks = next.valueOrNull;
    if (tasks == null) return;

    final scopeKey = TaskNewAssignmentNotifier.scopeKey(groupId: scope.groupId);

    if (trackedUserId != userId) {
      emissionCount = 0;
      trackedUserId = userId;
      trackedScopeKey = null;
    }

    if (trackedScopeKey != scopeKey) {
      emissionCount = 0;
      trackedScopeKey = scopeKey;
    }

    emissionCount++;
    notifier.processTasks(
      userId: userId,
      scopeKey: scopeKey,
      tasks: tasks,
      emissionCount: emissionCount,
      notifyEnabled: ref.read(taskNotifyNewTasksProvider),
    );
  }, fireImmediately: true);
});

/// Opens task detail when the user taps a local notification.
final notificationNavigationProvider = Provider<void>((ref) {
  final service = ref.watch(taskNotificationServiceProvider);

  void openTask(String taskId) {
    if (taskId.isEmpty) return;

    if (ref.read(authStateProvider).valueOrNull == null) {
      service.queuePendingTaskId(taskId);
      return;
    }

    ref.read(appRouterProvider).push(AppRoutes.taskDetail(taskId));
  }

  service.onNotificationTap = openTask;

  final launchTaskId = service.consumePendingLaunchTaskId();
  if (launchTaskId != null) {
    Future.microtask(() => openTask(launchTaskId));
  }

  ref.listen(authStateProvider, (previous, next) {
    if (next.valueOrNull == null) return;
    final pending = service.consumePendingLaunchTaskId();
    if (pending != null) {
      Future.microtask(() => openTask(pending));
    }
  });

  ref.onDispose(() {
    if (identical(service.onNotificationTap, openTask)) {
      service.onNotificationTap = null;
    }
  });
});

/// Keeps local notification schedules in sync with the current task list.
final taskReminderSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(taskNotificationSchedulerProvider);

  ref.listen(tasksProvider, (previous, next) {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;

    final tasks = next.valueOrNull;
    if (tasks == null) return;

    scheduler.syncTasksForUser(tasks: tasks, userId: userId);
  }, fireImmediately: true);
});

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final viewFilter = ref.watch(taskViewFilterProvider);
  final statusFilter = ref.watch(taskStatusFilterProvider);
  final dashboardScope = ref.watch(taskDashboardScopeProvider);
  final metricFilter = ref.watch(taskMetricFilterProvider);
  final searchQuery = ref.watch(taskSearchQueryProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;

  return tasksAsync.whenData((tasks) {
    var result = tasks;

    switch (dashboardScope) {
      case TaskDashboardScope.my:
        result = result
            .where(
              (task) =>
                  !task.isGroupTask &&
                  (task.assigneeId == userId || task.createdBy == userId),
            )
            .toList();
      case TaskDashboardScope.family:
        result = result.where((task) => task.isGroupTask).toList();
      case TaskDashboardScope.none:
        result = switch (viewFilter) {
          TaskViewFilter.all => result,
          TaskViewFilter.assignedToMe => result
              .where((task) => !task.isGroupTask && task.assigneeId == userId)
              .toList(),
          TaskViewFilter.assignedByMe => result
              .where(
                (task) =>
                    !task.isGroupTask &&
                    task.createdBy == userId &&
                    task.assigneeId != userId,
              )
              .toList(),
          TaskViewFilter.group =>
            result.where((task) => task.isGroupTask).toList(),
        };
    }

    switch (metricFilter) {
      case TaskMetricFilter.openOnly:
        result =
            result.where((task) => task.status != TaskStatus.done).toList();
      case TaskMetricFilter.overdueOnly:
        result = result.where((task) => task.isOverdue).toList();
      case TaskMetricFilter.none:
        if (statusFilter != null) {
          result =
              result.where((task) => task.status == statusFilter).toList();
        }
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result
          .where(
            (task) =>
                task.title.toLowerCase().contains(query) ||
                task.description.toLowerCase().contains(query),
          )
          .toList();
    }

    return sortTasksDefault(result);
  });
});

final taskByIdProvider = Provider.family<AsyncValue<Task?>, String>((ref, taskId) {
  final tasksAsync = ref.watch(tasksProvider);

  return tasksAsync.when(
    data: (tasks) {
      for (final task in tasks) {
        if (task.id == taskId) return AsyncValue.data(task);
      }
      return ref.watch(_taskByIdServerProvider(taskId));
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});