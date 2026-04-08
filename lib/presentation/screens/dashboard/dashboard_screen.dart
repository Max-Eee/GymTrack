import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/enums.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/workout_providers.dart';
import '../../providers/user_providers.dart';
import '../../providers/nutrition_providers.dart';
import '../../../data/database/app_database.dart';

// ---------------------------------------------------------------------------
// Dashboard Screen - matches the GymTrack app design
// ---------------------------------------------------------------------------

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final weekDateRange = DateRange(sevenDaysAgo, DateTime(today.year, today.month, today.day, 23, 59, 59));
    final mondayOfWeek = today.subtract(Duration(days: now.weekday - 1));

    final weeklyWorkouts = ref.watch(workoutCountProvider(weekDateRange));
    final weeklyPRs = ref.watch(weeklyPRCountProvider(mondayOfWeek));
    final workoutLogs = ref.watch(allWorkoutLogsProvider);
    final goals = ref.watch(allGoalsProvider);
    final personalBests = ref.watch(allPersonalBestsProvider);
    final workoutPlans = ref.watch(allWorkoutPlansProvider);
    final allExercises = ref.watch(allExercisesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceDark,
          onRefresh: () async {
            ref.invalidate(workoutCountProvider(weekDateRange));
            ref.invalidate(weeklyPRCountProvider(mondayOfWeek));
            ref.invalidate(allWorkoutLogsProvider);
            ref.invalidate(allGoalsProvider);
            ref.invalidate(allPersonalBestsProvider);
            ref.invalidate(allWorkoutPlansProvider);
            ref.invalidate(allExercisesProvider);
            ref.invalidate(totalVolumeProvider(weekDateRange));
            ref.invalidate(weeklyMuscleActivityProvider(weekDateRange));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page heading ──────────────────────────────────
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Stat cards (2×2 grid) ─────────────────────────
                _buildStatCards(
                  weeklyWorkouts: weeklyWorkouts,
                  weeklyPRs: weeklyPRs,
                  workoutLogs: workoutLogs,
                  ref: ref,
                ),
                const SizedBox(height: 24),

                // ── Nutrition Summary ──────────────────────────────
                _buildSectionHeading('Today\'s Nutrition'),
                const SizedBox(height: 12),
                _buildNutritionSummary(ref),
                const SizedBox(height: 24),

                // ── Muscle Activity Heat Map ──────────────────────
                _buildSectionHeading('Muscle Activity'),
                const SizedBox(height: 12),
                _MuscleHeatMap(
                  muscleData: ref.watch(weeklyMuscleActivityProvider(weekDateRange)),
                ),
                const SizedBox(height: 24),

                // ── Goals section ─────────────────────────────────
                _buildSectionHeading('Goals'),
                const SizedBox(height: 12),
                _buildGoals(
                  context: context,
                  goals: goals,
                  personalBests: personalBests,
                  allExercises: allExercises,
                ),
                const SizedBox(height: 24),

                // ── Recent activity ───────────────────────────────
                _buildSectionHeading('Recent Activity'),
                const SizedBox(height: 12),
                _buildRecentActivity(
                  workoutLogs: workoutLogs,
                  workoutPlans: workoutPlans,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section heading ─────────────────────────────────────────────────────
  Widget _buildSectionHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryDark,
      ),
    );
  }

  // ── Stat cards ──────────────────────────────────────────────────────────
  Widget _buildStatCards({
    required AsyncValue<int> weeklyWorkouts,
    required AsyncValue<int> weeklyPRs,
    required AsyncValue<List<WorkoutLogData>> workoutLogs,
    required WidgetRef ref,
  }) {
    // Derive avg workout time & daily streak from workout logs
    final avgTime = workoutLogs.whenData((logs) {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final recentCompleted = logs.where((l) =>
          !l.inProgress && l.date.isAfter(sevenDaysAgo)).toList();
      if (recentCompleted.isEmpty) return 0;
      final totalSeconds =
          recentCompleted.fold<int>(0, (sum, l) => sum + l.duration);
      return (totalSeconds / recentCompleted.length / 60).round();
    });

    final streak = workoutLogs.whenData((logs) => _calculateStreak(logs));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today_rounded,
                value: weeklyWorkouts,
                label: 'WEEKLY WORKOUTS',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.hourglass_bottom_rounded,
                value: avgTime,
                label: 'AVG WORKOUT TIME',
                suffix: 'min',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                value: streak,
                label: 'DAILY STREAK',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_rounded,
                value: weeklyPRs,
                label: 'WEEKLY PBS',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Nutrition Summary ───────────────────────────────────────────────────
  Widget _buildNutritionSummary(WidgetRef ref) {
    final todayLogs = ref.watch(todayFoodLogsProvider);

    return todayLogs.when(
      data: (logs) {
        final totalCalories = logs.fold(0.0, (sum, l) => sum + l.calories);
        final totalProtein = logs.fold(0.0, (sum, l) => sum + l.proteinG);
        final totalCarbs = logs.fold(0.0, (sum, l) => sum + l.carbsG);
        final totalFat = logs.fold(0.0, (sum, l) => sum + l.fatG);

        if (logs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant_outlined, color: AppColors.textMutedDark.withOpacity(0.5), size: 40),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No meals logged today',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track your nutrition to see summary',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMutedDark, size: 16),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () => ref.read(currentTabProvider.notifier).state = 3, // Navigate to Nutrition tab
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Calories',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${totalCalories.toStringAsFixed(0)} kcal',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMutedDark, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _NutritionMacro(
                        label: 'Protein',
                        value: totalProtein,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NutritionMacro(
                        label: 'Carbs',
                        value: totalCarbs,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NutritionMacro(
                        label: 'Fat',
                        value: totalFat,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _ShimmerCard(height: 140),
      error: (_, __) => const _ErrorCard(message: 'Could not load nutrition data', onRetry: null),
    );
  }


  // ── Goals section ───────────────────────────────────────────────────────
  Widget _buildGoals({
    required BuildContext context,
    required AsyncValue<List<UserGoalData>> goals,
    required AsyncValue<List<UserExercisePBData>> personalBests,
    required AsyncValue<List<ExerciseData>> allExercises,
  }) {
    return goals.when(
      data: (goalList) {
        final exerciseMap = allExercises.valueOrNull;
        final pbList = personalBests.valueOrNull;

        if (goalList.isEmpty) {
          return Column(
            children: [
              const _EmptyState(
                icon: Icons.flag_rounded,
                message: 'No goals set yet',
                subtitle: 'Tap below to set your first goal',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _AddGoalCard(
                  onTap: () => _showAddGoalSheet(context),
                ),
              ),
            ],
          );
        }

        final displayGoals = goalList.take(4).toList();
        final nameMap = <String, String>{};
        if (exerciseMap != null) {
          for (final ex in exerciseMap) {
            nameMap[ex.id] = ex.name;
          }
        }
        final pbMap = <String, UserExercisePBData>{};
        if (pbList != null) {
          for (final pb in pbList) {
            pbMap[pb.exerciseId] = pb;
          }
        }

        final cards = <Widget>[];
        for (var i = 0; i < displayGoals.length; i += 2) {
          final row = <Widget>[
            Expanded(
              child: _GoalCard(
                goal: displayGoals[i],
                exerciseName: nameMap[displayGoals[i].exerciseId] ?? 'Unknown',
                currentPB: pbMap[displayGoals[i].exerciseId],
              ),
            ),
          ];
          if (i + 1 < displayGoals.length) {
            row.add(const SizedBox(width: 12));
            row.add(
              Expanded(
                child: _GoalCard(
                  goal: displayGoals[i + 1],
                  exerciseName:
                      nameMap[displayGoals[i + 1].exerciseId] ?? 'Unknown',
                  currentPB: pbMap[displayGoals[i + 1].exerciseId],
                ),
              ),
            );
          } else {
            row.add(const SizedBox(width: 12));
            row.add(const Expanded(child: SizedBox()));
          }
          cards.add(Row(children: row));
        }

        // Add Goal card always full-width below the grid
        if (displayGoals.length < 4) {
          cards.add(const SizedBox(height: 12));
          cards.add(
            SizedBox(
              width: double.infinity,
              child: _AddGoalCard(
                onTap: () => _showAddGoalSheet(context),
              ),
            ),
          );
        }

        return Column(
          children: cards
              .expand((w) => [w, const SizedBox(height: 12)])
              .toList()
            ..removeLast(),
        );
      },
      loading: () => const Row(
        children: [
          Expanded(child: _ShimmerCard(height: 140)),
          SizedBox(width: 12),
          Expanded(child: _ShimmerCard(height: 140)),
        ],
      ),
      error: (e, _) => const _ErrorCard(
        message: 'Could not load goals',
        onRetry: null,
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddGoalBottomSheet(),
    );
  }

  // ── Recent activity ─────────────────────────────────────────────────────
  Widget _buildRecentActivity({
    required AsyncValue<List<WorkoutLogData>> workoutLogs,
    required AsyncValue<List<WorkoutPlanData>> workoutPlans,
  }) {
    return workoutLogs.when(
      data: (logs) {
        final completed =
            logs.where((l) => !l.inProgress).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        final recent = completed.take(5).toList();

        if (recent.isEmpty) {
          return const _EmptyState(
            icon: Icons.history_rounded,
            message: 'No recent workouts',
            subtitle: 'Complete a workout to see it here',
          );
        }

        final planMap = <String, String>{};
        final plans = workoutPlans.valueOrNull;
        if (plans != null) {
          for (final p in plans) {
            planMap[p.id] = p.name;
          }
        }

        return Column(
          children: recent
              .map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentActivityCard(
                      log: log,
                      workoutName: planMap[log.workoutPlanId] ?? 'Workout',
                    ),
                  ))
              .toList(),
        );
      },
      loading: () => Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _ShimmerCard(height: 88),
          ),
        ),
      ),
      error: (e, _) => const _ErrorCard(
        message: 'Could not load activity',
        onRetry: null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper: calculate daily streak
// ═══════════════════════════════════════════════════════════════════════════
int _calculateStreak(List<WorkoutLogData> logs) {
  final completed = logs.where((l) => !l.inProgress).toList();
  if (completed.isEmpty) return 0;

  final workoutDays = <DateTime>{};
  for (final log in completed) {
    workoutDays.add(DateTime(log.date.year, log.date.month, log.date.day));
  }

  final today = DateTime.now();
  var current = DateTime(today.year, today.month, today.day);

  // Allow streak to start from today or yesterday
  if (!workoutDays.contains(current)) {
    current = current.subtract(const Duration(days: 1));
    if (!workoutDays.contains(current)) return 0;
  }

  int streak = 0;
  while (workoutDays.contains(current)) {
    streak++;
    current = current.subtract(const Duration(days: 1));
  }
  return streak;
}

// ═══════════════════════════════════════════════════════════════════════════
// _StatCard
// ═══════════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final AsyncValue<int> value;
  final String label;
  final String? suffix;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.danger, size: 20),
          ),
          const SizedBox(height: 12),
          value.when(
            data: (v) => Text(
              suffix != null ? '$v $suffix' : '$v',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                height: 1.1,
              ),
            ),
            loading: () => const _ShimmerBlock(width: 50, height: 36),
            error: (_, __) => const Text(
              '--',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.textMutedDark,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryDark,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _GoalCard
// ═══════════════════════════════════════════════════════════════════════════
class _GoalCard extends ConsumerWidget {
  final UserGoalData goal;
  final String exerciseName;
  final UserExercisePBData? currentPB;

  const _GoalCard({
    required this.goal,
    required this.exerciseName,
    this.currentPB,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeight = currentPB?.weight ?? 0.0;
    final target = goal.goalValue;
    final progress = target > 0 ? (currentWeight / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMutedDark,
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceDark,
                        title: const Text(
                          'Delete Goal',
                          style: TextStyle(color: AppColors.textPrimaryDark),
                        ),
                        content: Text(
                          'Remove the goal for $exerciseName?',
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textSecondaryDark),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref
                          .read(userRepositoryProvider)
                          .deleteGoal(goal.id);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${currentWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                ' / ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
                ),
              ),
              Text(
                '${target.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariantDark,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMutedDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _AddGoalCard
// ═══════════════════════════════════════════════════════════════════════════
class _AddGoalCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddGoalCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text('Add Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _AddGoalBottomSheet
// ═══════════════════════════════════════════════════════════════════════════
class _AddGoalBottomSheet extends ConsumerStatefulWidget {
  const _AddGoalBottomSheet();

  @override
  ConsumerState<_AddGoalBottomSheet> createState() =>
      _AddGoalBottomSheetState();
}

class _AddGoalBottomSheetState extends ConsumerState<_AddGoalBottomSheet> {
  final _weightController = TextEditingController();
  final _searchController = TextEditingController();
  ExerciseData? _selectedExercise;
  String _searchQuery = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _weightController.removeListener(_onFieldChanged);
    _weightController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (_selectedExercise == null) return;
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.insertGoal(UserGoalsCompanion.insert(
        id: const Uuid().v4(),
        exerciseId: _selectedExercise!.id,
        goalType: GoalType.weight,
        goalValue: weight,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goal: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final allExercises = ref.watch(allExercisesProvider);

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Text(
                'Add Goal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 20),

              // Exercise search field
              TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  hintText: 'Search exercise...',
                  hintStyle:
                      const TextStyle(color: AppColors.textMutedDark),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMutedDark,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 8),

              // Exercise list
              allExercises.when(
                data: (exercises) {
                  final filtered = _searchQuery.isEmpty
                      ? exercises
                      : exercises.where((e) {
                          final q = _searchQuery.toLowerCase();
                          return e.name.toLowerCase().contains(q) ||
                              e.category.name.toLowerCase().contains(q);
                        }).toList();

                  return Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No exercises found',
                              style: TextStyle(
                                color: AppColors.textMutedDark,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: AppColors.borderDark,
                            ),
                            itemBuilder: (_, i) {
                              final ex = filtered[i];
                              final isSelected =
                                  _selectedExercise?.id == ex.id;
                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor:
                                    AppColors.primary.withOpacity(0.1),
                                title: Text(
                                  ex.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimaryDark,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  ex.category.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMutedDark,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      )
                                    : null,
                                onTap: () => setState(
                                    () => _selectedExercise = ex),
                              );
                            },
                          ),
                  );
                },
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Could not load exercises',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_selectedExercise != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Selected: ${_selectedExercise!.name}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Target weight field
              TextField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: 'Target Weight',
                  labelStyle:
                      const TextStyle(color: AppColors.textSecondaryDark),
                  suffixText: 'kg',
                  suffixStyle:
                      const TextStyle(color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedExercise != null &&
                          _weightController.text.trim().isNotEmpty &&
                          !_saving
                      ? _saveGoal
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor:
                        AppColors.surfaceVariantDark,
                    disabledForegroundColor: AppColors.textMutedDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text(
                          'Save Goal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _RecentActivityCard
// ═══════════════════════════════════════════════════════════════════════════
class _RecentActivityCard extends StatelessWidget {
  final WorkoutLogData log;
  final String workoutName;

  const _RecentActivityCard({
    required this.log,
    required this.workoutName,
  });

  @override
  Widget build(BuildContext context) {
    final durationMin = (log.duration / 60).round();
    final dateStr = _formatDate(log.date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Row(
        children: [
          // Leading icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.textMutedDark),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.timer_outlined,
                        size: 12, color: AppColors.textMutedDark),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(log.duration),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Trailing duration badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$durationMin min',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _EmptyState
// ═══════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textMutedDark),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMutedDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ErrorCard
// ═══════════════════════════════════════════════════════════════════════════
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorCard({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 32, color: AppColors.danger),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ShimmerCard – loading placeholder
// ═══════════════════════════════════════════════════════════════════════════
class _ShimmerCard extends StatelessWidget {
  final double height;

  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _NutritionMacro – Nutrition macro display
// ═══════════════════════════════════════════════════════════════════════════
class _NutritionMacro extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _NutritionMacro({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(0)}g',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ShimmerBlock – inline loading placeholder
// ═══════════════════════════════════════════════════════════════════════════
class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBlock({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _MuscleHeatMap — body silhouette with muscle group highlights
// ═══════════════════════════════════════════════════════════════════════════
class _MuscleHeatMap extends StatefulWidget {
  final AsyncValue<Map<Muscle, int>> muscleData;
  const _MuscleHeatMap({required this.muscleData});

  @override
  State<_MuscleHeatMap> createState() => _MuscleHeatMapState();
}

class _MuscleHeatMapState extends State<_MuscleHeatMap> {
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          // Header with toggle
          Row(
            children: [
              Icon(Icons.accessibility_new_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'THIS WEEK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const Spacer(),
              _viewToggle(),
            ],
          ),
          const SizedBox(height: 16),

          // Body silhouette
          widget.muscleData.when(
            data: (data) => _buildBody(data),
            loading: () => SizedBox(
              height: 280,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, __) => SizedBox(
              height: 280,
              child: Center(
                child: Text('Unable to load data',
                    style: TextStyle(color: AppColors.textMutedDark)),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _viewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('Front', _showFront),
          _toggleBtn('Back', !_showFront),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _showFront = label == 'Front'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.textMutedDark,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Map<Muscle, int> data) {
    final maxVal = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    final muscles = _showFront
        ? _frontMuscles
        : _backMuscles;

    return SizedBox(
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body outline
          CustomPaint(
            size: const Size(180, 340),
            painter: _BodyOutlinePainter(isFront: _showFront),
          ),
          // Muscle regions
          ...muscles.entries.map((entry) {
            final muscle = entry.key;
            final region = entry.value;
            final count = data[muscle] ?? 0;
            final intensity = count > 0 ? (count / maxVal).clamp(0.15, 1.0) : 0.0;

            return Positioned(
              left: region.x,
              top: region.y,
              child: GestureDetector(
                onTap: () => _showMuscleTooltip(context, muscle, count),
                child: Container(
                  width: region.w,
                  height: region.h,
                  decoration: BoxDecoration(
                    color: intensity > 0
                        ? AppColors.primary.withOpacity(intensity * 0.85)
                        : AppColors.surfaceVariantDark.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(region.radius),
                  ),
                ),
              ),
            );
          }),
          // Muscle labels for active muscles
          ...muscles.entries.where((e) => (data[e.key] ?? 0) > 0).map((entry) {
            final region = entry.value;
            return Positioned(
              left: region.labelX,
              top: region.labelY,
              child: Text(
                _muscleName(entry.key),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 2),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showMuscleTooltip(BuildContext context, Muscle muscle, int count) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_muscleName(muscle)}: ${count > 0 ? "$count hits this week" : "Not trained this week"}',
          style: const TextStyle(color: AppColors.textPrimaryDark),
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Rest', style: TextStyle(fontSize: 10, color: AppColors.textMutedDark)),
        const SizedBox(width: 8),
        Container(
          width: 120,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceVariantDark.withOpacity(0.3),
                AppColors.primary.withOpacity(0.3),
                AppColors.primary.withOpacity(0.6),
                AppColors.primary,
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('Active', style: TextStyle(fontSize: 10, color: AppColors.primary)),
      ],
    );
  }

  String _muscleName(Muscle m) {
    switch (m) {
      case Muscle.abdominals: return 'Abs';
      case Muscle.hamstrings: return 'Hams';
      case Muscle.adductors: return 'Adductors';
      case Muscle.quadriceps: return 'Quads';
      case Muscle.biceps: return 'Biceps';
      case Muscle.shoulders: return 'Shoulders';
      case Muscle.chest: return 'Chest';
      case Muscle.middleBack: return 'Mid Back';
      case Muscle.calves: return 'Calves';
      case Muscle.glutes: return 'Glutes';
      case Muscle.lowerBack: return 'Low Back';
      case Muscle.lats: return 'Lats';
      case Muscle.triceps: return 'Triceps';
      case Muscle.traps: return 'Traps';
      case Muscle.forearms: return 'Forearms';
      case Muscle.neck: return 'Neck';
      case Muscle.abductors: return 'Abductors';
    }
  }
}

// Muscle region positioning data
class _MuscleRegion {
  final double x, y, w, h, radius, labelX, labelY;
  const _MuscleRegion(this.x, this.y, this.w, this.h, this.radius, this.labelX, this.labelY);
}

// Center of canvas = x:90 (half of 180 width)
// Positions calibrated for 180×340 body proportions

const _frontMuscles = <Muscle, _MuscleRegion>{
  // Head area offset: body centered at x~98 in a 180-wide space, y starts ~0
  Muscle.neck:       _MuscleRegion(82, 52, 16, 14, 4, 84, 54),
  Muscle.shoulders:  _MuscleRegion(54, 68, 72, 16, 6, 62, 70),
  Muscle.chest:      _MuscleRegion(62, 86, 56, 28, 8, 76, 94),
  Muscle.biceps:     _MuscleRegion(48, 100, 14, 32, 6, 49, 112),
  Muscle.triceps:    _MuscleRegion(118, 100, 14, 32, 6, 119, 112),
  Muscle.forearms:   _MuscleRegion(42, 138, 12, 30, 5, 43, 148),
  Muscle.abdominals: _MuscleRegion(70, 118, 40, 40, 6, 78, 132),
  Muscle.quadriceps: _MuscleRegion(64, 190, 52, 54, 8, 76, 210),
  Muscle.adductors:  _MuscleRegion(78, 178, 24, 30, 6, 80, 188),
  Muscle.abductors:  _MuscleRegion(62, 168, 56, 18, 6, 72, 172),
  Muscle.calves:     _MuscleRegion(66, 260, 48, 40, 8, 78, 274),
};

const _backMuscles = <Muscle, _MuscleRegion>{
  Muscle.neck:       _MuscleRegion(82, 52, 16, 14, 4, 84, 54),
  Muscle.traps:      _MuscleRegion(64, 64, 52, 22, 6, 78, 70),
  Muscle.shoulders:  _MuscleRegion(54, 68, 72, 16, 6, 62, 70),
  Muscle.lats:       _MuscleRegion(58, 90, 64, 34, 8, 76, 100),
  Muscle.middleBack: _MuscleRegion(70, 100, 40, 22, 6, 76, 106),
  Muscle.lowerBack:  _MuscleRegion(74, 126, 32, 24, 6, 78, 132),
  Muscle.triceps:    _MuscleRegion(48, 100, 14, 32, 6, 49, 112),
  Muscle.forearms:   _MuscleRegion(118, 138, 12, 30, 5, 119, 148),
  Muscle.glutes:     _MuscleRegion(66, 156, 48, 30, 8, 78, 166),
  Muscle.hamstrings: _MuscleRegion(64, 192, 52, 50, 8, 76, 210),
  Muscle.calves:     _MuscleRegion(66, 260, 48, 40, 8, 78, 274),
};

// ═══════════════════════════════════════════════════════════════════════════
// Body Outline Painter — draws a realistic human silhouette
// ═══════════════════════════════════════════════════════════════════════════
class _BodyOutlinePainter extends CustomPainter {
  final bool isFront;
  _BodyOutlinePainter({required this.isFront});

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = AppColors.surfaceVariantDark.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.surfaceVariantDark.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;

    // Head with gradient
    final headGradient = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.surfaceVariantDark.withOpacity(0.12),
          AppColors.surfaceVariantDark.withOpacity(0.06),
        ],
      ).createShader(Rect.fromCenter(center: Offset(cx, 28), width: 30, height: 36));
    
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 28), width: 30, height: 36),
      headGradient,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 28), width: 30, height: 36),
      outlinePaint,
    );

    // Create body path
    final bodyPath = Path();
    
    // Neck
    bodyPath.moveTo(cx - 8, 46);
    bodyPath.lineTo(cx - 8, 60);
    bodyPath.lineTo(cx + 8, 60);
    bodyPath.lineTo(cx + 8, 46);
    canvas.drawPath(bodyPath, fillPaint);
    canvas.drawPath(bodyPath, outlinePaint);

    // Torso outline with realistic shape
    final torsoPath = Path();
    torsoPath.moveTo(cx - 8, 60); // Left neck base
    
    // Left shoulder
    torsoPath.cubicTo(cx - 20, 65, cx - 38, 68, cx - 42, 75);
    
    // Left torso
    torsoPath.cubicTo(cx - 42, 90, cx - 40, 110, cx - 38, 130);
    torsoPath.cubicTo(cx - 37, 145, cx - 34, 155, cx - 32, 165);
    
    // Left hip
    torsoPath.cubicTo(cx - 28, 170, cx - 22, 172, cx - 18, 172);
    
    // Groin area (middle bottom)
    torsoPath.lineTo(cx - 8, 172);
    torsoPath.lineTo(cx + 8, 172);
    
    // Right hip
    torsoPath.cubicTo(cx + 22, 172, cx + 28, 170, cx + 32, 165);
    
    // Right torso
    torsoPath.cubicTo(cx + 34, 155, cx + 37, 145, cx + 38, 130);
    torsoPath.cubicTo(cx + 40, 110, cx + 42, 90, cx + 42, 75);
    
    // Right shoulder
    torsoPath.cubicTo(cx + 38, 68, cx + 20, 65, cx + 8, 60);
    
    torsoPath.close();
    canvas.drawPath(torsoPath, fillPaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // Arms
    _drawArm(canvas, cx - 42, 75, true, fillPaint, outlinePaint);  // Left arm
    _drawArm(canvas, cx + 42, 75, false, fillPaint, outlinePaint); // Right arm

    // Legs
    _drawLeg(canvas, cx - 18, 172, true, fillPaint, outlinePaint);  // Left leg
    _drawLeg(canvas, cx + 18, 172, false, fillPaint, outlinePaint); // Right leg
    
    // Add subtle muscle definition lines (anatomical details)
    if (isFront) {
      _drawFrontDetails(canvas, cx, outlinePaint);
    } else {
      _drawBackDetails(canvas, cx, outlinePaint);
    }
  }

  void _drawArm(Canvas canvas, double startX, double startY, bool isLeft, Paint fillPaint, Paint outlinePaint) {
    final sign = isLeft ? -1 : 1;
    final armPath = Path();
    
    armPath.moveTo(startX, startY);
    // Upper arm (shoulder to elbow)
    armPath.cubicTo(
      startX + sign * 4, startY + 25,
      startX + sign * 6, startY + 50,
      startX + sign * 4, startY + 68,
    );
    // Forearm (elbow to wrist)
    armPath.cubicTo(
      startX + sign * 2, startY + 85,
      startX + sign * 0, startY + 95,
      startX - sign * 2, startY + 104,
    );
    // Wrist to hand
    armPath.lineTo(startX - sign * 4, startY + 106);
    
    // Return path (inner side)
    armPath.lineTo(startX - sign * 2, startY + 104);
    armPath.cubicTo(
      startX + sign * 2, startY + 93,
      startX + sign * 5, startY + 83,
      startX + sign * 7, startY + 68,
    );
    armPath.cubicTo(
      startX + sign * 8, startY + 50,
      startX + sign * 6, startY + 25,
      startX + sign * 3, startY,
    );
    armPath.close();
    
    canvas.drawPath(armPath, fillPaint);
    canvas.drawPath(armPath, outlinePaint);
  }

  void _drawLeg(Canvas canvas, double startX, double startY, bool isLeft, Paint fillPaint, Paint outlinePaint) {
    final sign = isLeft ? -1 : 1;
    final legPath = Path();
    
    legPath.moveTo(startX, startY);
    // Thigh
    legPath.cubicTo(
      startX + sign * 8, startY + 30,
      startX + sign * 10, startY + 60,
      startX + sign * 8, startY + 88,
    );
    // Knee area
    legPath.cubicTo(
      startX + sign * 6, startY + 100,
      startX + sign * 5, startY + 110,
      startX + sign * 4, startY + 120,
    );
    // Calf
    legPath.cubicTo(
      startX + sign * 3, startY + 135,
      startX + sign * 4, startY + 145,
      startX + sign * 6, startY + 154,
    );
    // Ankle and foot
    legPath.lineTo(startX + sign * 8, startY + 164);
    
    // Return path (inner side)
    legPath.lineTo(startX + sign * 4, startY + 164);
    legPath.cubicTo(
      startX + sign * 2, startY + 145,
      startX, startY + 135,
      startX - sign * 1, startY + 120,
    );
    legPath.cubicTo(
      startX - sign * 2, startY + 110,
      startX - sign * 2, startY + 100,
      startX, startY + 88,
    );
    legPath.cubicTo(
      startX + sign * 2, startY + 60,
      startX + sign * 3, startY + 30,
      startX + sign * 2, startY,
    );
    legPath.close();
    
    canvas.drawPath(legPath, fillPaint);
    canvas.drawPath(legPath, outlinePaint);
  }

  void _drawFrontDetails(Canvas canvas, double cx, Paint paint) {
    final detailPaint = Paint()
      ..color = AppColors.surfaceVariantDark.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Abs definition
    canvas.drawLine(Offset(cx, 118), Offset(cx, 160), detailPaint);
    canvas.drawLine(Offset(cx - 12, 124), Offset(cx + 12, 124), detailPaint);
    canvas.drawLine(Offset(cx - 14, 138), Offset(cx + 14, 138), detailPaint);
    canvas.drawLine(Offset(cx - 12, 152), Offset(cx + 12, 152), detailPaint);
    
    // Chest definition
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 14, 92), width: 20, height: 16),
      -0.5,
      1.0,
      false,
      detailPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 14, 92), width: 20, height: 16),
      2.6,
      1.0,
      false,
      detailPaint,
    );
  }

  void _drawBackDetails(Canvas canvas, double cx, Paint paint) {
    final detailPaint = Paint()
      ..color = AppColors.surfaceVariantDark.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Spine
    canvas.drawLine(Offset(cx, 70), Offset(cx, 165), detailPaint);
    
    // Shoulder blades
    final leftScapula = Path()
      ..moveTo(cx - 18, 82)
      ..cubicTo(cx - 22, 88, cx - 24, 96, cx - 22, 104)
      ..cubicTo(cx - 20, 110, cx - 16, 112, cx - 10, 110);
    canvas.drawPath(leftScapula, detailPaint);
    
    final rightScapula = Path()
      ..moveTo(cx + 18, 82)
      ..cubicTo(cx + 22, 88, cx + 24, 96, cx + 22, 104)
      ..cubicTo(cx + 20, 110, cx + 16, 112, cx + 10, 110);
    canvas.drawPath(rightScapula, detailPaint);
    
    // Lower back contour
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 140), width: 40, height: 24),
      0,
      3.14,
      false,
      detailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyOutlinePainter oldDelegate) =>
      isFront != oldDelegate.isFront;
}

// ═══════════════════════════════════════════════════════════════════════════
// Formatting helpers
// ═══════════════════════════════════════════════════════════════════════════
String _formatDate(DateTime date) {
  return DateFormat('MMM d, y').format(date);
}

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final mins = seconds ~/ 60;
  if (mins < 60) return '${mins}m';
  final hrs = mins ~/ 60;
  final remainMins = mins % 60;
  return remainMins > 0 ? '${hrs}h ${remainMins}m' : '${hrs}h';
}
