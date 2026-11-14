import 'package:flutter/material.dart';
import 'package:rickipedia/features/on_boarding/models/onboarding_items.dart';
import 'package:rickipedia/theme/app_spacing.dart';
import 'package:rickipedia/theme/app_text_style.dart';

class OnboardingSlide extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingSlide({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisAlignment: .center,
        children: [
          if (item.imageUrl.isNotEmpty)
            Image.asset(item.imageUrl, height: 240, fit: BoxFit.contain)
          else
            SizedBox(
              height: 240,
              child: Center(child: Icon(Icons.image_outlined, size: 100)),
            ),
          SizedBox(height: AppSpacing.xl),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLarge,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(item.description,textAlign: TextAlign.center,style: AppTextStyles.body,)
        ],
      ),
    );
  }
}
