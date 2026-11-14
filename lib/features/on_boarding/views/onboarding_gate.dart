import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rickipedia/features/character/views/characters_page.dart';
import 'package:rickipedia/features/on_boarding/providers/onboarding_provider.dart';
import 'package:rickipedia/features/on_boarding/views/on_boarding_page.dart';
import 'package:rickipedia/shared/widgets/primary_button.dart';
import 'package:rickipedia/theme/app_spacing.dart';

class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key});

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  bool _isSaving = false;

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not save your progress.Please try again"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);
    return onboarding.when(
      data: (isCompleted) {
        if(isCompleted){
          return CharactersPage();}
        return OnboardingPage(onCompleted: _completeOnboarding);
      },
      error: (error, stackTrace) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Could not load your preferences",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: "Retry",
                  onPressed: () {
                    return ref.invalidate(onboardingProvider);
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
