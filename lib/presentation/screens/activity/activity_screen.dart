import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/workout_providers.dart';
import 'activity_detail_screen.dart';

enum ActivityTimeFilter { all, thisWeek, thisMonth, last3Months }

final _activityTimeFilterProvider =
    StateProvider<ActivityTimeFilter>((_) => ActivityTimeFilter.all);

List<dynamic> _applyTimeFilter(List<dynamic> logs, ActivityTimeFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case ActivityTimeFilter.all:
      return logs;
    case ActivityTimeFilter.thisWeek:
      final start = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(start.year, start.month, start.day);
      return logs.where((l) => l.date.isAfter(startDate)).toList();
    case ActivityTimeFilter.thisMonth:
      return logs
          .where((l) => l.date.month == now.month && l.date.year == now.year)
          .toList();
    case ActivityTimeFilter.last3Months:
      final start = DateTime(now.year, now.month - 3, now.day);
      return logs.where((l) => l.date.isAfter(start)).toList();
  }
}

String _formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '0m';
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String logId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Workout',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: const Text(
          'Are you sure you want to delete this workout? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(workoutRepositoryProvider).deleteWorkoutLog(logId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutLogs = ref.watch(allWorkoutLogsProvider);
    final selectedFilter = ref.watch(_activityTimeFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: workoutLogs.when(
          data: (logs) {
            final completedLogs = logs
                .where((log) => !log.inProgress)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            final filteredLogs = _applyTimeFilter(completedLogs, selectedFilter);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${filteredLogs.length} completed workout${filteredLogs.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ActivityTimeFilter.values.map((filter) {
                              final isSelected = filter == selectedFilter;
                              final label = switch (filter) {
                                ActivityTimeFilter.all => 'All',
                                ActivityTimeFilter.thisWeek => 'This Week',
                                ActivityTimeFilter.thisMonth => 'This Month',
                                ActivityTimeFilter.last3Months => 'Last 3 Months',
                              };
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  onSelected: (_) => ref
                                      .read(_activityTimeFilterProvider.notifier)
                                      .state = filter,
                                  selectedColor: AppColors.primary.withOpacity(0.2),
                                  checkmarkColor: AppColors.primary,
                                  backgroundColor: AppColors.surfaceDark,
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.borderDark,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondaryDark,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filteredLogs.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: filteredLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return _ActivityCard(
                          log: log,
                          onDelete: () =>
                              _confirmDelete(context, ref, log.id),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ActivityDetailScreen(workoutLogId: log.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 24),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load activity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 40,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No workouts completed yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start your first workout!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({required this.log, required this.onDelete, required this.onTap});

  final dynamic log;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(workoutLogExercisesProvider(log.id));
    final dateFormatted = DateFormat('MMM dd, yyyy').format(log.date);
    final plan = ref.watch(workoutPlanProvider(log.workoutPlanId));
    final routineName = plan.when(
      data: (p) => p?.name ?? 'Workout',
      loading: () => 'Loading...',
      error: (_, __) => 'Workout',
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateFormatted · ${DateFormat('EEEE').format(log.date)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondaryDark,
                    size: 20,
                  ),
                  color: AppColors.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderDark),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                    if (value == 'details') onTap();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondaryDark),
                          SizedBox(width: 10),
                          Text('View Details', style: TextStyle(color: AppColors.textPrimaryDark)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stat badges
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatBadge(
                  icon: Icons.timer_outlined,
                  label: _formatDuration(log.duration),
                ),
                exercises.when(
                  data: (exList) => _StatBadge(
                    icon: Icons.fitness_center_rounded,
                    label:
                        '${exList.length} exercise${exList.length == 1 ? '' : 's'}',
                  ),
                  loading: () => const _StatBadge(
                    icon: Icons.fitness_center_rounded,
                    label: '...',
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Exercise list summary
          exercises.when(
            data: (exList) {
              if (exList.isEmpty) return const SizedBox(height: 14);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < exList.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        _ExerciseNameRow(exerciseId: exList[i].exerciseId),
                      ],
                    ],
                  ),
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            error: (_, __) => const SizedBox(height: 14),
          ),
        ],
      ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ExerciseNameRow — resolves exerciseId → name via provider
// ═══════════════════════════════════════════════════════════════════════════
class _ExerciseNameRow extends ConsumerWidget {
  final String exerciseId;
  const _ExerciseNameRow({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseProvider(exerciseId));
    final name = exerciseAsync.valueOrNull?.name ?? exerciseId;
    final displayName = name.length > 40 ? '${name.substring(0, 37)}...' : name;

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            displayName,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
