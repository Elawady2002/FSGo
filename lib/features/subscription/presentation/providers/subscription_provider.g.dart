// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionDataSourceHash() =>
    r'32581cc664940b74bae60e366ac2203288a1bd15';

/// See also [subscriptionDataSource].
@ProviderFor(subscriptionDataSource)
final subscriptionDataSourceProvider =
    AutoDisposeProvider<SubscriptionDataSource>.internal(
  subscriptionDataSource,
  name: r'subscriptionDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionDataSourceRef
    = AutoDisposeProviderRef<SubscriptionDataSource>;
String _$subscriptionRepositoryHash() =>
    r'cf97877f8e511c6b0c249c9982c666f1cdb819f0';

/// See also [subscriptionRepository].
@ProviderFor(subscriptionRepository)
final subscriptionRepositoryProvider =
    AutoDisposeProvider<SubscriptionRepository>.internal(
  subscriptionRepository,
  name: r'subscriptionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionRepositoryRef
    = AutoDisposeProviderRef<SubscriptionRepository>;
String _$userSubscriptionsHash() => r'9498cc8e44990966333645874e3a91ff2ea98d4f';

/// See also [userSubscriptions].
@ProviderFor(userSubscriptions)
final userSubscriptionsProvider =
    AutoDisposeFutureProvider<List<SubscriptionEntity>>.internal(
  userSubscriptions,
  name: r'userSubscriptionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userSubscriptionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserSubscriptionsRef
    = AutoDisposeFutureProviderRef<List<SubscriptionEntity>>;
String _$activeSubscriptionHash() =>
    r'80bf5118c7d446a8d51092bdf8a84720bb26f3be';

/// See also [activeSubscription].
@ProviderFor(activeSubscription)
final activeSubscriptionProvider =
    AutoDisposeFutureProvider<SubscriptionEntity?>.internal(
  activeSubscription,
  name: r'activeSubscriptionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSubscriptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveSubscriptionRef
    = AutoDisposeFutureProviderRef<SubscriptionEntity?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
