import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/workout_providers.dart';

String _formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '0m';
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}

String _formatWeight(double weight) {
  return weight == weight.truncateToDouble()
      ? weight.toInt().toString()
      : weight.toStringAsFixed(1);
}

class ActivityDetailScreen extends ConsumerWidget {
  final String workoutLogId;

  const ActivityDetailScreen({super.key, required this.workoutLogId});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
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
      ref.read(workoutRepositoryProvider).deleteWorkoutLog(workoutLogId);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutLog = ref.watch(workoutLogProvider(workoutLogId));
    final exercises = ref.watch(workoutLogExercisesProvider(workoutLogId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Workout Details',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: workoutLog.when(
        data: (log) {
          if (log == null) {
            return const Center(
              child: Text(
                'Workout not found',
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
              ),
            );
          }
          return _DetailBody(
            log: log,
            exercises: exercises,
            onDelete: () => _confirmDelete(context, ref),
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
                const Text(
                  'Failed to load workout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.log,
    required this.exercises,
    required this.onDelete,
  });

  final WorkoutLogData log;
  final AsyncValue<List<WorkoutLogExerciseData>> exercises;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineName = ref.watch(workoutPlanProvider(log.workoutPlanId));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _HeaderCard(log: log, routineName: routineName),
          const SizedBox(height: 20),

          // Exercises section
          exercises.when(
            data: (exList) {
              if (exList.isEmpty) {
                return _buildEmptyExercises();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'EXERCISES (${exList.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
                  ...exList.map(
                    (exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExerciseCard(exercise: exercise),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Failed to load exercises',
                  style: TextStyle(color: AppColors.textSecondaryDark),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Delete button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete Workout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExercises() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 40,
            color: AppColors.textSecondaryDark.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No exercises recorded',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.log, required this.routineName});

  final WorkoutLogData log;
  final AsyncValue<WorkoutPlanData?> routineName;

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('MMM dd, yyyy').format(log.date);
    final dayName = DateFormat('EEEE').format(log.date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Routine name
          routineName.when(
            data: (plan) {
              if (plan == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Date
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondaryDark),
              const SizedBox(width: 8),
              Text(
                '$dateFormatted  ·  $dayName',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _HeaderStat(
                icon: Icons.timer_outlined,
                value: _formatDuration(log.duration),
                label: 'Duration',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 36,
                  width: 1,
                  color: AppColors.borderDark,
                ),
              ),
              const SizedBox(width: 12),
              _HeaderStat(
                icon: Icons.check_circle_outline_rounded,
                value: log.inProgress ? 'In Progress' : 'Completed',
                label: 'Status',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 4,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.exercise});

  final WorkoutLogExerciseData exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseData = ref.watch(exerciseProvider(exercise.exerciseId));
    final setLogs = ref.watch(setLogsProvider(exercise.id));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: exerciseData.when(
                    data: (ex) => Text(
                      ex?.name ?? exercise.exerciseId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    loading: () => Text(
                      exercise.exerciseId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    error: (_, __) => Text(
                      exercise.exerciseId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Set logs table
          setLogs.when(
            data: (sets) {
              if (sets.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'No sets recorded',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                );
              }

              final sortedSets = List<SetLogData>.from(sets)
                ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

              final isDuration = exercise.trackingType.name == 'duration';

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Table header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 40,
                              child: Text(
                                'SET',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                isDuration ? 'DURATION' : 'WEIGHT',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                isDuration ? '' : 'REPS',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: AppColors.borderDark.withOpacity(0.5),
                      ),
                      // Table rows
                      ...sortedSets.asMap().entries.map((entry) {
                        final index = entry.key;
                        final set = entry.value;
                        final isLast = index == sortedSets.length - 1;

                        return _SetRow(
                          setNumber: index + 1,
                          setLog: set,
                          isDuration: isDuration,
                          isLast: isLast,
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Failed to load sets',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.setNumber,
    required this.setLog,
    required this.isDuration,
    required this.isLast,
  });

  final int setNumber;
  final SetLogData setLog;
  final bool isDuration;
  final bool isLast;

  String _formatSetDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min > 0 && sec > 0) return '${min}m ${sec}s';
    if (min > 0) return '${min}m';
    return '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.borderDark.withOpacity(0.3),
                ),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: setLog.isWarmUp
                        ? AppColors.warning.withOpacity(0.15)
                        : AppColors.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    setLog.isWarmUp ? 'W' : '$setNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: setLog.isWarmUp
                          ? AppColors.warning
                          : AppColors.textPrimaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              isDuration
                  ? (setLog.exerciseDuration != null
                      ? _formatSetDuration(setLog.exerciseDuration!)
                      : '—')
                  : (setLog.weight != null
                      ? '${_formatWeight(setLog.weight!)} kg'
                      : '— kg'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              isDuration ? '' : (setLog.reps?.toString() ?? '—'),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
