import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/enums.dart';
import '../../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_providers.dart';

class AddExerciseSheet extends ConsumerStatefulWidget {
  final String workoutPlanId;
  final VoidCallback? onCustomExerciseCreated;

  const AddExerciseSheet({
    super.key,
    required this.workoutPlanId,
    this.onCustomExerciseCreated,
  });

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedExerciseIds = {};

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(allExercisesProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMutedDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Exercises',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _showCreateCustomExercise,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Custom'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondaryDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: const TextStyle(color: AppColors.textMutedDark),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: AppColors.surfaceVariantDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textSecondaryDark),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              style: const TextStyle(color: AppColors.textPrimaryDark),
            ),
          ),
          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: exercises.when(
              data: (exerciseList) {
                final filtered = _searchQuery.isEmpty
                    ? exerciseList
                    : exerciseList
                        .where((e) =>
                            e.name.toLowerCase().contains(_searchQuery))
                        .toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemBuilder: (context, index) {
                    final exercise = filtered[index];
                    final isSelected =
                        _selectedExerciseIds.contains(exercise.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.primary.withOpacity(0.3))
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.surfaceVariantDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: AppColors.primary, size: 20)
                                : Text(
                                    exercise.name.isNotEmpty
                                        ? exercise.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          exercise.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          exercise.category.displayName,
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedExerciseIds.remove(exercise.id);
                            } else {
                              _selectedExerciseIds.add(exercise.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, s) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.danger)),
              ),
            ),
          ),

          // Bottom action bar - moves with keyboard
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset > 0 ? bottomInset + 8 : 16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(top: BorderSide(color: AppColors.borderDark)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedExerciseIds.isNotEmpty ? () => _addSelectedExercises() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: AppColors.surfaceVariantDark,
                    disabledForegroundColor: AppColors.textMutedDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedExerciseIds.isNotEmpty
                        ? 'Add ${_selectedExerciseIds.length} Exercise${_selectedExerciseIds.length > 1 ? "s" : ""}'
                        : 'Select exercises to add',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCustomExercise() {
    final nameCtrl = TextEditingController();
    CategoryType category = CategoryType.strength;
    LevelType level = LevelType.beginner;
    final Set<Muscle> selectedMuscles = {};
    EquipmentType? equipment;
    ForceType? force;
    MechanicType? mechanic;
    final instructionsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.textMutedDark, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Create Custom Exercise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          labelText: 'Exercise Name *',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true, fillColor: AppColors.surfaceVariantDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CategoryType>(
                        value: category,
                        dropdownColor: AppColors.surfaceVariantDark,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true, fillColor: AppColors.surfaceVariantDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: CategoryType.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
                        onChanged: (v) => setSheetState(() => category = v ?? category),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LevelType>(
                        value: level,
                        dropdownColor: AppColors.surfaceVariantDark,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          labelText: 'Level',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true, fillColor: AppColors.surfaceVariantDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: LevelType.values.map((l) => DropdownMenuItem(value: l, child: Text(l.displayName))).toList(),
                        onChanged: (v) => setSheetState(() => level = v ?? level),
                      ),
                      const SizedBox(height: 12),
                      const Text('Primary Muscles', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: Muscle.values.map((m) => FilterChip(
                          label: Text(m.displayName),
                          selected: selectedMuscles.contains(m),
                          onSelected: (sel) => setSheetState(() {
                            if (sel) selectedMuscles.add(m); else selectedMuscles.remove(m);
                          }),
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selectedMuscles.contains(m) ? AppColors.primary : AppColors.textSecondaryDark,
                            fontSize: 12,
                          ),
                          backgroundColor: AppColors.surfaceVariantDark,
                          side: BorderSide.none,
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      // Equipment dropdown
                      DropdownButtonFormField<EquipmentType>(
                        value: equipment,
                        dropdownColor: AppColors.surfaceVariantDark,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          labelText: 'Equipment',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true, fillColor: AppColors.surfaceVariantDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem<EquipmentType>(value: null, child: Text('None', style: TextStyle(color: AppColors.textSecondaryDark))),
                          ...EquipmentType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))),
                        ],
                        onChanged: (v) => setSheetState(() => equipment = v),
                      ),
                      const SizedBox(height: 12),
                      // Force dropdown
                      DropdownButtonFormField<ForceType>(
                        value: force,
                        dropdownColor: AppColors.surfaceVariantDark,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          labelText: 'Force',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true, fillColor: AppColors.surfaceVariantDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem<ForceType>(value: null, child: Text('None', style: TextStyle(color: AppColors.textSecondaryDark))),
                          ...ForceType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))),
                        ],
                        onChanged: (v) => setSheetState(() => force = v),
                      ),
                      const SizedBox(height: 12),
                      // Mechanic dropdown
                      DropdownButtonFormField<MechanicType>(
                        value: mechanic,
                        dropdownColor: AppColors.surfaceVariantDark,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          labelText: 'Mechanic',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          filled: true, fillColor: AppColors.surfaceVariantDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          const DropdownMenuItem<MechanicType>(value: null, child: Text('None', style: TextStyle(color: AppColors.textSecondaryDark))),
                          ...MechanicType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))),
                        ],
                        onChanged: (v) => setSheetState(() => mechanic = v),
                      ),
                      const SizedBox(height: 12),
                      // Instructions text field
                      TextField(
                        controller: instructionsCtrl,
                        style: const TextStyle(color: AppColors.textPrimaryDark),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Instructions',
                          labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                          hintText: 'One instruction per line',
                          hintStyle: const TextStyle(color: AppColors.textMutedDark),
                          filled: true, fillColor: AppColors.surfaceVariantDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Please enter an exercise name'),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ));
                          return;
                        }
                        final repo = ref.read(exerciseRepositoryProvider);
                        final id = const Uuid().v4();
                        await repo.insertExercise(ExercisesCompanion.insert(
                          id: id,
                          name: nameCtrl.text.trim(),
                          aliases: [],
                          primaryMuscles: selectedMuscles.toList(),
                          secondaryMuscles: [],
                          level: level,
                          category: category,
                          equipment: drift.Value(equipment),
                          force: drift.Value(force),
                          mechanic: drift.Value(mechanic),
                          instructions: instructionsCtrl.text.trim().isNotEmpty
                              ? instructionsCtrl.text.trim().split('\n').where((l) => l.trim().isNotEmpty).toList()
                              : [],
                          tips: [],
                        ));
                        ref.invalidate(allExercisesProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        // Auto-select the newly created exercise
                        setState(() => _selectedExerciseIds.add(id));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Create & Select', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addSelectedExercises() async {
    final repo = ref.read(workoutRepositoryProvider);
    final existingExercises =
        await repo.getWorkoutPlanExercises(widget.workoutPlanId);
    int order = existingExercises.length;

    for (final exerciseId in _selectedExerciseIds) {
      await repo.insertWorkoutPlanExercise(
        WorkoutPlanExercisesCompanion.insert(
          id: const Uuid().v4(),
          workoutPlanId: widget.workoutPlanId,
          exerciseId: exerciseId,
          sets: 3,
          reps: drift.Value(10),
          order: drift.Value(order),
          trackingType: TrackingType.reps,
        ),
      );
      order++;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${_selectedExerciseIds.length} exercise${_selectedExerciseIds.length > 1 ? "s" : ""}',
          ),
          backgroundColor: AppColors.surfaceVariantDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
