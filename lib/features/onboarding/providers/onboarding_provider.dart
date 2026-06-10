import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/onboarding_service.dart';

/// Provider that reads whether onboarding has been completed.
final isOnboardingCompletedProvider = FutureProvider<bool>((ref) {
  return OnboardingService().isCompleted();
});

/// Provider for the user's selected investment style during onboarding.
final investmentStyleProvider = StateProvider<String?>((ref) => null);
