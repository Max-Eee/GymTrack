import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/enums.dart';
import '../../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_providers.dart';
import '../../../services/gemma_model_service.dart';

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

  // Local filter state
  List<CategoryType> _filterCategories = [];
  List<Muscle> _filterMuscles = [];
  List<LevelType> _filterLevels = [];
  List<EquipmentType> _filterEquipment = [];

  int get _activeFilterCount =>
      _filterCategories.length +
      _filterMuscles.length +
      _filterLevels.length +
      _filterEquipment.length;

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

          // Search bar + filter button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _activeFilterCount > 0
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _activeFilterCount > 0
                            ? AppColors.primary.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: _activeFilterCount > 0
                              ? AppColors.primary
                              : AppColors.textSecondaryDark,
                          size: 22,
                        ),
                        if (_activeFilterCount > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_activeFilterCount',
                                  style: const TextStyle(
                                    color: AppColors.onPrimary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: exercises.when(
              data: (exerciseList) {
                var filtered = exerciseList.toList();

                // Apply local filters
                if (_filterCategories.isNotEmpty) {
                  filtered = filtered
                      .where((e) => _filterCategories.contains(e.category))
                      .toList();
                }
                if (_filterMuscles.isNotEmpty) {
                  filtered = filtered
                      .where((e) => e.primaryMuscles
                          .any((m) => _filterMuscles.contains(m)))
                      .toList();
                }
                if (_filterLevels.isNotEmpty) {
                  filtered = filtered
                      .where((e) => _filterLevels.contains(e.level))
                      .toList();
                }
                if (_filterEquipment.isNotEmpty) {
                  filtered = filtered
                      .where((e) =>
                          e.equipment != null &&
                          _filterEquipment.contains(e.equipment))
                      .toList();
                }

                // Apply search query
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((e) =>
                          e.name.toLowerCase().contains(_searchQuery))
                      .toList();
                }

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

  void _showFilterSheet() {
    // Local copies declared outside builder so they persist across rebuilds
    var cats = List<CategoryType>.from(_filterCategories);
    var muscles = List<Muscle>.from(_filterMuscles);
    var levels = List<LevelType>.from(_filterLevels);
    var equipment = List<EquipmentType>.from(_filterEquipment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final hasFilters = cats.isNotEmpty ||
              muscles.isNotEmpty ||
              levels.isNotEmpty ||
              equipment.isNotEmpty;

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Filters',
                          style: TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (hasFilters)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _filterCategories = [];
                                _filterMuscles = [];
                                _filterLevels = [];
                                _filterEquipment = [];
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Clear all',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.surfaceVariantDark),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildChipSection<CategoryType>(
                            label: 'Category',
                            values: CategoryType.values,
                            selected: cats,
                            displayName: (v) => v.displayName,
                            onChanged: (list) =>
                                setSheetState(() => cats = list),
                          ),
                          const SizedBox(height: 16),
                          _buildChipSection<Muscle>(
                            label: 'Muscle',
                            values: Muscle.values,
                            selected: muscles,
                            displayName: (v) => v.displayName,
                            onChanged: (list) =>
                                setSheetState(() => muscles = list),
                          ),
                          const SizedBox(height: 16),
                          _buildChipSection<LevelType>(
                            label: 'Level',
                            values: LevelType.values,
                            selected: levels,
                            displayName: (v) =>
                                v.name[0].toUpperCase() + v.name.substring(1),
                            onChanged: (list) =>
                                setSheetState(() => levels = list),
                          ),
                          const SizedBox(height: 16),
                          _buildChipSection<EquipmentType>(
                            label: 'Equipment',
                            values: EquipmentType.values,
                            selected: equipment,
                            displayName: (v) => v.displayName,
                            onChanged: (list) =>
                                setSheetState(() => equipment = list),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterCategories = cats;
                              _filterMuscles = muscles;
                              _filterLevels = levels;
                              _filterEquipment = equipment;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChipSection<T>({
    required String label,
    required List<T> values,
    required List<T> selected,
    required String Function(T) displayName,
    required ValueChanged<List<T>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: values.map((v) {
            final isSelected = selected.contains(v);
            return GestureDetector(
              onTap: () {
                final copy = List<T>.from(selected);
                isSelected ? copy.remove(v) : copy.add(v);
                onChanged(copy);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  displayName(v),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondaryDark,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
    bool isTagging = false;

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
                      const SizedBox(height: 10),
                      // AI Auto-Tag Button
                      Builder(builder: (_) {
                        final activeModel = ref.watch(activeGemmaModelProvider);
                        if (activeModel == null) return const SizedBox.shrink();
                        return SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: isTagging ? null : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                  content: Text('Enter an exercise name first'),
                                  backgroundColor: AppColors.surfaceVariantDark,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }
                              setSheetState(() => isTagging = true);
                              try {
                                final gemma = ref.read(gemmaModelServiceProvider);
                                final muscleNames = Muscle.values.map((m) => m.displayName).join(', ');
                                final categoryNames = CategoryType.values.map((c) => c.displayName).join(', ');
                                final equipmentNames = EquipmentType.values.map((e) => e.displayName).join(', ');
                                final result = await gemma.infer(
                                  'Exercise: "$name"',
                                  systemInstruction:
                                    'You are a fitness expert. Given an exercise name, return ONLY a JSON object with these fields:\n'
                                    '- "primaryMuscles": array of muscle names from: $muscleNames\n'
                                    '- "category": one of: $categoryNames\n'
                                    '- "equipment": one of: $equipmentNames, or null\n'
                                    '- "force": one of: "Push", "Pull", "Static", or null\n'
                                    '- "mechanic": one of: "Compound", "Isolation", or null\n'
                                    '- "level": one of: "Beginner", "Intermediate", "Expert"\n'
                                    'Reply ONLY with the JSON object, no extra text.',
                                );
                                // Parse JSON from response
                                final jsonStr = result.contains('{')
                                    ? result.substring(result.indexOf('{'), result.lastIndexOf('}') + 1)
                                    : result;
                                final Map<String, dynamic> parsed;
                                try {
                                  parsed = Map<String, dynamic>.from(
                                    (await _parseJson(jsonStr)) ?? {},
                                  );
                                } catch (_) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                      content: Text('AI could not parse tags. Try again.'),
                                      backgroundColor: AppColors.danger,
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                  return;
                                }
                                // Apply parsed values
                                setSheetState(() {
                                  // Primary muscles
                                  if (parsed['primaryMuscles'] is List) {
                                    selectedMuscles.clear();
                                    for (final m in parsed['primaryMuscles']) {
                                      final match = Muscle.values.cast<Muscle?>().firstWhere(
                                        (v) => v!.displayName.toLowerCase() == m.toString().toLowerCase(),
                                        orElse: () => null,
                                      );
                                      if (match != null) selectedMuscles.add(match);
                                    }
                                  }
                                  // Category
                                  if (parsed['category'] is String) {
                                    final match = CategoryType.values.cast<CategoryType?>().firstWhere(
                                      (v) => v!.displayName.toLowerCase() == parsed['category'].toString().toLowerCase(),
                                      orElse: () => null,
                                    );
                                    if (match != null) category = match;
                                  }
                                  // Equipment
                                  if (parsed['equipment'] is String) {
                                    final match = EquipmentType.values.cast<EquipmentType?>().firstWhere(
                                      (v) => v!.displayName.toLowerCase() == parsed['equipment'].toString().toLowerCase(),
                                      orElse: () => null,
                                    );
                                    equipment = match;
                                  }
                                  // Force
                                  if (parsed['force'] is String) {
                                    final match = ForceType.values.cast<ForceType?>().firstWhere(
                                      (v) => v!.displayName.toLowerCase() == parsed['force'].toString().toLowerCase(),
                                      orElse: () => null,
                                    );
                                    force = match;
                                  }
                                  // Mechanic
                                  if (parsed['mechanic'] is String) {
                                    final match = MechanicType.values.cast<MechanicType?>().firstWhere(
                                      (v) => v!.displayName.toLowerCase() == parsed['mechanic'].toString().toLowerCase(),
                                      orElse: () => null,
                                    );
                                    mechanic = match;
                                  }
                                  // Level
                                  if (parsed['level'] is String) {
                                    final match = LevelType.values.cast<LevelType?>().firstWhere(
                                      (v) => v!.displayName.toLowerCase() == parsed['level'].toString().toLowerCase(),
                                      orElse: () => null,
                                    );
                                    if (match != null) level = match;
                                  }
                                });
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text('Tagged ${selectedMuscles.length} muscle${selectedMuscles.length == 1 ? '' : 's'} + metadata'),
                                    backgroundColor: AppColors.surfaceVariantDark,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text('AI tagging failed: ${e.toString().length > 60 ? '${e.toString().substring(0, 60)}...' : e}'),
                                    backgroundColor: AppColors.danger,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              } finally {
                                if (ctx.mounted) setSheetState(() => isTagging = false);
                              }
                            },
                            icon: isTagging
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  )
                                : const Icon(Icons.auto_awesome_rounded, size: 16),
                            label: Text(
                              isTagging ? 'Tagging...' : 'AI Auto-Tag Muscles',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        );
                      }),
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

  Future<Map<String, dynamic>?> _parseJson(String raw) async {
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }
}
