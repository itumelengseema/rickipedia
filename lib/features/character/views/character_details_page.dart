import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rickipedia/features/character/models/character_model.dart';
import 'package:rickipedia/theme/app_colours.dart';
import 'package:rickipedia/theme/app_spacing.dart';
import 'package:rickipedia/theme/app_text_style.dart';

class CharacterDetailsPage extends ConsumerWidget {
  const CharacterDetailsPage({super.key, required this.character});

  Color get statusColor {
    switch (character.status.toLowerCase()) {
      case 'alive':
        return Colors.green;
      case 'dead':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(character.name), centerTitle: true),
      body: Column(
        children: [
          SizedBox(
            width: 330,
            child: ClipRRect(
              borderRadius: .circular(20.0),
              child: CachedNetworkImage(
                imageUrl: character.image,
                fit: BoxFit.contain,
                placeholder: (context, url) {
                  return const Center(child: CircularProgressIndicator());
                },
                errorWidget: (context, url, error) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: AppSpacing.xxl,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 0.0,
                  horizontal: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(character.name, style: AppTextStyles.headingLarge),
                    Row(
                      children: [
                        Container(
                          width: AppSpacing.md,
                          height: AppSpacing.md,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          character.status,
                          style: AppTextStyles.productTitle,
                        ),
                      ],
                    ),
                    Text(character.species, style: AppTextStyles.body),
                  ],
                ),
              ),
            ],
          ),

          //About
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [Text('About', style: AppTextStyles.headingMedium)],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Species:"),
                    SizedBox(width: AppSpacing.sm),
                    Text(character.species, style: AppTextStyles.productTitle),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Gender:"),
                    SizedBox(width: AppSpacing.sm),
                    Text(character.gender, style: AppTextStyles.productTitle),
                  ],
                ),
              ],
            ),
          ),

          //Episodes
        ],
      ),
    );
  }
}
