import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/enums.dart';
import '../../providers/app_providers.dart';
import '../../providers/user_providers.dart';
import '../../../data/database/app_database.dart';
import '../../../services/backup_service.dart';

import '../settings/model_settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _ageController;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _initControllers(UserInfoData? info) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    _heightController.text = info?.height?.toString() ?? '';
    _weightController.text = info?.weight?.toString() ?? '';
    _ageController.text = info?.age?.toString() ?? '';
  }

  String _calculateBMI() {
    final weight = double.tryParse(_weightController.text);
    final heightCm = double.tryParse(_heightController.text);
    if (weight == null || heightCm == null || heightCm <= 0) return '--';
    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }

  Future<void> _saveMeasurements() async {
    final userRepo = ref.read(userRepositoryProvider);
    final existing = await userRepo.getUserInfo();
    await userRepo.insertOrUpdateUserInfo(
      UserInfosCompanion.insert(
        id: 'user-1',
        name: drift.Value(existing?.name ?? ''),
        avatarPath: drift.Value(existing?.avatarPath ?? ''),
        age: drift.Value(int.tryParse(_ageController.text)),
        height: drift.Value(double.tryParse(_heightController.text)),
        weight: drift.Value(double.tryParse(_weightController.text)),
      ),
    );
  }

  Future<void> _editName(UserInfoData? info) async {
    final controller = TextEditingController(text: info?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Name',
            style: TextStyle(color: AppColors.textPrimaryDark)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimaryDark),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: AppColors.textMutedDark),
            filled: true,
            fillColor: AppColors.surfaceVariantDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;

    final userRepo = ref.read(userRepositoryProvider);
    await userRepo.insertOrUpdateUserInfo(
      UserInfosCompanion.insert(
        id: 'user-1',
        name: drift.Value(result),
        avatarPath: drift.Value(info?.avatarPath ?? ''),
        age: drift.Value(info?.age),
        height: drift.Value(info?.height),
        weight: drift.Value(info?.weight),
      ),
    );
  }

  Future<void> _pickAvatar(UserInfoData? info) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Change Profile Photo',
                  style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Take Photo',
                    style: TextStyle(color: AppColors.textPrimaryDark)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.secondary),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(color: AppColors.textPrimaryDark)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (info?.avatarPath != null && info!.avatarPath.isNotEmpty)
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: AppColors.danger),
                  ),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: AppColors.danger)),
                  onTap: () => Navigator.pop(ctx, null),
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null && !(info?.avatarPath != null && info!.avatarPath.isNotEmpty)) return;

    String newPath = '';
    if (source != null) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final savedPath = p.join(appDir.path, 'profile_avatar.jpg');
      await File(picked.path).copy(savedPath);
      newPath = savedPath;
    }

    final userRepo = ref.read(userRepositoryProvider);
    await userRepo.insertOrUpdateUserInfo(
      UserInfosCompanion.insert(
        id: 'user-1',
        name: drift.Value(info?.name ?? ''),
        avatarPath: drift.Value(newPath),
        age: drift.Value(info?.age),
        height: drift.Value(info?.height),
        weight: drift.Value(info?.weight),
      ),
    );
  }

  Future<void> _toggleEquipment(
    EquipmentType type,
    bool selected,
    List<UserEquipmentData> currentEquipment,
  ) async {
    final userRepo = ref.read(userRepositoryProvider);
    final currentTypes = currentEquipment.map((e) => e.equipmentType).toList();
    if (selected) {
      currentTypes.add(type);
    } else {
      currentTypes.remove(type);
    }
    await userRepo.setUserEquipment(currentTypes);
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);
    final userEquipment = ref.watch(userEquipmentProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: userInfo.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Failed to load profile',
                  style: TextStyle(color: AppColors.textSecondaryDark),
                ),
              ],
            ),
          ),
          data: (info) {
            _initControllers(info);
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  _buildHeroSection(info),
                  const SizedBox(height: 28),
                  _buildStatsRow(info),
                  const SizedBox(height: 28),
                  _buildMeasurementsCard(info),
                  const SizedBox(height: 20),
                  _buildEquipmentCard(userEquipment),
                  const SizedBox(height: 20),
                  _buildModelSettingsCard(),
                  const SizedBox(height: 20),
                  _buildBackupCard(),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Hero Section ─────────────────────────────────────────────────────
  Widget _buildHeroSection(UserInfoData? info) {
    final hasAvatar = info != null && info.avatarPath.isNotEmpty && File(info.avatarPath).existsSync();
    final displayName = (info != null && info.name.isNotEmpty) ? info.name : 'GymTrack User';

    return Column(
      children: [
        // Avatar with edit overlay
        GestureDetector(
          onTap: () => _pickAvatar(info),
          child: Stack(
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  color: AppColors.surfaceDark,
                  image: hasAvatar
                      ? DecorationImage(
                          image: FileImage(File(info.avatarPath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasAvatar
                    ? null
                    : const Icon(
                        Icons.person_rounded,
                        size: 80,
                        color: AppColors.primary,
                      ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.backgroundDark, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Editable name
        GestureDetector(
          onTap: () => _editName(info),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.edit_rounded,
                size: 18,
                color: AppColors.textMutedDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────
  Widget _buildStatsRow(UserInfoData? info) {
    final bmiStr = _calculateBMI();
    final bmi = double.tryParse(bmiStr);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Column(
        children: [
          // Top: Weight · Height · Age
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Row(
              children: [
                _buildStatItem(
                  value: info?.weight?.toStringAsFixed(1) ?? '--',
                  unit: 'kg',
                  label: 'Weight',
                ),
                _buildStatDivider(),
                _buildStatItem(
                  value: info?.height?.toStringAsFixed(0) ?? '--',
                  unit: 'cm',
                  label: 'Height',
                ),
                _buildStatDivider(),
                _buildStatItem(
                  value: info?.age?.toString() ?? '--',
                  unit: 'y.o',
                  label: 'Age',
                ),
              ],
            ),
          ),
          // BMI insight card
          if (bmi != null) _buildBmiInsight(bmi, info?.weight),
        ],
      ),
    );
  }

  Widget _buildBmiInsight(double bmi, double? currentWeight) {
    final category = _bmiCategory(bmi);
    final color = _bmiColor(bmi);
    final icon = _bmiIcon(bmi);
    final heightM = (double.tryParse(_heightController.text) ?? 0) / 100;
    final advice = _bmiAdvice(bmi, currentWeight, heightM);

    // BMI bar position (range 15-40 mapped to 0.0-1.0)
    final barFraction = ((bmi - 15) / 25).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          // BMI score circle + info
          Row(
            children: [
              // BMI display
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(color: color.withOpacity(0.4), width: 2.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'BMI',
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Category + icon
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 18),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (advice.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        advice,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Modern segmented gauge bar
          Column(
            children: [
              // Gauge with rounded segments
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 14,
                            child: Container(
                              margin: const EdgeInsets.only(right: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF60A5FA).withOpacity(0.35),
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 26,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              color: AppColors.success.withOpacity(0.35),
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              color: const Color(0xFFFBBF24).withOpacity(0.35),
                            ),
                          ),
                          Expanded(
                            flex: 40,
                            child: Container(
                              margin: const EdgeInsets.only(left: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.35),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Active fill up to indicator
                      FractionallySizedBox(
                        widthFactor: barFraction,
                        child: Row(
                          children: [
                            if (barFraction <= 0.14)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF60A5FA),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                                  ),
                                ),
                              )
                            else if (barFraction <= 0.40)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF60A5FA), Color(0xFF4ADE80)],
                                    ),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                                  ),
                                ),
                              )
                            else if (barFraction <= 0.60)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF60A5FA), Color(0xFF4ADE80), Color(0xFFFBBF24)],
                                    ),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFF60A5FA), AppColors.success, const Color(0xFFFBBF24), AppColors.danger],
                                    ),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Position indicator (triangle/diamond)
                      FractionallySizedBox(
                        widthFactor: barFraction,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surfaceDark, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Range labels
              Row(
                children: [
                  _buildRangeLabel('Under', '< 18.5', const Color(0xFF60A5FA)),
                  _buildRangeLabel('Normal', '18.5-25', AppColors.success),
                  _buildRangeLabel('Over', '25-30', const Color(0xFFFBBF24)),
                  _buildRangeLabel('Obese', '30+', AppColors.danger),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeLabel(String label, String range, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            range,
            style: TextStyle(
              color: AppColors.textMutedDark,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF60A5FA); // blue
    if (bmi < 25) return AppColors.success;          // green
    if (bmi < 30) return const Color(0xFFFBBF24);    // amber
    return AppColors.danger;                          // red
  }

  IconData _bmiIcon(double bmi) {
    if (bmi < 18.5) return Icons.trending_up_rounded;
    if (bmi < 25) return Icons.check_circle_rounded;
    if (bmi < 30) return Icons.warning_amber_rounded;
    return Icons.error_outline_rounded;
  }

  String _bmiAdvice(double bmi, double? currentWeight, double heightM) {
    if (heightM <= 0 || currentWeight == null) return '';

    if (bmi < 18.5) {
      final targetWeight = 18.5 * heightM * heightM;
      final diff = (targetWeight - currentWeight).abs();
      return 'You need to gain ~${diff.toStringAsFixed(1)} kg to reach a healthy BMI.';
    } else if (bmi < 25) {
      return 'Great job! You\'re at a healthy weight. Keep it up!';
    } else if (bmi < 30) {
      final targetWeight = 24.9 * heightM * heightM;
      final diff = (currentWeight - targetWeight).abs();
      return 'Losing ~${diff.toStringAsFixed(1)} kg would bring you to a healthy BMI.';
    } else {
      final targetWeight = 24.9 * heightM * heightM;
      final diff = (currentWeight - targetWeight).abs();
      return 'Losing ~${diff.toStringAsFixed(1)} kg would bring you to a healthy BMI range.';
    }
  }

  Widget _buildStatItem({
    required String value,
    required String unit,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.surfaceVariantDark,
    );
  }

  // ─── Measurements Card ────────────────────────────────────────────────
  Widget _buildMeasurementsCard(UserInfoData? info) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: AppColors.surfaceVariantDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.monitor_weight_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Measurements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.surfaceVariantDark),
          // Form Fields
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInputField(
                  controller: _heightController,
                  label: 'Height',
                  suffix: 'cm',
                  icon: Icons.height_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _weightController,
                  label: 'Weight',
                  suffix: 'kg',
                  icon: Icons.fitness_center_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _ageController,
                  label: 'Age',
                  suffix: 'years',
                  icon: Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    TextEditingController? controller,
    required String label,
    required String suffix,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? value,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onChanged: (_) {
        setState(() {}); // Refresh BMI
        _saveMeasurements();
      },
      style: const TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondaryDark),
        hintText: readOnly ? value : 'Enter $label',
        hintStyle: TextStyle(
          color: readOnly ? AppColors.primary : AppColors.textSecondaryDark.withOpacity(0.5),
          fontWeight: readOnly ? FontWeight.w700 : FontWeight.normal,
        ),
        suffixText: suffix.isNotEmpty ? suffix : null,
        suffixStyle: TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondaryDark, size: 20),
        filled: true,
        fillColor: AppColors.surfaceVariantDark.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.surfaceVariantDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ─── Equipment Card ───────────────────────────────────────────────────
  Widget _buildEquipmentCard(AsyncValue<List<UserEquipmentData>> userEquipment) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: AppColors.surfaceVariantDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select the equipment you have access to',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.surfaceVariantDark),
          // Equipment dropdown selector
          userEquipment.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Failed to load equipment',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
            data: (equipment) {
              final selectedTypes = equipment.map((e) => e.equipmentType).toSet();
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown trigger
                    InkWell(
                      onTap: () => _showEquipmentPicker(selectedTypes, equipment),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariantDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surfaceVariantDark),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: AppColors.textSecondaryDark, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedTypes.isEmpty
                                    ? 'Tap to select equipment'
                                    : '${selectedTypes.length} equipment selected',
                                style: TextStyle(
                                  color: selectedTypes.isEmpty
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textPrimaryDark,
                                  fontSize: 14,
                                  fontWeight: selectedTypes.isEmpty ? FontWeight.w400 : FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondaryDark, size: 22),
                          ],
                        ),
                      ),
                    ),
                    // Selected chips
                    if (selectedTypes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedTypes.map((type) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_equipmentIcon(type), size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  type.displayName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _toggleEquipment(type, false, equipment),
                                  child: Icon(Icons.close_rounded, size: 14, color: AppColors.primary.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEquipmentPicker(Set<EquipmentType> selectedTypes, List<UserEquipmentData> currentEquipment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'Select Equipment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: AppColors.surfaceVariantDark),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: EquipmentType.values.length,
                      itemBuilder: (ctx, index) {
                        final type = EquipmentType.values[index];
                        final isSelected = selectedTypes.contains(type);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            _toggleEquipment(type, value ?? false, currentEquipment);
                            setSheetState(() {
                              if (value ?? false) {
                                selectedTypes.add(type);
                              } else {
                                selectedTypes.remove(type);
                              }
                            });
                          },
                          title: Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? AppColors.textPrimaryDark : AppColors.textSecondaryDark,
                            ),
                          ),
                          secondary: Icon(
                            _equipmentIcon(type),
                            size: 20,
                            color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                          ),
                          activeColor: AppColors.primary,
                          checkColor: AppColors.onPrimary,
                          controlAffinity: ListTileControlAffinity.trailing,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEquipmentTile(
    EquipmentType type,
    bool isSelected,
    List<UserEquipmentData> currentEquipment,
  ) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) => _toggleEquipment(type, value ?? false, currentEquipment),
      title: Text(
        type.displayName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? AppColors.textPrimaryDark : AppColors.textSecondaryDark,
        ),
      ),
      secondary: Icon(
        _equipmentIcon(type),
        size: 20,
        color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
      ),
      activeColor: AppColors.primary,
      checkColor: AppColors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  IconData _equipmentIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.bodyOnly:
        return Icons.accessibility_new_rounded;
      case EquipmentType.machine:
        return Icons.precision_manufacturing_rounded;
      case EquipmentType.dumbbell:
        return Icons.fitness_center_rounded;
      case EquipmentType.barbell:
        return Icons.fitness_center;
      case EquipmentType.kettlebells:
        return Icons.sports_martial_arts_rounded;
      case EquipmentType.cable:
        return Icons.cable_rounded;
      case EquipmentType.bands:
        return Icons.straighten_rounded;
      case EquipmentType.medicineBall:
        return Icons.sports_baseball_rounded;
      case EquipmentType.exerciseBall:
        return Icons.circle_outlined;
      case EquipmentType.ezCurlBar:
        return Icons.linear_scale_rounded;
      case EquipmentType.foamRoll:
        return Icons.roller_shades_rounded;
      case EquipmentType.other:
        return Icons.more_horiz_rounded;
    }
  }

  // ─── Backup & Restore Card ─────────────────────────────────────────────
  Widget _buildBackupCard() {
    final backupState = ref.watch(backupServiceProvider);
    final backupService = ref.read(backupServiceProvider.notifier);

    // Format last backup info
    String lastBackupText = 'No backups yet';
    if (backupState.lastBackupDate != null) {
      final date = DateTime.tryParse(backupState.lastBackupDate!);
      if (date != null) {
        final now = DateTime.now();
        final diff = now.difference(date);
        if (diff.inMinutes < 1) {
          lastBackupText = 'Just now';
        } else if (diff.inHours < 1) {
          lastBackupText = '${diff.inMinutes}m ago';
        } else if (diff.inDays < 1) {
          lastBackupText = '${diff.inHours}h ago';
        } else if (diff.inDays == 1) {
          lastBackupText = 'Yesterday';
        } else {
          lastBackupText = DateFormat('MMM d, yyyy').format(date);
        }
        if (backupState.lastBackupSize != null) {
          lastBackupText += '  •  ${backupState.lastBackupSize}';
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: AppColors.surfaceVariantDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.backup_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Backup & Restore',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastBackupText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.surfaceVariantDark),

          // Progress indicator when backing up / restoring
          if (backupState.isBackingUp || backupState.isRestoring)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        backupState.isBackingUp ? 'Creating backup...' : 'Restoring...',
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: backupState.progress > 0 ? backupState.progress : null,
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceVariantDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),

          // Error message
          if (backupState.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        backupState.error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Backup Now + Export row
                Row(
                  children: [
                    Expanded(
                      child: _buildBackupActionButton(
                        icon: Icons.save_rounded,
                        label: 'Backup Now',
                        onTap: backupState.isBackingUp || backupState.isRestoring
                            ? null
                            : () async {
                                final path = await backupService.createBackup();
                                if (path != null && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Backup created successfully'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildBackupActionButton(
                        icon: Icons.upload_file_rounded,
                        label: 'Export',
                        onTap: backupState.isBackingUp || backupState.isRestoring
                            ? null
                            : () => backupService.exportBackup(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Import row
                SizedBox(
                  width: double.infinity,
                  child: _buildBackupActionButton(
                    icon: Icons.download_rounded,
                    label: 'Import Backup',
                    onTap: backupState.isBackingUp || backupState.isRestoring
                        ? null
                        : () => _importBackup(backupService),
                  ),
                ),
                const SizedBox(height: 14),
                // Auto-backup toggle
                _buildAutoBackupToggle(backupService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.surfaceVariantDark.withOpacity(0.3)
                : AppColors.surfaceVariantDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceVariantDark),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDisabled ? AppColors.textMutedDark : AppColors.textSecondaryDark,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? AppColors.textMutedDark : AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoBackupToggle(BackupService backupService) {
    return FutureBuilder<bool>(
      future: backupService.isAutoBackupEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? true;
        return Row(
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: AppColors.textSecondaryDark),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Daily auto-backup',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
            SizedBox(
              height: 24,
              child: Switch(
                value: isEnabled,
                onChanged: (value) async {
                  await backupService.setAutoBackupEnabled(value);
                  setState(() {});
                },
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withOpacity(0.3),
                inactiveThumbColor: AppColors.textMutedDark,
                inactiveTrackColor: AppColors.surfaceVariantDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importBackup(BackupService backupService) async {
    // Confirm restore
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Restore Backup',
            style: TextStyle(color: AppColors.textPrimaryDark)),
        content: const Text(
          'This will replace all current data with the backup. A safety copy of your current data will be saved. Continue?',
          style: TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.single.path;
    if (filePath == null) return;

    // Validate it's a .db file
    if (!filePath.endsWith('.db')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a .db backup file'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    final success = await backupService.restoreFromFile(filePath);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup restored. Please restart the app for changes to take effect.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Restore failed. Your data is unchanged.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ─── Backup & Restore Card ─────────────────────────────────────────────
  Widget _buildBackupCard() {
    final backupState = ref.watch(backupServiceProvider);
    final backupService = ref.read(backupServiceProvider.notifier);

    // Format last backup info
    String lastBackupText = 'No backups yet';
    if (backupState.lastBackupDate != null) {
      final date = DateTime.tryParse(backupState.lastBackupDate!);
      if (date != null) {
        final now = DateTime.now();
        final diff = now.difference(date);
        if (diff.inMinutes < 1) {
          lastBackupText = 'Just now';
        } else if (diff.inHours < 1) {
          lastBackupText = '${diff.inMinutes}m ago';
        } else if (diff.inDays < 1) {
          lastBackupText = '${diff.inHours}h ago';
        } else if (diff.inDays == 1) {
          lastBackupText = 'Yesterday';
        } else {
          lastBackupText = DateFormat('MMM d, yyyy').format(date);
        }
        if (backupState.lastBackupSize != null) {
          lastBackupText += '  •  ${backupState.lastBackupSize}';
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: AppColors.surfaceVariantDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecora