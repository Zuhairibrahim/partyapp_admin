import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Shows an elegant, centered, gold-accented confirmation box that
/// auto-dismisses after ~2.2 seconds. Used after "حجز الآن" (added to the
/// cart) and after "تأكيد كل الحجوزات" (requests sent).
Future<void> showLuxuryToast(
  BuildContext context,
  String message, {
  String? title,
  IconData? icon,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) => _LuxuryToastBox(
      message: message,
      title: title,
      icon: icon,
    ),
  );
}

class _LuxuryToastBox extends StatefulWidget {
  final String message;
  final String? title;
  final IconData? icon;

  const _LuxuryToastBox({required this.message, this.title, this.icon});

  @override
  State<_LuxuryToastBox> createState() => _LuxuryToastBoxState();
}

class _LuxuryToastBoxState extends State<_LuxuryToastBox> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'تمت العملية بنجاح';
    final icon = widget.icon ?? Icons.check_rounded;
    return Center(
      // Outer wrapper draws a golden gradient frame around the card.
      child: Container(
        width: 286,
        padding: const EdgeInsets.all(1.4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightGold,
              AppColors.primaryGold,
              AppColors.lightGold,
              AppColors.primaryGold,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 34,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.primaryGold.withValues(alpha: 0.32),
              blurRadius: 28,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF232936), AppColors.cardDark],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ToastOrnament(),
              const SizedBox(height: 18),
              // Gold confirmation badge with inner double ring + glow.
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryGold.withValues(alpha: 0.35),
                      AppColors.primaryGold.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.9),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.lightGold.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                    ),
                    Icon(icon, color: AppColors.primaryGold, size: 26),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.5),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delicate gold ornament: a short line, a diamond dot, and a short line.
class _ToastOrnament extends StatelessWidget {
  const _ToastOrnament();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ornamentLine(begin: Alignment.centerRight, end: Alignment.centerLeft),
        const SizedBox(width: 7),
        Container(
          width: 5,
          height: 5,
          transform: Matrix4.rotationZ(0.7853982),
          decoration: BoxDecoration(
            color: AppColors.primaryGold,
            border: Border.all(
              color: AppColors.lightGold,
              width: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 7),
        _ornamentLine(begin: Alignment.centerLeft, end: Alignment.centerRight),
      ],
    );
  }

  Widget _ornamentLine({
    required AlignmentGeometry begin,
    required AlignmentGeometry end,
  }) {
    return Container(
      width: 26,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [
            AppColors.primaryGold.withValues(alpha: 0.0),
            AppColors.primaryGold.withValues(alpha: 0.9),
          ],
        ),
      ),
    );
  }
}