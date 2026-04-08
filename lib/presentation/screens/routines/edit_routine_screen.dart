import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_constants.dart';
import '../../../models/enums.dart';
import '../../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_providers.dart';

import 'add_exercise_sheet.dart';

class EditRoutineScreen extends ConsumerStatefulWidget {
  final String routineId;

  const EditRoutineScreen({super.key, required this.routineId});

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  List<WorkoutPlanExerciseData> _exercises = [];
  final Set<String> _deletedExerciseIds = {};
  final Map<String, TextEditingController> _setsControllers = {};
  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _durationControllers = {};
  final Map<String, TrackingType> _trackingTypes = {};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    for (final c in _setsControllers.values) {
      c.dispose();
    }
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    for (final c in _durationControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final plan = await repo.getWorkoutPlan(widget.routineId);
      final exercises = await repo.getWorkoutPlanExercises(widget.routineId);

      if (mounted) {
        setState(() {
          _nameController.text = plan?.name ?? '';
          _notesController.text = plan?.notes ?? '';
          _exercises = List.from(exercises);
          _initControllers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _initControllers() {
    for (final ex in _exercises) {
      _initControllerForExercise(ex);
    }
  }

  void _initControllerForExercise(WorkoutPlanExerciseData ex) {
    _setsControllers[ex.id] =
        TextEditingController(text: ex.sets.toString());
    _repsControllers[ex.id] =
        TextEditingController(text: (ex.reps ?? 10).toString());
    _durationControllers[ex.id] =
        TextEditingController(text: (ex.exerciseDuration ?? 30).toString());
    _trackingTypes[ex.id] = ex.trackingType;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex--;
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  void _removeExercise(int index) {
    final exercise = _exercises[index];
    setState(() {
      _exercises.removeAt(index);
      _deletedExerciseIds.add(exercise.id);
      _setsControllers.remove(exercise.id)?.dispose();
      _repsControllers.remove(exercise.id)?.dispose();
      _durationControllers.remove(exercise.id)?.dispose();
      _trackingTypes.remove(exercise.id);
    });
  }

  Future<void> _openAddExerciseSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExerciseSheet(workoutPlanId: widget.routineId),
    );

    if (!mounted) return;

    // Pick up any newly-added exercises from the database,
    // but exclude ones the user deleted in this editing session
    final repo = ref.read(workoutRepositoryProvider);
    final dbExercises =
        await repo.getWorkoutPlanExercises(widget.routineId);
    final existingIds = _exercises.map((e) => e.id).toSet();

    final newExercises = dbExercises
        .where((e) => !existingIds.contains(e.id) && !_deletedExerciseIds.contains(e.id))
        .toList();
    if (newExercises.isNotEmpty) {
      setState(() {
        for (final ex in newExercises) {
          _exercises.add(ex);
          _initControllerForExercise(ex);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(workoutRepositoryProvider);

      // 1. Update routine name / notes
      final plan = await repo.getWorkoutPlan(widget.routineId);
      if (plan != null) {
        await repo.updateWorkoutPlan(
          plan.copyWith(
            name: _nameController.text.trim(),
            notes: drift.Value(
              _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // 2. Delete exercises removed by the user
      final currentIds = _exercises.map((e) => e.id).toSet();
      final dbExercises =
          await repo.getWorkoutPlanExercises(widget.routineId);
      for (final original in dbExercises) {
        if (!currentIds.contains(original.id)) {
          await repo.deleteWorkoutPlanExercise(original.id);
        }
      }

      // 3. Update remaining exercises (sets, reps, order, tracking type)
      for (int i = 0; i < _exercises.length; i++) {
        final exercise = _exercises[i];
        final trackingType =
            _trackingTypes[exercise.id] ?? exercise.trackingType;
        final sets =
            int.tryParse(_setsControllers[exercise.id]?.text ?? '') ??
                exercise.sets;

        int? reps;
        int? duration;

        if (trackingType == TrackingType.reps) {
          reps =
              int.tryParse(_repsControllers[exercise.id]?.text ?? '') ??
                  exercise.reps;
        } else {
          duration = int.tryParse(
                  _durationControllers[exercise.id]?.text ?? '') ??
              exercise.exerciseDuration;
        }

        await repo.updateWorkoutPlanExercise(
          exercise.copyWith(
            sets: sets,
            reps: drift.Value(reps),
            exerciseDuration: drift.Value(duration),
            order: drift.Value(i),
            trackingType: trackingType,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Routine saved!'),
            backgroundColor: AppColors.surfaceVariantDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _nameController.text.isNotEmpty
              ? _nameController.text
              : 'Edit Routine',
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.check_rounded, color: AppColors.primary),
              onPressed: _isSaving ? null : _save,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              const Text(
                'Failed to load routine',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondaryDark, fontSize: 14),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadData();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
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

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section: Routine Info ──
            _buildSectionHeader('Routine Info', Icons.info_outline_rounded),
            const SizedBox(height: 12),
            _buildNameField(),
            const SizedBox(height: 12),
            _buildNotesField(),
            const SizedBox(height: 28),

            // ── Section: Exercises ──
            _buildExercisesHeader(),
            const SizedBox(height: 12),
            if (_exercises.isEmpty)
              _buildEmptyExercises()
            else
              _buildExerciseList(),

            const SizedBox(height: 28),

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section helpers
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: AppColors.textPrimaryDark),
      decoration: _inputDecoration('Routine Name', 'e.g., Push Day'),
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Name is required'
          : null,
      onChanged: (_) => setState(() {}), // refresh AppBar title
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      style: const TextStyle(color: AppColors.textPrimaryDark),
      decoration: _inputDecoration(
          'Notes (optional)', 'Add any notes about this routine…'),
      maxLines: 3,
    );
  }

  // ---------------------------------------------------------------------------
  // Exercises section
  // ---------------------------------------------------------------------------

  Widget _buildExercisesHeader() {
    return Row(
      children: [
        const Icon(Icons.fitness_center_rounded,
            color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        const Text(
          'Exercises',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
        ),
        if (_exercises.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_exercises.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const Spacer(),
        TextButton.icon(
          onPressed: _openAddExerciseSheet,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyExercises() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 48,
            color: AppColors.textMutedDark.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No exercises yet',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Add" to include exercises',
            style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _exercises.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 8,
          color: Colors.transparent,
          shadowColor: AppColors.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        return _buildExerciseCard(_exercises[index], index);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise card
  // ---------------------------------------------------------------------------

  Widget _buildExerciseCard(
      WorkoutPlanExerciseData exercise, int index) {
    final exerciseAsync =
        ref.watch(exerciseProvider(exercise.exerciseId));
    final exerciseData = exerciseAsync.valueOrNull;
    final name = exerciseData?.name ?? 'Loading…';
    final category = exerciseData?.category.displayName ?? '';
    final trackingType =
        _trackingTypes[exercise.id] ?? TrackingType.reps;

    return Container(
      key: ValueKey(exercise.id),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: drag handle · name · delete ──
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.drag_handle_rounded,
                        color: AppColors.textMutedDark, size: 22),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeExercise(index),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.danger, size: 20),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  tooltip: 'Remove exercise',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Inputs: sets · reps/duration · tracking type ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactField(
                      'Sets',
                      _setsControllers[exercise.id]!,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: trackingType == TrackingType.reps
                        ? _buildCompactField(
                            'Reps', _repsControllers[exercise.id]!)
                        : _buildCompactField(
                            'Seconds',
                            _durationControllers[exercise.id]!),
                  ),
                  const SizedBox(width: 10),
                  _buildTrackingDropdown(exercise.id, trackingType),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Compact number field used inside exercise cards
  // ---------------------------------------------------------------------------

  Widget _buildCompactField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.backgroundDark,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tracking-type dropdown (Reps / Duration)
  // ---------------------------------------------------------------------------

  Widget _buildTrackingDropdown(
      String exerciseId, TrackingType trackingType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type',
          style: TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TrackingType>(
              value: trackingType,
              dropdownColor: AppColors.surfaceDark,
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.textSecondaryDark, size: 20),
              isDense: true,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                DropdownMenuItem(
                  value: TrackingType.reps,
                  child: Text('Reps'),
                ),
                DropdownMenuItem(
                  value: TrackingType.duration,
                  child: Text('Duration'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _trackingTypes[exerciseId] = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared input decoration (used for Name / Notes fields)
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
      hintStyle:
          TextStyle(color: AppColors.textSecondaryDark.withOpacity(0.5)),
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
