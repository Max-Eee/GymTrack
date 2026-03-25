import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../models/enums.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_providers.dart';

// ---------------------------------------------------------------------------
// Exercises Screen
// ---------------------------------------------------------------------------

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  bool _showFilters = false;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(exerciseSearchQueryProvider.notifier).state = value;
    });
  }

  int get _activeFilterCount {
    int count = 0;
    count += ref.read(exerciseFilterCategoriesProvider).length;
    count += ref.read(exerciseFilterLevelsProvider).length;
    count += ref.read(exerciseFilterEquipmentProvider).length;
    count += ref.read(exerciseFilterMusclesProvider).length;
    if (ref.read(showOnlyFavoritesProvider)) count++;
    return count;
  }

  void _clearAllFilters() {
    ref.read(exerciseFilterCategoriesProvider.notifier).state = [];
    ref.read(exerciseFilterLevelsProvider.notifier).state = [];
    ref.read(exerciseFilterEquipmentProvider.notifier).state = [];
    ref.read(exerciseFilterMusclesProvider.notifier).state = [];
    ref.read(showOnlyFavoritesProvider.notifier).state = false;
    ref.read(exerciseSearchQueryProvider.notifier).state = '';
    _searchController.clear();
  }

  void _showCreateExerciseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateExerciseSheet(
        onSave: (companion) async {
          final repo = ref.read(exerciseRepositoryProvider);
          await repo.insertExercise(companion);
          ref.invalidate(filteredExercisesProvider);
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Exercise created!'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(exerciseSearchQueryProvider);
    final selectedCategories = ref.watch(exerciseFilterCategoriesProvider);
    final selectedLevels = ref.watch(exerciseFilterLevelsProvider);
    final selectedEquipment = ref.watch(exerciseFilterEquipmentProvider);
    final selectedMuscles = ref.watch(exerciseFilterMusclesProvider);
    final showOnlyFavorites = ref.watch(showOnlyFavoritesProvider);

    final hasFilters = selectedCategories.isNotEmpty ||
        selectedLevels.isNotEmpty ||
        selectedEquipment.isNotEmpty ||
        selectedMuscles.isNotEmpty ||
        showOnlyFavorites;

    final hasSearchOrFilters = searchQuery.isNotEmpty || hasFilters;

    // Always use filteredExercisesProvider – it combines search + filters + favorites.
    final exercises = ref.watch(filteredExercisesProvider);

    if (_searchController.text != searchQuery) {
      _searchController.text = searchQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: searchQuery.length),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _showCreateExerciseSheet(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page heading
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Exercises',
                style: AppTextStyles.pageHeading.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),

            // Search bar + filter toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Expanded(child: _SearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  )),
                  const SizedBox(width: 10),
                  _FilterToggleButton(
                    isActive: _showFilters,
                    activeCount: _activeFilterCount,
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                  ),
                ],
              ),
            ),

            // Collapsible filter panel
            _FilterPanel(
              visible: _showFilters,
              selectedCategories: selectedCategories,
              selectedLevels: selectedLevels,
              selectedEquipment: selectedEquipment,
              selectedMuscles: selectedMuscles,
              showOnlyFavorites: showOnlyFavorites,
              onClearAll: hasFilters ? _clearAllFilters : null,
            ),

            // Exercise list
            Expanded(
              child: exercises.when(
                data: (list) {
                  if (list.isEmpty) {
                    return _EmptyState(hasFilters: hasSearchOrFilters);
                  }
                  return _ExerciseListView(exercises: list);
                },
                loading: () => const _ShimmerList(),
                error: (e, _) => _ErrorState(error: e),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Bar
// ---------------------------------------------------------------------------

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(exerciseSearchQueryProvider);
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search exercises...',
        hintStyle:
            const TextStyle(color: AppColors.textSecondaryDark, fontSize: 15),
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.textSecondaryDark),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon:
                    const Icon(Icons.close, color: AppColors.textSecondaryDark),
                onPressed: () {
                  controller.clear();
                  ref.read(exerciseSearchQueryProvider.notifier).state = '';
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Toggle Button
// ---------------------------------------------------------------------------

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({
    required this.isActive,
    required this.activeCount,
    required this.onPressed,
  });
  final bool isActive;
  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: isActive ? AppColors.primary : AppColors.surfaceVariantDark,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.tune_rounded,
                color: isActive
                    ? AppColors.onPrimary
                    : AppColors.textSecondaryDark,
                size: 22,
              ),
            ),
          ),
        ),
        if (activeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Panel (collapsible)
// ---------------------------------------------------------------------------

class _FilterPanel extends ConsumerWidget {
  const _FilterPanel({
    required this.visible,
    required this.selectedCategories,
    required this.selectedLevels,
    required this.selectedEquipment,
    required this.selectedMuscles,
    required this.showOnlyFavorites,
    this.onClearAll,
  });

  final bool visible;
  final List<CategoryType> selectedCategories;
  final List<LevelType> selectedLevels;
  final List<EquipmentType> selectedEquipment;
  final List<Muscle> selectedMuscles;
  final bool showOnlyFavorites;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedCrossFade(
      duration: AppDurations.medium,
      sizeCurve: Curves.easeInOut,
      crossFadeState:
          visible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      secondChild: const SizedBox.shrink(),
      firstChild: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(Icons.filter_list_rounded,
                    color: AppColors.textSecondaryDark, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (onClearAll != null)
                  GestureDetector(
                    onTap: onClearAll,
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Favorites-only toggle
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Favorites only',
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: Switch.adaptive(
                    value: showOnlyFavorites,
                    activeColor: AppColors.primary,
                    onChanged: (v) => ref
                        .read(showOnlyFavoritesProvider.notifier)
                        .state = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category
            _FilterSection<CategoryType>(
              label: 'Category',
              values: CategoryType.values,
              selected: selectedCategories,
              displayName: (v) => v.displayName,
              onChanged: (list) => ref
                  .read(exerciseFilterCategoriesProvider.notifier)
                  .state = list,
            ),
            const SizedBox(height: 10),

            // Muscle
            _FilterSection<Muscle>(
              label: 'Muscle',
              values: Muscle.values,
              selected: selectedMuscles,
              displayName: (v) => v.displayName,
              onChanged: (list) =>
                  ref.read(exerciseFilterMusclesProvider.notifier).state = list,
            ),
            const SizedBox(height: 10),

            // Level
            _FilterSection<LevelType>(
              label: 'Level',
              values: LevelType.values,
              selected: selectedLevels,
              displayName: (v) =>
                  v.name[0].toUpperCase() + v.name.substring(1),
              onChanged: (list) =>
                  ref.read(exerciseFilterLevelsProvider.notifier).state = list,
            ),
            const SizedBox(height: 10),

            // Equipment
            _FilterSection<EquipmentType>(
              label: 'Equipment',
              values: EquipmentType.values,
              selected: selectedEquipment,
              displayName: (v) => v.displayName,
              onChanged: (list) => ref
                  .read(exerciseFilterEquipmentProvider.notifier)
                  .state = list,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable filter chip section
// ---------------------------------------------------------------------------

class _FilterSection<T> extends StatelessWidget {
  const _FilterSection({
    required this.label,
    required this.values,
    required this.selected,
    required this.displayName,
    required this.onChanged,
    super.key,
  });

  final String label;
  final List<T> values;
  final List<T> selected;
  final String Function(T) displayName;
  final ValueChanged<List<T>> onChanged;

  @override
  Widget build(BuildContext context) {
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
                duration: AppDurations.short,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
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
}

// ---------------------------------------------------------------------------
// Exercise List View (lazy)
// ---------------------------------------------------------------------------

class _ExerciseListView extends ConsumerWidget {
  const _ExerciseListView({required this.exercises});
  final List<ExerciseData> exercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: exercises.length,
      itemExtent: null,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _ExerciseCard(exercise: exercise);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise Card
// ---------------------------------------------------------------------------

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.exercise});
  final ExerciseData exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isExerciseFavoriteProvider(exercise.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: AppColors.borderDark.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusMedium),
          onTap: () => _showExerciseDetail(context, exercise),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Leading avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      exercise.name.isNotEmpty
                          ? exercise.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise.category.displayName,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                      if (exercise.primaryMuscles.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: exercise.primaryMuscles
                              .take(3)
                              .map((m) => _MuscleChip(muscle: m))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite star
                    isFavorite.when(
                      data: (fav) => _FavButton(
                        isFavorite: fav,
                        onTap: () async {
                          await ref
                              .read(
                                  toggleExerciseFavoriteProvider(exercise.id))();
                        },
                      ),
                      loading: () => const SizedBox(
                        width: 32,
                        height: 32,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // Info button
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: const Icon(Icons.info_outline_rounded,
                            color: AppColors.textSecondaryDark),
                        onPressed: () =>
                            _showExerciseDetail(context, exercise),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Favorite Button
// ---------------------------------------------------------------------------

class _FavButton extends StatelessWidget {
  const _FavButton({required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFavorite ? AppColors.warning : AppColors.textSecondaryDark,
        ),
        onPressed: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Muscle Chip
// ---------------------------------------------------------------------------

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.muscle});
  final Muscle muscle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        muscle.displayName,
        style: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer / Skeleton loading
// ---------------------------------------------------------------------------

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: 12,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _shimmerBox(44, 44, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _shimmerBox(double.infinity, 14),
                      const SizedBox(height: 6),
                      _shimmerBox(80, 10),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _shimmerBox(50, 16, radius: 6),
                          const SizedBox(width: 4),
                          _shimmerBox(60, 16, radius: 6),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _shimmerBox(double w, double h, {double radius = 4}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.fitness_center_rounded,
              size: 64,
              color: AppColors.textMutedDark,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No exercises found' : 'No exercises available',
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters'
                  : 'Exercises will appear here once loaded',
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise Detail Bottom Sheet
// ---------------------------------------------------------------------------

void _showExerciseDetail(BuildContext context, ExerciseData exercise) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExerciseDetailSheet(exercise: exercise),
  );
}

class _ExerciseDetailSheet extends StatelessWidget {
  const _ExerciseDetailSheet({required this.exercise});
  final ExerciseData exercise;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondaryDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Tabs
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondaryDark,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 2.5,
                        labelStyle: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w400),
                        dividerColor: AppColors.borderDark,
                        tabs: [
                          Tab(text: 'About'),
                          Tab(text: 'History'),
                          Tab(text: 'Records'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _AboutTab(
                              exercise: exercise,
                              bottomPad: bottomPad,
                            ),
                            _PlaceholderTab(
                              icon: Icons.history_rounded,
                              label: 'No workout history yet',
                              bottomPad: bottomPad,
                            ),
                            _PlaceholderTab(
                              icon: Icons.emoji_events_outlined,
                              label: 'No records yet',
                              bottomPad: bottomPad,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// About Tab
// ---------------------------------------------------------------------------

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.exercise, required this.bottomPad});
  final ExerciseData exercise;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPad),
      children: [
        // Info chips grid
        _InfoGrid(exercise: exercise),
        const SizedBox(height: 20),

        // Instructions
        if (exercise.instructions.isNotEmpty) ...[
          const Text(
            'Instructions',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...exercise.instructions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        // Tips
        if (exercise.tips.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Tips',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...exercise.tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 10),
                    child: Icon(Icons.lightbulb_outline_rounded,
                        size: 16, color: AppColors.warning),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Info Grid (detail sheet)
// ---------------------------------------------------------------------------

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.exercise});
  final ExerciseData exercise;

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      _InfoItem(
          icon: Icons.category_rounded,
          label: 'Category',
          value: exercise.category.displayName),
      _InfoItem(
          icon: Icons.signal_cellular_alt_rounded,
          label: 'Level',
          value: exercise.level.name[0].toUpperCase() +
              exercise.level.name.substring(1)),
      if (exercise.equipment != null)
        _InfoItem(
            icon: Icons.fitness_center_rounded,
            label: 'Equipment',
            value: exercise.equipment!.displayName),
      if (exercise.force != null)
        _InfoItem(
            icon: Icons.swap_vert_rounded,
            label: 'Force',
            value: exercise.force!.name[0].toUpperCase() +
                exercise.force!.name.substring(1)),
      if (exercise.mechanic != null)
        _InfoItem(
            icon: Icons.settings_rounded,
            label: 'Mechanic',
            value: exercise.mechanic!.name[0].toUpperCase() +
                exercise.mechanic!.name.substring(1)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info chip row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => _InfoChipWidget(item: item))
              .toList(),
        ),

        // Muscles section
        if (exercise.primaryMuscles.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Primary Muscles',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: exercise.primaryMuscles
                .map((m) => _DetailMuscleChip(
                    label: m.displayName, isPrimary: true))
                .toList(),
          ),
        ],
        if (exercise.secondaryMuscles.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Secondary Muscles',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: exercise.secondaryMuscles
                .map((m) => _DetailMuscleChip(
                    label: m.displayName, isPrimary: false))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _InfoItem {
  const _InfoItem(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

class _InfoChipWidget extends StatelessWidget {
  const _InfoChipWidget({required this.item});
  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textMutedDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                item.value,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailMuscleChip extends StatelessWidget {
  const _DetailMuscleChip(
      {required this.label, required this.isPrimary});
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.surfaceVariantDark,
        borderRadius: BorderRadius.circular(8),
        border: isPrimary
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? AppColors.primary : AppColors.textSecondaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder Tab (History / Records)
// ---------------------------------------------------------------------------

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.label,
    required this.bottomPad,
  });
  final IconData icon;
  final String label;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMutedDark),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create Exercise Bottom Sheet
// ---------------------------------------------------------------------------

class _CreateExerciseSheet extends StatefulWidget {
  const _CreateExerciseSheet({required this.onSave});
  final Future<void> Function(ExercisesCompanion companion) onSave;

  @override
  State<_CreateExerciseSheet> createState() => _CreateExerciseSheetState();
}

class _CreateExerciseSheetState extends State<_CreateExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();

  CategoryType _category = CategoryType.strength;
  LevelType _level = LevelType.beginner;
  List<Muscle> _primaryMuscles = [];
  EquipmentType? _equipment;
  ForceType? _force;
  MechanicType? _mechanic;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_primaryMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one primary muscle'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final instructions = _instructionsController.text.trim();
    final companion = ExercisesCompanion.insert(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      aliases: [],
      primaryMuscles: _primaryMuscles,
      secondaryMuscles: [],
      force: drift.Value(_force),
      level: _level,
      mechanic: drift.Value(_mechanic),
      equipment: drift.Value(_equipment),
      category: _category,
      instructions: instructions.isNotEmpty ? instructions.split('\n') : [],
      description: const drift.Value(null),
      tips: [],
      image: const drift.Value(null),
    );

    try {
      await widget.onSave(companion);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Form(
          key: _formKey,
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
                'Create Exercise',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable form fields
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                  children: [
                    // Name
                    _buildLabel('Name *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                      decoration: _inputDecoration('Exercise name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Category
                    _buildLabel('Category'),
                    const SizedBox(height: 6),
                    _buildDropdown<CategoryType>(
                      value: _category,
                      items: CategoryType.values,
                      label: (e) => e.displayName,
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 16),

                    // Level
                    _buildLabel('Level'),
                    const SizedBox(height: 6),
                    _buildDropdown<LevelType>(
                      value: _level,
                      items: LevelType.values,
                      label: (e) => e.displayName,
                      onChanged: (v) => setState(() => _level = v!),
                    ),
                    const SizedBox(height: 16),

                    // Primary Muscles (multi-select chips)
                    _buildLabel('Primary Muscles *'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: Muscle.values.map((m) {
                        final selected = _primaryMuscles.contains(m);
                        return FilterChip(
                          label: Text(
                            m.displayName,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.onPrimary
                                  : AppColors.textSecondaryDark,
                              fontSize: 13,
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceVariantDark,
                          checkmarkColor: AppColors.onPrimary,
                          side: BorderSide.none,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _primaryMuscles = [..._primaryMuscles, m];
                              } else {
                                _primaryMuscles =
                                    _primaryMuscles.where((e) => e != m).toList();
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Equipment
                    _buildLabel('Equipment'),
                    const SizedBox(height: 6),
                    _buildNullableDropdown<EquipmentType>(
                      value: _equipment,
                      items: EquipmentType.values,
                      label: (e) => e.displayName,
                      onChanged: (v) => setState(() => _equipment = v),
                    ),
                    const SizedBox(height: 16),

                    // Force
                    _buildLabel('Force'),
                    const SizedBox(height: 6),
                    _buildNullableDropdown<ForceType>(
                      value: _force,
                      items: ForceType.values,
                      label: (e) => e.displayName,
                      onChanged: (v) => setState(() => _force = v),
                    ),
                    const SizedBox(height: 16),

                    // Mechanic
                    _buildLabel('Mechanic'),
                    const SizedBox(height: 6),
                    _buildNullableDropdown<MechanicType>(
                      value: _mechanic,
                      items: MechanicType.values,
                      label: (e) => e.displayName,
                      onChanged: (v) => setState(() => _mechanic = v),
                    ),
                    const SizedBox(height: 16),

                    // Instructions
                    _buildLabel('Instructions'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _instructionsController,
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                      maxLines: 4,
                      decoration: _inputDecoration('One instruction per line'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Save button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Text(
                            'Save Exercise',
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
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMutedDark),
      filled: true,
      fillColor: AppColors.surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: AppColors.surfaceVariantDark,
      style: const TextStyle(color: AppColors.textPrimaryDark),
      decoration: _inputDecoration(''),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(label(e))))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNullableDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: AppColors.surfaceVariantDark,
      style: const TextStyle(color: AppColors.textPrimaryDark),
      decoration: _inputDecoration(''),
      items: [
        DropdownMenuItem<T>(value: null, child: Text('None')),
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(label(e)))),
      ],
      onChanged: onChanged,
    );
  }
}
