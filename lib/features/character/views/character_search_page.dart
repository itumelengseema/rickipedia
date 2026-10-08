import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rickipedia/features/character/models/character_model.dart';
import 'package:rickipedia/features/character/providers/character_search_controller.dart';
import 'package:rickipedia/shared/widgets/search_results_list.dart';
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
    final searchState = ref.watch(characterSearchControllerProvider);

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
                                onChanged: (query) {
                                  ref
                                      .read(
                                        characterSearchControllerProvider
                                            .notifier,
                                      )
                                      .search(query);
                                },
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
                                  onPressed: () {
                                    searchController.clear();
                                    ref
                                        .read(
                                          characterSearchControllerProvider
                                              .notifier,
                                        )
                                        .search('');
                                  },
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
          searchState.when(
            loading: () {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            error: (error, stackTrace) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/server_failure.svg',
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text("Failed to search characters"),
                  ],
                ),
              );
            },
            data: (response) {
              if (response == null) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/searchImage.svg',
                        width: 150,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text("Search to find characters"),
                    ],
                  ),
                );
              }

              if (response.characters.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/notFound.svg',
                        width: 150,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text("No results found :("),
                    ],
                  ),
                );
              }

              return SearchResultsList<Character>(
                items: response.characters,
                itemBuilder: (context, character) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        character.image,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(character.name),
                    subtitle: Text(
                      '${character.species} • ${character.status}',
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
