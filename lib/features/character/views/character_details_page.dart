import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rickipedia/features/character/models/character_model.dart';
import 'package:rickipedia/theme/app_colours.dart';
import 'package:rickipedia/theme/app_spacing.dart';
import 'package:rickipedia/theme/app_text_style.dart';

class CharacterDetailsPage extends StatelessWidget {
  const CharacterDetailsPage({super.key, required this.character});

  final Character character;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character details'), centerTitle: true),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: character.image,
                            fit: BoxFit.contain,
                            placeholder: (context, url) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
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
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text(character.name, style: AppTextStyles.headingLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Container(
                        width: AppSpacing.sm,
                        height: AppSpacing.sm,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          character.status,
                          style: AppTextStyles.productTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(character.species, style: AppTextStyles.body),
                  const SizedBox(height: AppSpacing.md),

                  _DetailsSection(
                    title: 'About',
                    child: Column(
                      children: [
                        _InfoRow(label: 'Species', value: character.species),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(label: 'Gender', value: character.gender),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(label: 'Origin', value: character.origin.name),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(
                          label: 'Current location',
                          value: character.location.name,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(label: 'Type', value: character.type),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _DetailsSection(
                    title: 'Episodes',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${character.episode.length}',
                          style: AppTextStyles.headingLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          character.episode.length == 1
                              ? 'appearance'
                              : 'appearances',
                          style: AppTextStyles.label,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.headingMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text('$label:', style: AppTextStyles.label)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 3,
          child: Text(
            value.trim().isEmpty ? 'Not specified' : value,
            style: AppTextStyles.productTitle,
          ),
        ),
      ],
    );
  }
}
