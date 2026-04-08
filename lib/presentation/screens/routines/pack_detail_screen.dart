import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/preset_pack_service.dart';
import '../../../models/preset_pack.dart';
import '../../providers/app_providers.dart';

class PackDetailScreen extends ConsumerStatefulWidget {
  final PresetPack pack;
  const PackDetailScreen({super.key, required this.pack});

  @override
  ConsumerState<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends ConsumerState<PackDetailScreen> {
  Set<String> _existingNames = {};
  Set<String> _addedThisSession = {};
  bool _loading = true;
  bool _addingAll = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final service = _getService();
    final existing = await service.getExistingRoutineNames(widget.pack);
    if (mounted) {
      setState(() {
        _existingNames = existing;
        _loading = false;
      });
    }
  }

  PresetPackService _getService() {
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final exerciseRepo = ref.read(exerciseRepositoryProvider);
    return PresetPackService(workoutRepo, exerciseRepo);
  }

  bool _isAdded(String name) =>
      _existingNames.contains(name) || _addedThisSession.contains(name);

  int get _addableCount => widget.pack.routines
      .where((r) => !_isAdded(r.name))
      .length;

  Future<void> _addAll() async {
    setState(() => _addingAll = true);
    final service = _getService();
    final added = await service.addPack(widget.pack);
    if (mounted) {
      setState(() {
        _addingAll = false;
        _addedThisSession = widget.pack.routines.map((r) => r.name).toSet();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $added routine${added == 1 ? '' : 's'}'),
          backgroundColor: AppColors.surfaceVariantDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addSingle(PresetRoutine routine) async {
    final service = _getService();
    final success = await service.addSingleRoutine(routine);
    if (mounted) {
      if (success) {
        setState(() => _addedThisSession.add(routine.name));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${routine.name}" to your routines'),
            backgroundColor: AppColors.surfaceVariantDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${routine.name}" already exists'),
            backgroundColor: AppColors.surfaceVariantDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: AppColors.surfaceDark,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 160,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryDark),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
              title: Text(
                widget.pack.name,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.pack.color.withOpacity(0.2),
                      AppColors.surfaceDark,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.pack.icon,
                    size: 64,
                    color: widget.pack.color.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Description + Add All button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pack.description,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: widget.pack.color),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.pack.routines.length} routines',
                        style: TextStyle(
                          color: widget.pack.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.fitness_center_rounded,
                          size: 14, color: widget.pack.color),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.pack.totalExercises} exercises',
                        style: TextStyle(
                          color: widget.pack.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Add All button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading || _addingAll || _addableCount == 0
                          ? null
                          : _addAll,
                      style: FilledButton.styleFrom(
                        backgroundColor: _addableCount == 0
                            ? AppColors.surfaceVariantDark
                            : AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _addingAll
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Icon(
                              _addableCount == 0
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                            ),
                      label: Text(
                        _addableCount == 0
                            ? 'All Routines Added'
                            : 'Add All ${widget.pack.routines.length} Routines',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'ROUTINES',
                    style: TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Routine list
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final routine = widget.pack.routines[index];
                    return _RoutineCard(
                      routine: routine,
                      packColor: widget.pack.color,
                      isAdded: _isAdded(routine.name),
                      onAdd: () => _addSingle(routine),
                    );
                  },
                  childCount: widget.pack.routines.length,
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatefulWidget {
  final PresetRoutine routine;
  final Color packColor;
  final bool isAdded;
  final VoidCallback onAdd;

  const _RoutineCard({
    required this.routine,
    required this.packColor,
    required this.isAdded,
    required this.onAdd,
  });

  @override
  State<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<_RoutineCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isAdded
                ? AppColors.success.withOpacity(0.3)
                : AppColors.borderDark,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Routine name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.routine.name,
                            style: const TextStyle(
                              color: AppColors.textPrimaryDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.routine.exercises.length} exercises · ${widget.routine.totalSets} sets',
                            style: const TextStyle(
                              color: AppColors.textMutedDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add button
                    if (widget.isAdded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 16, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              'Added',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      FilledButton.tonal(
                        onPressed: widget.onAdd,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              widget.packColor.withOpacity(0.15),
                          foregroundColor: widget.packColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textMutedDark,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            // Exercise list (expanded)
            if (_expanded)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Column(
                  children: [
                    const Divider(
                        color: AppColors.borderDark, height: 1, thickness: 1),
                    const SizedBox(height: 8),
                    ...widget.routine.exercises.asMap().entries.map(
                      (entry) {
                        final i = entry.key;
                        final ex = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${i + 1}.',
                                  style: const TextStyle(
                                    color: AppColors.textMutedDark,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  ex.exerciseName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimaryDark,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                ex.durationSeconds != null
                                    ? '${ex.sets} × ${ex.durationSeconds}s'
                                    : '${ex.sets} × ${ex.reps}',
                                style: TextStyle(
                                  color: widget.packColor.withOpacity(0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
