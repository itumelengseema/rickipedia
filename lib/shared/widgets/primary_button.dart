import 'package:flutter/material.dart';
import 'package:rickipedia/theme/app_colours.dart';
import 'package:rickipedia/theme/app_spacing.dart';
import 'package:rickipedia/theme/app_text_style.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textSecondary,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary,
              ),
            )
          : Text(
              label,
              style: AppTextStyles.productTitle.copyWith(
                color: onPressed == null
                    ? AppColors.textSecondary
                    : AppColors.white,
              ),
            ),
    );
  }
}
