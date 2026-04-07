import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/animated_ai_gradient.dart';
import '../../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/workout_providers.dart';
import 'add_exercise_sheet.dart';
import 'edit_routine_screen.dart';
import 'preset_packs_screen.dart';
import '../workout/active_workout_screen.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  @override
  Widget build(BuildContext context) {
    final workoutPlans = ref.watch(allWorkoutPlansProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          heroTag: 'routines_fab',
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          onPressed: () => _showCreateRoutineDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: workoutPlans.when(
          data: (plans) => _buildContent(plans),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildContent(List<WorkoutPlanData> plans) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildExplorePacksCard()),
        if (plans.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          _buildRoutineGrid(plans),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Start Workout',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplorePacksCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PresetPacksScreen()),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderDark,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedAiGradient(
                  width: 42,
                  height: 42,
                  borderRadius: BorderRadius.circular(11),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Workout Packs',
                        style: TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pre-built splits ready to add',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMutedDark,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantDark,
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
              'No routines yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first routine to start tracking\nyour workouts!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateRoutineDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create Routine',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineGrid(List<WorkoutPlanData> plans) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _RoutineCard(
            plan: plans[index],
            onEdit: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditRoutineScreen(routineId: plans[index].id),
                ),
              );
            },
            onDelete: () => _showDeleteConfirmation(context, plans[index]),
            onStart: () => _onStartWorkout(context, plans[index]),
            onAddExercises: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddExerciseSheet(workoutPlanId: plans[index].id),
              );
            },
          ),
          childCount: plans.length,
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(allWorkoutPlansProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onStartWorkout(BuildContext context, WorkoutPlanData plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(
          routineId: plan.id,
          routineName: plan.name,
        ),
      ),
    );
  }

  void _showCreateRoutineDialog(BuildContext context) {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'New Routine',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Form
              Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Routine Name *',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: _inputDecoration('Routine Name', 'e.g., Push Day'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: notesController,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: _inputDecoration('Notes (optional)', 'Add any notes...'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              // Create button
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.of(sheetContext).padding.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final workoutRepo = ref.read(workoutRepositoryProvider);
                      await workoutRepo.insertWorkoutPlan(
                        WorkoutPlansCompanion.insert(
                          id: const Uuid().v4(),
                          name: nameController.text.trim(),
                          notes: drift.Value(
                            notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          ),
                          isSystemRoutine: const drift.Value(false),
                        ),
                      );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Routine created!'),
                            backgroundColor: AppColors.surfaceVariantDark,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Routine',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditRoutineDialog(BuildContext context, WorkoutPlanData plan) {
    final nameController = TextEditingController(text: plan.name);
    final notesController = TextEditingController(text: plan.notes ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'Edit Routine',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Form
              Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Routine Name *',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: _inputDecoration('Routine Name', 'e.g., Push Day'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: notesController,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: _inputDecoration('Notes (optional)', 'Add any notes...'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              // Save button
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.of(sheetContext).padding.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final workoutRepo = ref.read(workoutRepositoryProvider);
                      await workoutRepo.updateWorkoutPlan(
                        plan.copyWith(
                          name: nameController.text.trim(),
                          notes: drift.Value(
                            notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          ),
                        ),
                      );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Routine updated!'),
                            backgroundColor: AppColors.surfaceVariantDark,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WorkoutPlanData plan) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 10),
            Text(
              'Delete Routine',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${plan.name}"? This action cannot be undone.',
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final workoutRepo = ref.read(workoutRepositoryProvider);
              await workoutRepo.deleteWorkoutPlan(plan.id);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Routine deleted'),
                    backgroundColor: AppColors.surfaceVariantDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
      hintStyle: TextStyle(color: AppColors.textSecondaryDark.withOpacity(0.5)),
      filled: true,
      fillColor: AppColors.backgroundDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.surfaceVariantDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.surfaceVariantDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ---------------------------------------------------------------------------
// Routine Card Widget
// ---------------------------------------------------------------------------
class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
    required this.onStart,
    required this.onAddExercises,
  });

  final WorkoutPlanData plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStart;
  final VoidCallback onAddExercises;

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(workoutPlanExercisesProvider(plan.id));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceVariantDark.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Updated ${_timeAgo(plan.updatedAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondaryDark,
                    size: 20,
                  ),
                  color: AppColors.surfaceVariantDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'add_exercises',
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded,
                              size: 18, color: AppColors.primary),
                          SizedBox(width: 10),
                          Text('Add Exercises',
                              style: TextStyle(color: AppColors.textPrimaryDark)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 18, color: AppColors.textPrimaryDark),
                          SizedBox(width: 10),
                          Text('Edit',
                              style: TextStyle(color: AppColors.textPrimaryDark)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.danger),
                          SizedBox(width: 10),
                          Text('Delete',
                              style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'add_exercises') onAddExercises();
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Divider(
            color: AppColors.surfaceVariantDark.withOpacity(0.5),
            height: 1,
          ),

          // Exercise List Preview
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'No exercises added',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  );
                }

                final displayExercises = exercises.length > 5
                    ? exercises.sublist(0, 5)
                    : exercises;
                final remaining = exercises.length - displayExercises.length;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...displayExercises.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _ExerciseRow(exercise: e),
                        ),
                      ),
                      if (remaining > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+$remaining more',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
              error: (_, __) => const Center(
                child: Icon(Icons.error_outline,
                    size: 16, color: AppColors.textSecondaryDark),
              ),
            ),
          ),

          // Start Workout Button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: SizedBox(
              width: double.infinity,
              child: Builder(
                builder: (_) {
                  final hasExercises = exercisesAsync.valueOrNull?.isNotEmpty ?? false;
                  return TextButton.icon(
                    onPressed: hasExercises ? onStart : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text(
                      'Start Workout',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: hasExercises ? AppColors.primary : AppColors.textMutedDark,
                      backgroundColor: hasExercises
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surfaceVariantDark.withOpacity(0.3),
                      disabledForegroundColor: AppColors.textMutedDark,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single Exercise Row (resolves exercise name from ID)
// ---------------------------------------------------------------------------
class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({required this.exercise});

  final WorkoutPlanExerciseData exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseProvider(exercise.exerciseId));

    final name = exerciseAsync.whenOrNull(data: (e) => e?.name) ?? '...';

    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${exercise.sets} x $name',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
