import 'package:flutter/material.dart';
import 'package:rickipedia/theme/app_spacing.dart';

class SearchResultsList<T> extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: AppSpacing.sm);
        },
        itemBuilder: (context, index) {
          return itemBuilder(context, items[index]);
        },
      ),
    );
  }
}
