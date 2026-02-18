// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeRemoteDataSourceHash() =>
    r'00ffca707b01b1aa52fe70cd6c68cca3b876b2e1';

/// See also [homeRemoteDataSource].
@ProviderFor(homeRemoteDataSource)
final homeRemoteDataSourceProvider =
    AutoDisposeProvider<HomeRemoteDataSource>.internal(
      homeRemoteDataSource,
      name: r'homeRemoteDataSourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$homeRemoteDataSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeRemoteDataSourceRef = AutoDisposeProviderRef<HomeRemoteDataSource>;
String _$homeRepositoryHash() => r'6fc01a1657a74331472ffd92897fc9c841e2bfff';

/// See also [homeRepository].
@ProviderFor(homeRepository)
final homeRepositoryProvider = AutoDisposeProvider<HomeRepository>.internal(
  homeRepository,
  name: r'homeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeRepositoryRef = AutoDisposeProviderRef<HomeRepository>;
String _$citiesHash() => r'2bc1b4071b8391788f88bdfc7084868dfd19cbf6';

/// See also [cities].
@ProviderFor(cities)
final citiesProvider = AutoDisposeFutureProvider<List<CityEntity>>.internal(
  cities,
  name: r'citiesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$citiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CitiesRef = AutoDisposeFutureProviderRef<List<CityEntity>>;
String _$universitiesHash() => r'2e3ecad12a513c9645fc8cd7af6a96bc16c1ffa9';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [universities].
@ProviderFor(universities)
const universitiesProvider = UniversitiesFamily();

/// See also [universities].
class UniversitiesFamily extends Family<AsyncValue<List<UniversityEntity>>> {
  /// See also [universities].
  const UniversitiesFamily();

  /// See also [universities].
  UniversitiesProvider call(String cityId) {
    return UniversitiesProvider(cityId);
  }

  @override
  UniversitiesProvider getProviderOverride(
    covariant UniversitiesProvider provider,
  ) {
    return call(provider.cityId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'universitiesProvider';
}

/// See also [universities].
class UniversitiesProvider
    extends AutoDisposeFutureProvider<List<UniversityEntity>> {
  /// See also [universities].
  UniversitiesProvider(String cityId)
    : this._internal(
        (ref) => universities(ref as UniversitiesRef, cityId),
        from: universitiesProvider,
        name: r'universitiesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$universitiesHash,
        dependencies: UniversitiesFamily._dependencies,
        allTransitiveDependencies:
            UniversitiesFamily._allTransitiveDependencies,
        cityId: cityId,
      );

  UniversitiesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.cityId,
  }) : super.internal();

  final String cityId;

  @override
  Override overrideWith(
    FutureOr<List<UniversityEntity>> Function(UniversitiesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UniversitiesProvider._internal(
        (ref) => create(ref as UniversitiesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        cityId: cityId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<UniversityEntity>> createElement() {
    return _UniversitiesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UniversitiesProvider && other.cityId == cityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, cityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UniversitiesRef on AutoDisposeFutureProviderRef<List<UniversityEntity>> {
  /// The parameter `cityId` of this provider.
  String get cityId;
}

class _UniversitiesProviderElement
    extends AutoDisposeFutureProviderElement<List<UniversityEntity>>
    with UniversitiesRef {
  _UniversitiesProviderElement(super.provider);

  @override
  String get cityId => (origin as UniversitiesProvider).cityId;
}

String _$stationsHash() => r'd6d4901cd4fd1dfbbdacff297a041dc1aed39afc';

/// See also [stations].
@ProviderFor(stations)
const stationsProvider = StationsFamily();

/// See also [stations].
class StationsFamily extends Family<AsyncValue<List<StationEntity>>> {
  /// See also [stations].
  const StationsFamily();

  /// See also [stations].
  StationsProvider call(String cityId) {
    return StationsProvider(cityId);
  }

  @override
  StationsProvider getProviderOverride(covariant StationsProvider provider) {
    return call(provider.cityId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'stationsProvider';
}

/// See also [stations].
class StationsProvider extends AutoDisposeFutureProvider<List<StationEntity>> {
  /// See also [stations].
  StationsProvider(String cityId)
    : this._internal(
        (ref) => stations(ref as StationsRef, cityId),
        from: stationsProvider,
        name: r'stationsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$stationsHash,
        dependencies: StationsFamily._dependencies,
        allTransitiveDependencies: StationsFamily._allTransitiveDependencies,
        cityId: cityId,
      );

  StationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.cityId,
  }) : super.internal();

  final String cityId;

  @override
  Override overrideWith(
    FutureOr<List<StationEntity>> Function(StationsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StationsProvider._internal(
        (ref) => create(ref as StationsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        cityId: cityId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StationEntity>> createElement() {
    return _StationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StationsProvider && other.cityId == cityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, cityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StationsRef on AutoDisposeFutureProviderRef<List<StationEntity>> {
  /// The parameter `cityId` of this provider.
  String get cityId;
}

class _StationsProviderElement
    extends AutoDisposeFutureProviderElement<List<StationEntity>>
    with StationsRef {
  _StationsProviderElement(super.provider);

  @override
  String get cityId => (origin as StationsProvider).cityId;
}

String _$routesHash() => r'4225e3185e23df4cbfae621444990fbc5e3dfbeb';

/// See also [routes].
@ProviderFor(routes)
const routesProvider = RoutesFamily();

/// See also [routes].
class RoutesFamily extends Family<AsyncValue<List<RouteEntity>>> {
  /// See also [routes].
  const RoutesFamily();

  /// See also [routes].
  RoutesProvider call(String? universityId) {
    return RoutesProvider(universityId);
  }

  @override
  RoutesProvider getProviderOverride(covariant RoutesProvider provider) {
    return call(provider.universityId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'routesProvider';
}

/// See also [routes].
class RoutesProvider extends AutoDisposeFutureProvider<List<RouteEntity>> {
  /// See also [routes].
  RoutesProvider(String? universityId)
    : this._internal(
        (ref) => routes(ref as RoutesRef, universityId),
        from: routesProvider,
        name: r'routesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$routesHash,
        dependencies: RoutesFamily._dependencies,
        allTransitiveDependencies: RoutesFamily._allTransitiveDependencies,
        universityId: universityId,
      );

  RoutesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.universityId,
  }) : super.internal();

  final String? universityId;

  @override
  Override overrideWith(
    FutureOr<List<RouteEntity>> Function(RoutesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RoutesProvider._internal(
        (ref) => create(ref as RoutesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        universityId: universityId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RouteEntity>> createElement() {
    return _RoutesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoutesProvider && other.universityId == universityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, universityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RoutesRef on AutoDisposeFutureProviderRef<List<RouteEntity>> {
  /// The parameter `universityId` of this provider.
  String? get universityId;
}

class _RoutesProviderElement
    extends AutoDisposeFutureProviderElement<List<RouteEntity>>
    with RoutesRef {
  _RoutesProviderElement(super.provider);

  @override
  String? get universityId => (origin as RoutesProvider).universityId;
}

String _$schedulesHash() => r'6b7a38efc46ea5819becbc9da827d648f87aa8c1';

/// See also [schedules].
@ProviderFor(schedules)
const schedulesProvider = SchedulesFamily();

/// See also [schedules].
class SchedulesFamily extends Family<AsyncValue<List<ScheduleEntity>>> {
  /// See also [schedules].
  const SchedulesFamily();

  /// See also [schedules].
  SchedulesProvider call(String routeId) {
    return SchedulesProvider(routeId);
  }

  @override
  SchedulesProvider getProviderOverride(covariant SchedulesProvider provider) {
    return call(provider.routeId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'schedulesProvider';
}

/// See also [schedules].
class SchedulesProvider
    extends AutoDisposeFutureProvider<List<ScheduleEntity>> {
  /// See also [schedules].
  SchedulesProvider(String routeId)
    : this._internal(
        (ref) => schedules(ref as SchedulesRef, routeId),
        from: schedulesProvider,
        name: r'schedulesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$schedulesHash,
        dependencies: SchedulesFamily._dependencies,
        allTransitiveDependencies: SchedulesFamily._allTransitiveDependencies,
        routeId: routeId,
      );

  SchedulesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.routeId,
  }) : super.internal();

  final String routeId;

  @override
  Override overrideWith(
    FutureOr<List<ScheduleEntity>> Function(SchedulesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SchedulesProvider._internal(
        (ref) => create(ref as SchedulesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        routeId: routeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ScheduleEntity>> createElement() {
    return _SchedulesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SchedulesProvider && other.routeId == routeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, routeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SchedulesRef on AutoDisposeFutureProviderRef<List<ScheduleEntity>> {
  /// The parameter `routeId` of this provider.
  String get routeId;
}

class _SchedulesProviderElement
    extends AutoDisposeFutureProviderElement<List<ScheduleEntity>>
    with SchedulesRef {
  _SchedulesProviderElement(super.provider);

  @override
  String get routeId => (origin as SchedulesProvider).routeId;
}

String _$allStationsHash() => r'c50d10649b9da60af2f832f13409ade5e60a7092';

/// See also [allStations].
@ProviderFor(allStations)
final allStationsProvider =
    AutoDisposeFutureProvider<List<StationEntity>>.internal(
      allStations,
      name: r'allStationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allStationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllStationsRef = AutoDisposeFutureProviderRef<List<StationEntity>>;
String _$allUniversitiesHash() => r'5ba3818d45c2283cb398226e66ace6741dd11df2';

/// See also [allUniversities].
@ProviderFor(allUniversities)
final allUniversitiesProvider =
    AutoDisposeFutureProvider<List<UniversityEntity>>.internal(
      allUniversities,
      name: r'allUniversitiesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allUniversitiesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllUniversitiesRef =
    AutoDisposeFutureProviderRef<List<UniversityEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
