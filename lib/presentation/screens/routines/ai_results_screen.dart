import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/preset_pack.dart';
import '../../../data/services/preset_pack_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/workout_providers.dart';

class AiResultsScreen extends ConsumerWidget {
  final List<PresetRoutine> routines;
  final String? usedPrompt;

  const AiResultsScreen({
    super.key,
    required this.routines,
    this.usedPrompt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 10),
            Text(
              'Your AI Workout Plan',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${routines.length} routine${routines.length > 1 ? 's' : ''} generated',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (usedPrompt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '"$usedPrompt"',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Routine cards
                  ...routines.asMap().entries.map((entry) =>
                      _RoutineCard(
                        index: entry.key,
                        routine: entry.value,
                      )),
                ],
              ),
            ),
          ),
          // Bottom action bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(top: BorderSide(color: AppColors.borderDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryDark,
                      side: const BorderSide(color: AppColors.borderDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _addAllRoutines(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Add All (${routines.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAllRoutines(BuildContext context, WidgetRef ref) async {
    final packService = PresetPackService(
      ref.read(workoutRepositoryProvider),
      ref.read(exerciseRepositoryProvider),
    );

    int added = 0;
    for (final routine in routines) {
      final success = await packService.addSingleRoutine(routine);
      if (success) added++;
    }

    ref.invalidate(allWorkoutPlansProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added > 0
            ? '$added routine${added > 1 ? 's' : ''} added to your workouts!'
            : 'All routines already exist.'),
        backgroundColor: added > 0 ? AppColors.primary : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (added > 0) {
      // Pop back to routines screen (pop results + pop AI generate)
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }
}

class _RoutineCard extends ConsumerWidget {
  final int index;
  final PresetRoutine routine;

  const _RoutineCard({required this.index, required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSets = routine.exercises.fold(0, (sum, e) => sum + e.sets);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        if (routine.notes != null)
                          Text(
                            routine.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMutedDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _addSingle(context, ref),
                    icon: Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primary, size: 24),
                    tooltip: 'Add this routine',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  _buildInfoTag(Icons.fitness_center_rounded,
                      '${routine.exercises.length} exercises'),
                  const SizedBox(width: 12),
                  _buildInfoTag(Icons.repeat_rounded, '$totalSets sets'),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.borderDark.withOpacity(0.5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: routine.exercises.map((ex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.textMutedDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ex.exerciseName,
                            style: const TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          ex.durationSeconds != null
                              ? '${ex.sets} × ${ex.durationSeconds}s'
                              : '${ex.sets} × ${ex.reps}',
                          style: const TextStyle(
                            color: AppColors.textMutedDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSingle(BuildContext context, WidgetRef ref) async {
    final packService = PresetPackService(
      ref.read(workoutRepositoryProvider),
      ref.read(exerciseRepositoryProvider),
    );

    final success = await packService.addSingleRoutine(routine);
    ref.invalidate(allWorkoutPlansProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '"${routine.name}" added!'
            : '"${routine.name}" already exists.'),
        backgroundColor: success ? AppColors.primary : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMutedDark),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMutedDark,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
