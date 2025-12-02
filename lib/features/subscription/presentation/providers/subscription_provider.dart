import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../data/datasources/subscription_data_source.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/subscription_repository_impl.dart';

part 'subscription_provider.g.dart';

@riverpod
SubscriptionDataSource subscriptionDataSource(SubscriptionDataSourceRef ref) {
  return SubscriptionDataSourceImpl(Supabase.instance.client);
}

@riverpod
SubscriptionRepository subscriptionRepository(SubscriptionRepositoryRef ref) {
  final dataSource = ref.watch(subscriptionDataSourceProvider);
  return SubscriptionRepositoryImpl(dataSource);
}

// User Subscriptions Provider (all subscriptions)
@riverpod
Future<List<SubscriptionEntity>> userSubscriptions(
  UserSubscriptionsRef ref,
) async {
  final user = ref.watch(authProvider);
  if (user == null) return [];

  final repository = ref.watch(subscriptionRepositoryProvider);
  final result = await repository.getUserSubscriptions(user.id);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (subscriptions) => subscriptions,
  );
}

// Active Subscription Provider (current active subscription)
@riverpod
Future<SubscriptionEntity?> activeSubscription(
  ActiveSubscriptionRef ref,
) async {
  final subscriptions = await ref.watch(userSubscriptionsProvider.future);

  // Find the first active or pending subscription
  try {
    print(
      'DEBUG: Filtering ${subscriptions.length} subscriptions for active/pending',
    );
    final activeSub = subscriptions.firstWhere((sub) {
      final isActiveOrPending =
          sub.status == SubscriptionStatus.active ||
          sub.status == SubscriptionStatus.pending;
      final isNotExpired = sub.endDate.isAfter(DateTime.now());
      print(
        'DEBUG: Sub ${sub.id}: Status=${sub.status}, End=${sub.endDate}, Active/Pending=$isActiveOrPending, NotExpired=$isNotExpired',
      );
      return isActiveOrPending && isNotExpired;
    });
    print('DEBUG: Found active subscription: ${activeSub.id}');
    return activeSub;
  } catch (e) {
    print('DEBUG: No active subscription found: $e');
    return null;
  }
}
