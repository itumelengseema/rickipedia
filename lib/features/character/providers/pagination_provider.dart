import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rickipedia/features/character/models/pagination_state.dart';

class PaginationNotifier extends Notifier<PaginationState> {
  @override
  PaginationState build() {
    return const PaginationState();
  }

  void startLoading() {
    state = const PaginationState(isLoading: true);
  }

  void setError(Object error) {
    state = PaginationState(error: error);
  }

  void reset() {
    state = const PaginationState();
  }
}

final paginationStateProvider =
    NotifierProvider<PaginationNotifier, PaginationState>(
      PaginationNotifier.new,
    );
