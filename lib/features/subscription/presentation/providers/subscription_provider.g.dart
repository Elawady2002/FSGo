// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionDataSourceHash() =>
    r'04e0aba5726739867015028daa9766585d456fc2';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubscriptionDataSourceRef =
    AutoDisposeProviderRef<SubscriptionDataSource>;
String _$subscriptionRepositoryHash() =>
    r'd271e4c14fa11776665a57d9121eeb92ff0fd0aa';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubscriptionRepositoryRef =
    AutoDisposeProviderRef<SubscriptionRepository>;
String _$userSubscriptionsHash() => r'd84a008c8ae24742c8f07fee9e5c868dcd6dbb76';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserSubscriptionsRef =
    AutoDisposeFutureProviderRef<List<SubscriptionEntity>>;
String _$activeSubscriptionHash() =>
    r'35102edbf478748805d0e06ddb35ecb9c0a69799';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveSubscriptionRef =
    AutoDisposeFutureProviderRef<SubscriptionEntity?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
