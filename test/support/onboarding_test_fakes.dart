import 'dart:async';

import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/providers/character_controller.dart';
import 'package:rickipedia/features/on_boarding/repositories/onboarding_repository.dart';

class ControlledOnboardingRepository implements OnboardingRepository {
  bool completed = false;
  bool failRead = false;
  bool failSave = false;
  int readCalls = 0;
  int saveCalls = 0;
  Completer<bool>? pendingRead;
  Completer<void>? pendingSave;

  @override
  Future<bool> isCompleted() async {
    readCalls++;
    if (failRead) throw StateError('Read failed');
    final pending = pendingRead;
    if (pending != null) return pending.future;
    return completed;
  }

  @override
  Future<void> complete() async {
    saveCalls++;
    if (failSave) throw StateError('Save failed');
    final pending = pendingSave;
    if (pending != null) await pending.future;
    completed = true;
  }
}

class EmptyOnboardingCharacterController extends CharacterController {
  @override
  Future<CharacterResponse> build() async => CharacterResponse(
    count: 0,
    pages: 1,
    next: null,
    prev: null,
    characters: [],
  );
}
