import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// A confirmation banner that auto-confirms after [autoConfirmSeconds].
/// Shows action text, a countdown progress bar, and Cancel / Confirm buttons.
class VoiceConfirmationCard extends StatefulWidget {
  final String actionText;
  final IconData icon;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final int autoConfirmSeconds;

  const VoiceConfirmationCard({
    super.key,
    required this.actionText,
    this.icon = Icons.mic_rounded,
    required this.onConfirm,
    required this.onCancel,
    this.autoConfirmSeconds = 3,
  });

  @override
  State<VoiceConfirmationCard> createState() => _VoiceConfirmationCardState();
}

class _VoiceConfirmationCardState extends State<VoiceConfirmationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _autoConfirmTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.autoConfirmSeconds),
    )..forward();

    _autoConfirmTimer = Timer(
      Duration(seconds: widget.autoConfirmSeconds),
      () {
        if (mounted) widget.onConfirm();
      },
    );
  }

  @override
  void dispose() {
    _autoConfirmTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (_, __) => LinearProgressIndicator(
                value: _progressController.value,
                minHeight: 3,
                backgroundColor: AppColors.surfaceVariantDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withOpacity(0.7),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),

                // Action text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voice Command',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.actionText,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Cancel button
                GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondaryDark,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Confirm button
                GestureDetector(
                  onTap: widget.onConfirm,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen listening overlay with pulsing mic and live transcript.
class VoiceListeningOverlay extends StatefulWidget {
  final String transcript;
  final bool isListening;
  final VoidCallback onCancel;
  final bool isSmartMode;

  const VoiceListeningOverlay({
    super.key,
    required this.transcript,
    required this.isListening,
    required this.onCancel,
    this.isSmartMode = false,
  });

  @override
  State<VoiceListeningOverlay> createState() => _VoiceListeningOverlayState();
}

class _VoiceListeningOverlayState extends State<VoiceListeningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundDark.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with cancel
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),

            // Outer pulse ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final outerScale = 1.0 + (_pulseController.value * 0.3);
                return Transform.scale(
                  scale: widget.isListening ? outerScale : 1.0,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(
                          widget.isListening ? 0.15 : 0.05,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Inner mic circle (overlaid on the pulse ring)
            Transform.translate(
              offset: const Offset(0, -130),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final innerScale = 1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: widget.isListening ? innerScale : 1.0,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                          width: 2.5,
                        ),
                      ),
                      child: Icon(
                        widget.isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                        color: AppColors.primary,
                        size: 52,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Offset for the overlapping circles
            Transform.translate(
              offset: const Offset(0, -110),
              child: Column(
                children: [
                  // Status
                  Text(
                    widget.isListening ? 'Listening...' : 'Processing...',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mode chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isSmartMode
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isSmartMode ? Icons.auto_awesome : Icons.text_fields_rounded,
                          color: widget.isSmartMode ? AppColors.primary : AppColors.textMutedDark,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.isSmartMode ? 'AI' : 'Basic',
                          style: TextStyle(
                            color: widget.isSmartMode ? AppColors.primary : AppColors.textMutedDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Live transcript
                  if (widget.transcript.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.format_quote_rounded, color: AppColors.primary.withOpacity(0.5), size: 18),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.transcript,
                              style: const TextStyle(
                                color: AppColors.textPrimaryDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }
}
