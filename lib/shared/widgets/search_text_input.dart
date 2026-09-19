import 'package:flutter/material.dart';

import '../../theme/app_colours.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_style.dart';

class SearchTextInput extends StatelessWidget {
  const SearchTextInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 20),

          SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Text(
              'Search characters',
              style: AppTextStyles.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
