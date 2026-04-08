import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/ai_workout_service.dart';
import '../../../services/gemma_model_service.dart';
import '../../widgets/animated_ai_gradient.dart';
import 'ai_results_screen.dart';

class AiGenerateScreen extends ConsumerStatefulWidget {
  const AiGenerateScreen({super.key});

  @override
  ConsumerState<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends ConsumerState<AiGenerateScreen>
    with SingleTickerProviderStateMixin {
  final _promptController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isGenerating = false;
  String? _error;
  String? _usedPrompt;
  String _streamedText = '';
  String _statusMessage = '';
  final _scrollController = ScrollController();

  late AnimationController _shimmerController;

  static const _suggestions = [
    '3-day full body for beginners',
    'Push Pull Legs for muscle gain',
    '5-day bodybuilding split',
    'Upper lower split, 4 days',
    'Home workout with dumbbells only',
    'Strength training for powerlifting',
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _focusNode.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generate(String prompt) async {
    if (prompt.trim().isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _isGenerating = true;
      _error = null;
      _usedPrompt = prompt.trim();
      _streamedText = '';
      _statusMessage = 'Initializing...';
    });
    _shimmerController.repeat();

    try {
      final service = ref.read(aiWorkoutServiceProvider);
      final routines = await service.generateWorkoutStreaming(
        prompt.trim(),
        onToken: (token) {
          if (!mounted) return;
          setState(() {
            _streamedText += token;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent);
            }
          });
        },
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _statusMessage = status;
          });
        },
      );
      if (!mounted) return;
      _shimmerController.stop();
      setState(() {
        _isGenerating = false;
      });

      // Navigate to results screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiResultsScreen(
            routines: routines,
            usedPrompt: _usedPrompt,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _shimmerController.stop();
      setState(() {
        _isGenerating = false;
        _error = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('FormatException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveModel = ref.watch(activeGemmaModelProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedAiGradient(
              width: 28,
              height: 28,
              borderRadius: BorderRadius.circular(7),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'AI Workout Generator',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !hasActiveModel
          ? _buildNoModelState()
          : Column(
              children: [
                Expanded(
                  child: _isGenerating
                      ? _buildGeneratingView()
                      : _error != null
                          ? _buildErrorView()
                          : _buildPromptView(),
                ),
                if (!_isGenerating) _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildNoModelState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedAiGradient(
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(20),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Model Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Download and activate an AI model in\nProfile \u2192 AI Workout Agent Models',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                AnimatedAiGradient(
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(14),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Describe your ideal workout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tell the AI your goals, schedule, and preferences.\nIt will create a complete workout split for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'QUICK PROMPTS',
            style: TextStyle(
              color: AppColors.textMutedDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _suggestions.map((s) => _buildSuggestionChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _promptController.text = text;
        _generate(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              focusNode: _focusNode,
              style: const TextStyle(
                  color: AppColors.textPrimaryDark, fontSize: 15),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: _generate,
              decoration: InputDecoration(
                hintText: 'e.g. "4-day split for muscle building"',
                hintStyle: const TextStyle(
                    color: AppColors.textMutedDark, fontSize: 14),
                filled: true,
                fillColor: AppColors.surfaceVariantDark,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _generate(_promptController.text),
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.send_rounded,
                    color: AppColors.onPrimary, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingView() {
    return ListenableBuilder(
      listenable: _shimmerController,
      builder: (context, _) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedAiGradient(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _streamedText.isEmpty
                                  ? _statusMessage
                                  : 'Generating...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        if (_usedPrompt != null)
                          Text(
                            '"$_usedPrompt"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMutedDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_streamedText.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: SelectableText(
                    _streamedText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFFB0D0B0),
                      height: 1.6,
                    ),
                  ),
                ),
              ] else ...[
                ...List.generate(3, (i) => _buildSkeletonCard(i)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard(int index) {
    final delay = index * 0.15;
    final opacity =
        (0.3 + (_shimmerController.value + delay) % 1.0 * 0.4).clamp(0.3, 0.7);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(opacity),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark.withOpacity(opacity)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color:
                          AppColors.surfaceVariantDark.withOpacity(opacity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariantDark
                          .withOpacity(opacity * 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Generation Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
