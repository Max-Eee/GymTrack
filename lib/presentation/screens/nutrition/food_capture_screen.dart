import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../models/enums.dart';
import '../../../services/nutrition_service.dart';
import '../../providers/nutrition_providers.dart';

class FoodCaptureScreen extends ConsumerStatefulWidget {
  final File imageFile;
  
  const FoodCaptureScreen({super.key, required this.imageFile});

  @override
  ConsumerState<FoodCaptureScreen> createState() => _FoodCaptureScreenState();
}

class _FoodCaptureScreenState extends ConsumerState<FoodCaptureScreen>
    with TickerProviderStateMixin {
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  FoodAnalysisResult? _result;
  String? _error;

  // Animation controllers
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _resultSlideController;
  late Animation<double> _resultSlideAnimation;

  // Editable fields
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _servingSizeController = TextEditingController();
  MealType _selectedMealType = _inferMealType();

  static MealType _inferMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return MealType.breakfast;
    if (hour < 15) return MealType.lunch;
    if (hour < 20) return MealType.dinner;
    return MealType.snack;
  }

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _resultSlideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultSlideAnimation = CurvedAnimation(
      parent: _resultSlideController,
      curve: Curves.easeOutCubic,
    );

    _loadImageAndAnalyze();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _resultSlideController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  Future<void> _loadImageAndAnalyze() async {
    final bytes = await widget.imageFile.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
    _analyzeImage(bytes);
  }

  Future<void> _analyzeImage(Uint8List bytes) async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
    });
    _scanController.repeat();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();

    try {
      final service = ref.read(nutritionServiceProvider);
      final result = await service.analyzeFood(bytes);

      if (!mounted) return;

      _scanController.stop();
      _pulseController.stop();
      _shimmerController.stop();

      if (result == null) {
        setState(() {
          _isAnalyzing = false;
          _error = 'Could not analyze the food. Please try again.';
        });
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _result = result;
        _nameController.text = result.name;
        _caloriesController.text = result.calories.toStringAsFixed(0);
        _proteinController.text = result.proteinG.toStringAsFixed(1);
        _carbsController.text = result.carbsG.toStringAsFixed(1);
        _fatController.text = result.fatG.toStringAsFixed(1);
        _fiberController.text = result.fiberG.toStringAsFixed(1);
        _servingSizeController.text = result.servingSize;
      });

      _resultSlideController.forward();
    } on PlatformException catch (e) {
      if (!mounted) return;
      _scanController.stop();
      _pulseController.stop();
      _shimmerController.stop();
      String errorMessage;
      if (e.code == 'NOT_LOADED' || e.code == 'NOT_ACTIVE') {
        errorMessage = 'AI model not loaded. Please activate a model in Settings.';
      } else if (e.code == 'LOAD_FAILED') {
        errorMessage = 'Failed to load AI model. Try a smaller model or restart the app.';
      } else if (e.code == 'GENERATION_TIMEOUT') {
        errorMessage = 'Analysis timed out. The model may need a moment to warm up — try again.';
      } else {
        errorMessage = e.message ?? 'An error occurred during analysis';
      }
      setState(() {
        _isAnalyzing = false;
        _error = errorMessage;
      });
    } catch (e) {
      if (!mounted) return;
      _scanController.stop();
      _pulseController.stop();
      _shimmerController.stop();
      setState(() {
        _isAnalyzing = false;
        _error = 'Analysis failed: $e';
      });
    }
  }

  Future<void> _logFood() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final entry = FoodLogsCompanion(
      id: Value(const Uuid().v4()),
      name: Value(name),
      calories: Value(double.tryParse(_caloriesController.text) ?? 0),
      proteinG: Value(double.tryParse(_proteinController.text) ?? 0),
      carbsG: Value(double.tryParse(_carbsController.text) ?? 0),
      fatG: Value(double.tryParse(_fatController.text) ?? 0),
      fiberG: Value(double.tryParse(_fiberController.text) ?? 0),
      servingSize: Value(_servingSizeController.text.trim()),
      imagePath: const Value(null),
      loggedAt: Value(DateTime.now()),
      mealType: Value(_selectedMealType),
    );

    await ref.read(foodLogRepositoryProvider).insertFoodLog(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background: blurred image
          if (_imageBytes != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0F).withOpacity(0.6),
                    const Color(0xFF0A0A0F).withOpacity(0.92),
                    const Color(0xFF0A0A0F),
                  ],
                  stops: const [0.0, 0.5, 0.8],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isAnalyzing
                      ? _buildScanningView()
                      : _error != null
                          ? _buildErrorView()
                          : _result != null
                              ? _buildResultView()
                              : const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isAnalyzing
                ? 'Scanning...'
                : _result != null
                    ? 'Results'
                    : 'Food Scanner',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── SCANNING VIEW ─────────────────────────────────────────────
  Widget _buildScanningView() {
    final screenSize = MediaQuery.of(context).size;
    return Stack(
      children: [
        // Full-screen image
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([_scanController, _pulseController]),
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full-screen food image
                  Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                  ),
                  // Dark vignette overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Bottom gradient for text
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: screenSize.height * 0.35,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Shimmer overlay
                  Positioned.fill(
                    child: _buildShimmerOverlay(),
                  ),
                ],
              );
            },
          ),
        ),
        // Status text at bottom
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: _buildScanStatus(),
        ),
      ],
    );
  }

  Widget _buildShimmerOverlay() {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerController, _pulseController]),
      builder: (context, _) {
        final value = _shimmerController.value;
        final pulse = _pulseController.value;
        final angle = value * 2 * math.pi;
        return IgnorePointer(
          child: Stack(
            children: [
              // Purple plasma sweep
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.cos(angle) * 0.6,
                      math.sin(angle * 0.7) * 0.4,
                    ),
                    radius: 1.2 + pulse * 0.3,
                    colors: [
                      AppColors.aiPurple.withOpacity(0.18 + pulse * 0.08),
                      AppColors.aiPurple.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              // Blue sweep (offset phase)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(angle * 1.3 + 2.0) * 0.5,
                      math.cos(angle * 0.9 + 1.0) * 0.5,
                    ),
                    radius: 1.0 + pulse * 0.2,
                    colors: [
                      AppColors.aiBlue.withOpacity(0.14 + pulse * 0.06),
                      AppColors.aiBlue.withOpacity(0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
              // Subtle diagonal light sweep
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.06 + pulse * 0.03),
                      Colors.transparent,
                    ],
                    stops: [
                      (value - 0.2).clamp(0.0, 1.0),
                      value,
                      (value + 0.2).clamp(0.0, 1.0),
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

  Widget _buildScanStatus() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.aiPurple.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: AppColors.aiPurple, size: 18),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.aiPurple, AppColors.aiBlue],
                ).createShader(bounds),
                child: const Text(
                  'Analyzing your food...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Identifying nutrients and portions',
          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }

  // ── ERROR VIEW ────────────────────────────────────────────────
  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // Image preview
          if (_imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(_imageBytes!, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 36),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _analyzeImage(_imageBytes!),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Retry Analysis',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── RESULT VIEW ───────────────────────────────────────────────
  Widget _buildResultView() {
    return FadeTransition(
      opacity: _resultSlideAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_resultSlideAnimation),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFoodHeader(),
                    const SizedBox(height: 20),
                    _buildMacroCards(),
                    const SizedBox(height: 20),
                    _buildEditableDetails(),
                    const SizedBox(height: 16),
                    _buildMealTypeChips(),
                  ],
                ),
              ),
            ),
            // Pinned Log Food button at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _buildLogButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodHeader() {
    return Row(
      children: [
        // Compact image preview
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _imageBytes != null
              ? Image.memory(_imageBytes!, width: 80, height: 80, fit: BoxFit.cover)
              : Container(width: 80, height: 80, color: Colors.grey.shade900),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            _nameController.text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCards() {
    final calories = double.tryParse(_caloriesController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    final fiber = double.tryParse(_fiberController.text) ?? 0;

    return Column(
      children: [
        // Calories hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.15),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${calories.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'calories',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Mini macro bars
              _buildMiniBar('P', protein, AppColors.secondary),
              const SizedBox(width: 12),
              _buildMiniBar('C', carbs, AppColors.primary),
              const SizedBox(width: 12),
              _buildMiniBar('F', fat, const Color(0xFFFF9500)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Macro detail row
        Row(
          children: [
            _buildMacroTile('Protein', protein, 'g', AppColors.secondary),
            const SizedBox(width: 10),
            _buildMacroTile('Carbs', carbs, 'g', AppColors.primary),
            const SizedBox(width: 10),
            _buildMacroTile('Fat', fat, 'g', const Color(0xFFFF9500)),
            const SizedBox(width: 10),
            _buildMacroTile('Fiber', fiber, 'g', AppColors.success),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniBar(String label, double value, Color color) {
    final maxValue = 100.0;
    final fraction = (value / maxValue).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 6,
          height: 40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(color: color.withOpacity(0.15)),
                FractionallySizedBox(
                  heightFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildMacroTile(
      String label, double value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(unit,
                    style:
                        TextStyle(fontSize: 11, color: color.withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_outlined,
                  size: 14, color: Colors.white.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text('Edit Details',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          _buildInputRow('Name', _nameController, TextInputType.text),
          _buildInputRow('Calories', _caloriesController,
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'kcal'),
          _buildInputRow('Protein', _proteinController,
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'g'),
          _buildInputRow('Carbs', _carbsController,
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'g'),
          _buildInputRow('Fat', _fatController,
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'g'),
          _buildInputRow('Fiber', _fiberController,
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'g', isLast: true),
        ],
      ),
    );
  }

  Widget _buildInputRow(
      String label, TextEditingController controller, TextInputType type,
      {String? suffix, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: type,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                suffixText: suffix,
                suffixStyle:
                    TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppColors.primary.withOpacity(0.5)),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeChips() {
    return Row(
      children: MealType.values.map((type) {
        final isSelected = _selectedMealType == type;
        final label = switch (type) {
          MealType.breakfast => 'Breakfast',
          MealType.lunch => 'Lunch',
          MealType.dinner => 'Dinner',
          MealType.snack => 'Snack',
        };
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMealType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.4)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _logFood,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('Log Food',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Corner Bracket Painter ──────────────────────────────────────
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _CornerBracketPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const m = 4.0;
    const l = 30.0;

    // Top-left
    canvas.drawLine(Offset(m, m + l), Offset(m, m), paint);
    canvas.drawLine(Offset(m, m), Offset(m + l, m), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - m - l, m), Offset(size.width - m, m), paint);
    canvas.drawLine(Offset(size.width - m, m), Offset(size.width - m, m + l), paint);
    // Bottom-left
    canvas.drawLine(Offset(m, size.height - m - l), Offset(m, size.height - m), paint);
    canvas.drawLine(Offset(m, size.height - m), Offset(m + l, size.height - m), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - m - l, size.height - m), Offset(size.width - m, size.height - m), paint);
    canvas.drawLine(Offset(size.width - m, size.height - m - l), Offset(size.width - m, size.height - m), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
