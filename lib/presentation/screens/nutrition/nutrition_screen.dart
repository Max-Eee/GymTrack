import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../../widgets/animated_ai_gradient.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../models/enums.dart';
import '../../../services/gemma_model_service.dart';
import '../../providers/nutrition_providers.dart';
import 'food_capture_screen.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final foodLogs = ref.watch(foodLogsByDateProvider(selectedDate));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - consistent with Exercises page
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nutrition',
                      style: AppTextStyles.pageHeading.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDatePicker(context, ref, selectedDate),
                    icon: const Icon(Icons.calendar_today, color: AppColors.textSecondaryDark, size: 22),
                  ),
                ],
              ),
            ),

            // Date selector
            _DateSelector(
              selectedDate: selectedDate,
              onDateChanged: (date) => ref.read(selectedDateProvider.notifier).state = date,
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: foodLogs.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return _buildContent(context, ref, logs);
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: AnimatedAiGradient(
          width: 56,
          height: 56,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showImageSourceDialog(context, ref),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
              child: const Center(
                child: Icon(Icons.camera_alt, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_outlined, size: 80, color: AppColors.textMutedDark.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No meals logged',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Snap a photo of your food to get started',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<FoodLogData> logs) {
    final totalCalories = logs.fold(0.0, (sum, l) => sum + l.calories);
    final totalProtein = logs.fold(0.0, (sum, l) => sum + l.proteinG);
    final totalCarbs = logs.fold(0.0, (sum, l) => sum + l.carbsG);
    final totalFat = logs.fold(0.0, (sum, l) => sum + l.fatG);

    // Group by meal type
    final grouped = <MealType, List<FoodLogData>>{};
    for (final log in logs) {
      grouped.putIfAbsent(log.mealType, () => []).add(log);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          _SummaryCard(
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
          ),
          const SizedBox(height: 20),

          // Meal sections
          for (final mealType in MealType.values)
            if (grouped.containsKey(mealType))
              _MealSection(
                mealType: mealType,
                logs: grouped[mealType]!,
                onDelete: (id) => ref.read(foodLogRepositoryProvider).deleteFoodLog(id),
              ),

          const SizedBox(height: 100), // floating navbar clearance
        ],
      ),
    );
  }

  void _showDatePicker(BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }

  Future<void> _showImageSourceDialog(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Food Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take Photo', style: TextStyle(color: AppColors.textPrimaryDark)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.secondary),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimaryDark)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    // Free model from GPU memory before opening camera to prevent OOM kill
    try {
      final gemmaService = ref.read(gemmaModelServiceProvider);
      await gemmaService.freeModel();
    } catch (_) {}

    final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked == null) return;

    final file = File(picked.path);
    
    // Navigate to food capture screen only after image is picked
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodCaptureScreen(imageFile: file),
      ),
    );
  }
}

