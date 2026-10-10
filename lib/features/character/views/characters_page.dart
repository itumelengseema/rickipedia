import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rickipedia/features/character/providers/character_controller.dart';
import 'package:rickipedia/features/character/providers/pagination_provider.dart';
import 'package:rickipedia/features/character/views/character_search_page.dart';
import 'package:rickipedia/shared/widgets/character_card.dart';
import 'package:rickipedia/shared/widgets/primary_button.dart';
import 'package:rickipedia/shared/widgets/search_text_input.dart';
import 'package:rickipedia/theme/app_colours.dart';
import 'package:rickipedia/theme/app_spacing.dart';
import 'package:rickipedia/theme/app_text_style.dart';

class CharactersPage extends ConsumerStatefulWidget {
  const CharactersPage({super.key});

  @override
  ConsumerState<CharactersPage> createState() => _CharactersPageState();
}

class _CharactersPageState extends ConsumerState<CharactersPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearBottom);
  }

  void _loadMoreNearBottom() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.extentAfter < 300) {
      ref.read(characterControllerProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMoreNearBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _showPaginationErrorSnackBar() {
    final messenger = ScaffoldMessenger.of(context);

    // Remove existing snackbars so messages do not build up.
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text("Couldn't load more characters. Please try again."),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            ref.read(characterControllerProvider.notifier).loadNextPage();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final characterState = ref.watch(characterControllerProvider);
    final paginationState = ref.watch(paginationStateProvider);

    ref.listen(paginationStateProvider, (previous, next) {
      final requestFinished = previous?.isLoading == true && !next.isLoading;

      if (requestFinished && next.error != null) {
        _showPaginationErrorSnackBar();
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.black,
        backgroundColor: AppColors.surface,
        onRefresh: () {
          ScaffoldMessenger.of(context).clearSnackBars();

          return ref.read(characterControllerProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.white,
              surfaceTintColor: AppColors.white,
              elevation: 0,
              floating: true,
              snap: true,
              pinned: false,
              expandedHeight: 160,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Rickipedia",
                              style: AppTextStyles.headingLarge,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.person,
                                    size: AppSpacing.xl,
                                    color: AppColors.black,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: AppSpacing.xl,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return const CharacterSearchPage();
                                },
                              ),
                            );
                          },
                          child: const SearchTextInput(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Character loading, error and success states
            characterState.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),

              error: (error, stackTrace) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: AppSpacing.sm),
                      const Text('Failed to load characters'),
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryButton(
                        label: 'Retry',
                        onPressed: () {
                          ref
                              .read(characterControllerProvider.notifier)
                              .retry();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              data: (response) {
                if (response.characters.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No characters found')),
                  );
                }

                return SliverMainAxisGroup(
                  slivers: [
                    // Character grid
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final character = response.characters[index];

                          return CharacterCard(character: character);
                        }, childCount: response.characters.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.72,
                            ),
                      ),
                    ),

                    // Pagination loading indicator
                    if (paginationState.isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
