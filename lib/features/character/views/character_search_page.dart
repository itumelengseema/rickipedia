import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rickipedia/theme/app_colours.dart';
import 'package:rickipedia/theme/app_spacing.dart';
import 'package:rickipedia/theme/app_text_style.dart';

class CharacterSearchPage extends ConsumerStatefulWidget {
  const CharacterSearchPage({super.key});

  @override
  ConsumerState<CharacterSearchPage> createState() =>
      _CharacterSearchPageState();
}

class _CharacterSearchPageState extends ConsumerState<CharacterSearchPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            elevation: 0,
            floating: true,
            snap: true,
            pinned: false,
            expandedHeight: 110,
            title: const Text("Search"),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                controller: searchController,

                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Search Characters",
                                ),
                                style: AppTextStyles.body,
                              ),
                            ),

                            ValueListenableBuilder(
                              valueListenable: searchController,
                              builder: (context, value, child) {
                                if (value.text.isEmpty) {
                                  return SizedBox.shrink();
                                }
                                return IconButton(
                                  onPressed: searchController.clear,
                                  icon: Icon(Icons.clear, size: 20),
                                );
                              },
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
        ],
      ),
    );
  }
}