// ── Date Selector ──────────────────────────────────────────────────────────

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector({required this.selectedDate, required this.onDateChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate.year == today.year && selectedDate.month == today.month && selectedDate.day == today.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => onDateChanged(selectedDate.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left, color: AppColors.textSecondaryDark),
            iconSize: 28,
          ),
          Text(
            isToday ? 'Today' : DateFormat('MMM d, yyyy').format(selectedDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
          IconButton(
            onPressed: isToday ? null : () => onDateChanged(selectedDate.add(const Duration(days: 1))),
            icon: Icon(Icons.chevron_right, color: isToday ? AppColors.textMutedDark : AppColors.textSecondaryDark),
            iconSize: 28,
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const _SummaryCard({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          // Total calories
          Text(
            totalCalories.toStringAsFixed(0),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary, height: 1),
          ),
          const SizedBox(height: 4),
          const Text('calories', style: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark)),
          const SizedBox(height: 20),

          // Macro bars
          Row(
            children: [
              _MacroBar(label: 'Protein', grams: totalProtein, color: AppColors.secondary),
              const SizedBox(width: 12),
              _MacroBar(label: 'Carbs', grams: totalCarbs, color: AppColors.primary),
              const SizedBox(width: 12),
              _MacroBar(label: 'Fat', grams: totalFat, color: AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;

  const _MacroBar({required this.label, required this.grams, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${grams.toStringAsFixed(1)}g',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
        ],
      ),
    );
  }
}

// ── Meal Section ───────────────────────────────────────────────────────────

class _MealSection extends ConsumerWidget {
  final MealType mealType;
  final List<FoodLogData> logs;
  final ValueChanged<String> onDelete;

  const _MealSection({required this.mealType, required this.logs, required this.onDelete});

  String get _mealLabel {
    switch (mealType) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.dinner: return 'Dinner';
      case MealType.snack: return 'Snacks';
    }
  }

  IconData get _mealIcon {
    switch (mealType) {
      case MealType.breakfast: return Icons.wb_sunny_outlined;
      case MealType.lunch: return Icons.wb_cloudy_outlined;
      case MealType.dinner: return Icons.nightlight_outlined;
      case MealType.snack: return Icons.cookie_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionCalories = logs.fold(0.0, (sum, l) => sum + l.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(_mealIcon, color: AppColors.textSecondaryDark, size: 20),
            const SizedBox(width: 8),
            Text(
              _mealLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
            ),
            const Spacer(),
            Text(
              '${sectionCalories.toStringAsFixed(0)} cal',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Food cards
        ...logs.map((log) => _FoodLogCard(
          log: log,
          onDelete: () => onDelete(log.id),
          onEdit: () => _showEditDialog(context, ref, log),
        )),

        const SizedBox(height: 16),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, FoodLogData log) {
    showDialog(
      context: context,
      builder: (ctx) => _EditFoodDialog(log: log, ref: ref),
    );
  }
}

// ── Food Log Card ──────────────────────────────────────────────────────────

class _FoodLogCard extends StatelessWidget {
  final FoodLogData log;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _FoodLogCard({required this.log, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              // Food image or icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant, color: AppColors.textMutedDark),
              ),
              const SizedBox(width: 12),

              // Name + macros
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P ${log.proteinG.toStringAsFixed(0)}g  C ${log.carbsG.toStringAsFixed(0)}g  F ${log.fatG.toStringAsFixed(0)}g',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),

              // Calories
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${log.calories.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const Text('cal', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit Food Dialog ───────────────────────────────────────────────────────

class _EditFoodDialog extends StatefulWidget {
  final FoodLogData log;
  final WidgetRef ref;

  const _EditFoodDialog({required this.log, required this.ref});

  @override
  State<_EditFoodDialog> createState() => _EditFoodDialogState();
}

class _EditFoodDialogState extends State<_EditFoodDialog> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;
  late TextEditingController _servingSizeController;
  late MealType _selectedMealType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.log.name);
    _caloriesController = TextEditingController(text: widget.log.calories.toStringAsFixed(0));
    _proteinController = TextEditingController(text: widget.log.proteinG.toStringAsFixed(1));
    _carbsController = TextEditingController(text: widget.log.carbsG.toStringAsFixed(1));
    _fatController = TextEditingController(text: widget.log.fatG.toStringAsFixed(1));
    _fiberController = TextEditingController(text: (widget.log.fiberG ?? 0).toStringAsFixed(1));
    _servingSizeController = TextEditingController(text: widget.log.servingSize);
    _selectedMealType = widget.log.mealType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final entry = FoodLogsCompanion(
      id: Value(widget.log.id),
      name: Value(_nameController.text.trim()),
      calories: Value(double.tryParse(_caloriesController.text) ?? 0),
      proteinG: Value(double.tryParse(_proteinController.text) ?? 0),
      carbsG: Value(double.tryParse(_carbsController.text) ?? 0),
      fatG: Value(double.tryParse(_fatController.text) ?? 0),
      fiberG: Value(double.tryParse(_fiberController.text) ?? 0),
      servingSize: Value(_servingSizeController.text.trim()),
      imagePath: Value(widget.log.imagePath),
      loggedAt: Value(widget.log.loggedAt),
      mealType: Value(_selectedMealType),
    );

    await widget.ref.read(foodLogRepositoryProvider).updateFoodLog(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Food Log', style: TextStyle(color: AppColors.textPrimaryDark)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField('Food Name', _nameController),
            const SizedBox(height: 12),
            _buildField('Serving Size', _servingSizeController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField('Calories', _caloriesController, isNumber: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildField('Protein (g)', _proteinController, isNumber: true)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField('Carbs (g)', _carbsController, isNumber: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildField('Fat (g)', _fatController, isNumber: true)),
              ],
            ),
            const SizedBox(height: 10),
            _buildField('Fiber (g)', _fiberController, isNumber: true),
            const SizedBox(height: 16),
            // Meal type selector
            DropdownButtonFormField<MealType>(
              value: _selectedMealType,
              dropdownColor: AppColors.surfaceDark,
              decoration: InputDecoration(
                labelText: 'Meal Type',
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: MealType.values.map((type) {
                final label = switch (type) {
                  MealType.breakfast => 'Breakfast',
                  MealType.lunch => 'Lunch',
                  MealType.dinner => 'Dinner',
                  MealType.snack => 'Snack',
                };
                return DropdownMenuItem(
                  value: type,
                  child: Text(label, style: const TextStyle(color: AppColors.textPrimaryDark)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedMealType = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }
}
