import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/in_memory_subscription_access_repository.dart';
import '../../domain/models/account_context.dart';
import '../../domain/models/subscription_access.dart';
import '../../domain/repositories/subscription_access_repository.dart';

/// Provider for the SubscriptionAccessRepository instance.
final subscriptionAccessRepositoryProvider =
    Provider<SubscriptionAccessRepository>((ref) {
      return InMemorySubscriptionAccessRepository();
    });

/// StateProvider holding the active AccountContext (Individual vs School).
final currentAccountContextProvider = StateProvider<AccountContext>(
  (ref) => AccountContext.individual,
);

/// FutureProvider to fetch current user subscription access state.
final subscriptionAccessProvider =
    FutureProvider.family<SubscriptionAccess, String>((ref, userId) async {
      final repo = ref.watch(subscriptionAccessRepositoryProvider);
      final context = ref.watch(currentAccountContextProvider);
      return repo.getAccessState(userId: userId, context: context);
    });
