import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/providers/app_providers.dart';
import 'services/gemma_model_service.dart';
import 'services/backup_service.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/exercises/exercises_screen.dart';
import 'presentation/screens/routines/routines_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/nutrition/nutrition_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set immersive system UI mode to prevent navbar from hiding
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(
    const ProviderScope(
      child: GymTrackApp(),
    ),
  );
}

class GymTrackApp extends ConsumerWidget {
  const GymTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(appInitializationProvider);

    return MaterialApp(
      title: 'GymTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      home: initialization.when(
        data: (_) => const HomePage(),
        loading: () => const _LoadingScreen(),
        error: (error, stack) => _ErrorScreen(
          error: error,
          onRetry: () => ref.invalidate(appInitializationProvider),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'GymTrack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Loading your workout data...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceVariantDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Error initializing app',
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
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController _pageController;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ExercisesScreen(),
    RoutinesScreen(),
    NutritionScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(currentTabProvider));
    // Eagerly initialize Gemma model service to restore model states from native
    ref.read(gemmaModelServiceProvider);
    // Run daily auto-backup check
    ref.read(backupServiceProvider.notifier).checkAndRunAutoBackup();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(currentTabProvider.notifier).state = index;
  }

  void _onTabTapped(int index) {
    ref.read(currentTabProvider.notifier).state = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(currentTabProvider);

    // Sync PageView when tab changes from outside (e.g. dashboard cards)
    if (_pageController.hasClients &&
        _pageController.page?.round() != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: _screens,
          ),
          // Floating navbar
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 10,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Row(
                children: [
                  _FloatingNavItem(
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => _onTabTapped(0),
                    isDark: isDark,
                  ),
                  _FloatingNavItem(
                    icon: Icons.fitness_center_outlined,
                    selectedIcon: Icons.fitness_center_rounded,
                    label: 'Exercises',
                    isSelected: currentIndex == 1,
                    onTap: () => _onTabTapped(1),
                    isDark: isDark,
                  ),
                  _FloatingNavItem(
                    icon: Icons.play_circle_outline_rounded,
                    selectedIcon: Icons.play_circle_rounded,
                    label: 'Workout',
                    isSelected: currentIndex == 2,
                    onTap: () => _onTabTapped(2),
                    isDark: isDark,
                    isPrimary: true,
                  ),
                  _FloatingNavItem(
                    icon: Icons.restaurant_outlined,
                    selectedIcon: Icons.restaurant_rounded,
                    label: 'Nutrition',
                    isSelected: currentIndex == 3,
                    onTap: () => _onTabTapped(3),
                    isDark: isDark,
                  ),
                  _FloatingNavItem(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: currentIndex == 4,
                    onTap: () => _onTabTapped(4),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool isPrimary;

  const _FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.textMutedDark : AppColors.textSecondary);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 44 : 36,
              height: isSelected ? 32 : 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: isSelected ? 22 : 20,
                color: activeColor,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 10 : 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: activeColor,
                letterSpacing: isSelected ? 0.1 : 0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
