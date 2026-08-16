import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_priority.dart';
import 'package:family_tasks/features/tasks/domain/task_recurrence.dart';
import 'package:family_tasks/features/tasks/domain/task_reminder_preset.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/family/presentation/utils/family_onboarding.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  bool get isEditing => taskId != null;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriorityLevel _priority = TaskPriorityLevel.medium;
  TaskStatus _status = TaskStatus.todo;
  DateTime? _deadline;
  TaskReminderPreset _reminderPreset = TaskReminderPreset.none;
  DateTime? _existingReminderAt;
  bool _isGroupTask = false;
  String? _assigneeId;
  TaskRecurrence _recurrence = TaskRecurrence.none;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _populate(Task task) {
    if (_initialized) return;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _priority = task.priority;
    _status = task.status;
    _deadline = task.deadline;
    _existingReminderAt = task.reminderAt;
    _reminderPreset = TaskReminderPreset.none;
    _isGroupTask = task.isGroupTask;
    _assigneeId = task.assigneeId;
    _recurrence = task.recurrence;
    _initialized = true;
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final earliest = _deadline != null && _deadline!.isBefore(now)
        ? DateTime(_deadline!.year, _deadline!.month, _deadline!.day)
        : DateTime(now.year, now.month, now.day).subtract(const Duration(days: 365 * 5));
    var initial = _deadline ?? now.add(const Duration(days: 1));
    if (initial.isBefore(earliest)) initial = earliest;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: earliest,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    final scope = ref.read(taskScopeProvider);
    if (user == null || scope == null) return;

    if (!_isGroupTask && _assigneeId == null) {
      _assigneeId = user.uid;
    }

    if (_reminderPreset != TaskReminderPreset.none) {
      final granted =
          await ref.read(taskNotificationSchedulerProvider).requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission denied. Reminder may not appear.',
            ),
          ),
        );
      }
    }

    final reminderAt = _reminderPreset.resolveFromNow();
    final clearReminder = _reminderPreset == TaskReminderPreset.none;

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(taskRepositoryProvider);
      if (widget.isEditing) {
        final existing = await repository.getTask(
          userId: scope.userId,
          groupId: scope.groupId,
          taskId: widget.taskId!,
        );
        if (existing == null) throw Exception('Task not found');
        if (!existing.canEditFields(user.uid)) {
          throw Exception('Only the creator can edit this task.');
        }

        await repository.updateTask(
          userId: scope.userId,
          groupId: scope.groupId,
          currentUserId: user.uid,
          task: existing.copyWith(
            title: title,
            description: _descriptionController.text.trim(),
            deadline: _deadline,
            clearDeadline: _deadline == null,
            reminderAt: reminderAt,
            clearReminder: clearReminder,
            priority: _priority,
            status: _status,
            recurrence: _recurrence,
          ),
        );
      } else {
        await repository.createTask(
          userId: scope.userId,
          groupId: scope.groupId,
          createdBy: user.uid,
          assigneeId: _isGroupTask ? null : _assigneeId,
          title: title,
          description: _descriptionController.text.trim(),
          deadline: _deadline,
          reminderAt: reminderAt,
          priority: _priority,
          status: _status,
          isGroupTask: _isGroupTask,
          recurrence: _recurrence,
        );
        if (mounted) {
          await showFirstAssignTipIfNeeded(
            context: context,
            ref: ref,
            userId: user.uid,
            assigneeId: _isGroupTask ? null : _assigneeId,
            isGroupTask: _isGroupTask,
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save task: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final taskAsync = ref.watch(taskByIdProvider(widget.taskId!));
      return taskAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit task')),
          body: Center(child: Text('Error: $error')),
        ),
        data: (task) {
          if (task == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit task')),
              body: const Center(child: Text('Task not found')),
            );
          }
          _populate(task);
          return _buildForm(context, canEdit: task.canEditFields(
            ref.watch(authStateProvider).valueOrNull?.uid ?? '',
          ));
        },
      );
    }

    return _buildForm(context, canEdit: true);
  }

  Widget _buildForm(BuildContext context, {required bool canEdit}) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final hasGroup = ref.watch(userProfileProvider).valueOrNull?.hasGroup ?? false;
    final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
    final deadlineLabel = _deadline != null
        ? DateFormat('MMM d, yyyy • HH:mm').format(_deadline!)
        : 'No deadline set';
    final existingReminderLabel = _existingReminderAt != null &&
            _existingReminderAt!.isAfter(DateTime.now())
        ? DateFormat('MMM d, yyyy • HH:mm').format(_existingReminderAt!)
        : null;

    if (_assigneeId == null && user != null && !_isGroupTask) {
      _assigneeId = user.uid;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit task' : 'New task'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            enabled: canEdit,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'What needs to be done?',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            enabled: canEdit,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Add details (optional)',
            ),
          ),
          if (hasGroup) ...[
            const SizedBox(height: 16),
            Text('Task type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Personal')),
                ButtonSegment(value: true, label: Text('Family')),
              ],
              selected: {_isGroupTask},
              onSelectionChanged: canEdit
                  ? (selection) {
                      setState(() => _isGroupTask = selection.first);
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              _isGroupTask
                  ? 'Family tasks are visible to everyone in your family.'
                  : 'Personal tasks are assigned to one person.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
            ),
            if (!_isGroupTask) ...[
              const SizedBox(height: 16),
              DropdownMenu<String>(
                enabled: canEdit,
                initialSelection: _assigneeId,
                label: const Text('Assign to'),
                dropdownMenuEntries: members
                    .map(
                      (member) => DropdownMenuEntry(
                        value: member.userId,
                        label: member.displayName.isNotEmpty
                            ? member.displayName
                            : member.email,
                      ),
                    )
                    .toList(),
                onSelected: (value) => setState(() => _assigneeId = value),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text('Priority', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskPriorityLevel.values.map((level) {
              final selected = _priority == level;
              return ChoiceChip(
                label: Text(level.label),
                selected: selected,
                onSelected: canEdit
                    ? (_) => setState(() => _priority = level)
                    : null,
                selectedColor: level.color.withValues(alpha: 0.25),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Status', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TaskStatus>(
            segments: TaskStatus.values
                .map(
                  (status) => ButtonSegment(
                    value: status,
                    label: Text(status.label),
                    icon: Icon(status.icon, size: 18),
                  ),
                )
                .toList(),
            selected: {_status},
            onSelectionChanged: (selection) {
              setState(() => _status = selection.first);
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Deadline'),
            subtitle: Text(deadlineLabel),
            trailing: IconButton(
              onPressed: canEdit ? _pickDeadline : null,
              icon: const Icon(Icons.calendar_month_rounded),
            ),
          ),
          if (_deadline != null && canEdit)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _deadline = null),
                child: const Text('Clear deadline'),
              ),
            ),
          const SizedBox(height: 16),
          Text('Reminder', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TaskReminderPreset>(
            segments: TaskReminderPreset.values
                .map(
                  (preset) => ButtonSegment(
                    value: preset,
                    label: Text(preset.label),
                    icon: Icon(
                      switch (preset) {
                        TaskReminderPreset.none => Icons.notifications_off_outlined,
                        TaskReminderPreset.inOneHour => Icons.schedule_rounded,
                        TaskReminderPreset.inOneDay => Icons.today_rounded,
                      },
                      size: 18,
                    ),
                  ),
                )
                .toList(),
            selected: {_reminderPreset},
            onSelectionChanged: canEdit
                ? (selection) {
                    setState(() => _reminderPreset = selection.first);
                  }
                : null,
          ),
          if (existingReminderLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              'Current reminder: $existingReminderLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Repeat', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in TaskRecurrence.values)
                ChoiceChip(
                  avatar: Icon(item.formIcon, size: 16),
                  label: Text(item.label),
                  selected: _recurrence == item,
                  onSelected: canEdit
                      ? (selected) {
                          if (selected) {
                            setState(() => _recurrence = item);
                          }
                        }
                      : null,
                ),
            ],
          ),
          if (_recurrence.formHint != null) ...[
            const SizedBox(height: 8),
            Text(
              _recurrence.formHint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEditing ? 'Save changes' : 'Create task'),
          ),
        ),
      ),
    );
  }
}