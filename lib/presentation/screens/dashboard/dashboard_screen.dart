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
import '../../../data/database/app_database.dart';

// ---------------------------------------------------------------------------
// Dashboard Screen - matches the FitForge web app design
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

                // ── Insights section ─────────────────────────────
                _buildSectionHeading('Insights'),
                const SizedBox(height: 12),
                _WeeklyBarChart(workoutsPerDay: _getWeeklyWorkoutData(workoutLogs.valueOrNull)),
                const SizedBox(height: 12),
                _WeeklyStatsCard(
                  weeklyWorkouts: weeklyWorkouts,
                  weeklyPRs: weeklyPRs,
                  totalVolume: ref.watch(totalVolumeProvider(weekDateRange)),
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
                const SizedBox(height: 24),
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
// Helper: weekly workout data for bar chart
// ═══════════════════════════════════════════════════════════════════════════
List<int> _getWeeklyWorkoutData(List<WorkoutLogData>? logs) {
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));

  final counts = List.filled(7, 0); // Mon-Sun
  if (logs == null) return counts;

  for (final log in logs) {
    if (log.inProgress) continue;
    final logDay = DateTime(log.date.year, log.date.month, log.date.day);
    final daysSinceMonday = logDay.difference(monday).inDays;
    if (daysSinceMonday >= 0 && daysSinceMonday < 7) {
      counts[daysSinceMonday]++;
    }
  }
  return counts;
}

// ═══════════════════════════════════════════════════════════════════════════
// _WeeklyBarChart
// ═══════════════════════════════════════════════════════════════════════════
class _WeeklyBarChart extends StatelessWidget {
  final List<int> workoutsPerDay;

  const _WeeklyBarChart({required this.workoutsPerDay});

  @override
  Widget build(BuildContext context) {
    final maxVal = workoutsPerDay.reduce((a, b) => a > b ? a : b).clamp(1, 100);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.danger, size: 20),
              const SizedBox(width: 8),
              const Text('WEEKLY ACTIVITY', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                letterSpacing: 1.0, color: AppColors.textSecondaryDark,
              )),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = workoutsPerDay[i];
                final barHeight = val > 0 ? (val / maxVal * 80).clamp(8.0, 80.0) : 4.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (val > 0)
                      Text('$val', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: val > 0 ? AppColors.primary : AppColors.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(days[i], style: TextStyle(
                      color: val > 0 ? AppColors.textPrimaryDark : AppColors.textMutedDark,
                      fontSize: 12, fontWeight: FontWeight.w500,
                    )),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _WeeklyStatsCard
// ═══════════════════════════════════════════════════════════════════════════
class _WeeklyStatsCard extends StatelessWidget {
  final AsyncValue<int> weeklyWorkouts;
  final AsyncValue<int> weeklyPRs;
  final AsyncValue<double> totalVolume;

  const _WeeklyStatsCard({
    required this.weeklyWorkouts,
    required this.weeklyPRs,
    required this.totalVolume,
  });

  @override
  Widget build(BuildContext context) {
    final volumeVal = totalVolume.valueOrNull ?? 0.0;
    final workoutsVal = weeklyWorkouts.valueOrNull ?? 0;
    final prsVal = weeklyPRs.valueOrNull ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.danger, size: 20),
              const SizedBox(width: 8),
              const Text('THIS WEEK', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                letterSpacing: 1.0, color: AppColors.textSecondaryDark,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniStat('Workouts', '$workoutsVal', Icons.fitness_center_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat('Volume', '${(volumeVal / 1000).toStringAsFixed(1)}k kg', Icons.monitor_weight_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat('PRs', '$prsVal', Icons.emoji_events_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
            color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            color: AppColors.textSecondaryDark, fontSize: 11,
          )),
        ],
      ),
    );
  }
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
