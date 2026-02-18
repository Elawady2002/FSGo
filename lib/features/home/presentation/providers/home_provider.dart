import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../booking/domain/entities/city_entity.dart';
import '../../../booking/domain/entities/university_entity.dart';
import '../../../booking/domain/entities/station_entity.dart';
import '../../../booking/domain/entities/route_entity.dart';
import '../../../booking/domain/entities/schedule_entity.dart';

part 'home_provider.g.dart';

@riverpod
HomeRemoteDataSource homeRemoteDataSource(Ref ref) {
  return HomeRemoteDataSourceImpl(Supabase.instance.client);
}

@riverpod
HomeRepository homeRepository(Ref ref) {
  final remoteDataSource = ref.watch(homeRemoteDataSourceProvider);
  return HomeRepositoryImpl(remoteDataSource: remoteDataSource);
}

@riverpod
Future<List<CityEntity>> cities(Ref ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final result = await repository.getCities();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (cities) => cities,
  );
}

@riverpod
Future<List<UniversityEntity>> universities(Ref ref, String cityId) async {
  final repository = ref.watch(homeRepositoryProvider);
  final result = await repository.getUniversities(cityId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (universities) => universities,
  );
}

@riverpod
Future<List<StationEntity>> stations(
  Ref ref,
  String cityId, // Changed from universityId to cityId
) async {
  final repository = ref.watch(homeRepositoryProvider);
  final result = await repository.getStations(
    cityId,
  ); // Changed from universityId to cityId
  return result.fold(
    (failure) => throw Exception(failure.message),
    (stations) => stations,
  );
}

@riverpod
Future<List<RouteEntity>> routes(Ref ref, String? universityId) async {
  if (universityId == null) {
    // Return a default route for station-based trips for now
    return [
      RouteEntity(
        id: '00000000-0000-0000-0000-000000000010',
        universityId: 'station-to-station',
        routeNameAr: 'من موقف لموقف',
        routeNameEn: 'Station to Station',
        routeCode: 'SS001',
        stationsOrder: const [],
        isActive: true,
      ),
    ];
  }

  final repository = ref.watch(homeRepositoryProvider);
  final result = await repository.getRoutes(universityId);

  final routes = result.fold((failure) => <RouteEntity>[], (routes) => routes);

  if (routes.isEmpty) {
    return [
      RouteEntity(
        id: '00000000-0000-0000-0000-000000000001',
        universityId: universityId,
        routeNameAr: 'خط افتراضي',
        routeNameEn: 'Default Route',
        routeCode: 'DR001',
        stationsOrder: const [],
        isActive: true,
      ),
    ];
  }

  return routes;
}

@riverpod
Future<List<ScheduleEntity>> schedules(Ref ref, String routeId) async {
  final repository = ref.watch(homeRepositoryProvider);
  final result = await repository.getSchedules(routeId);

  final schedules = result.fold(
    (failure) => <ScheduleEntity>[],
    (schedules) => schedules,
  );

  // Add fake schedules for testing as requested by user
  if (schedules.isEmpty) {
    return [
      ScheduleEntity(
        id: '00000000-0000-0000-0000-000000000007',
        routeId: routeId,
        direction: RouteDirection.toUniversity,
        departureTime: '07:00',
        availableDays: const [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ],
        capacity: 15,
        pricePerTrip: 45,
        isActive: true,
      ),
      ScheduleEntity(
        id: '00000000-0000-0000-0000-000000000008',
        routeId: routeId,
        direction: RouteDirection.toUniversity,
        departureTime: '07:30',
        availableDays: const [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ],
        capacity: 15,
        pricePerTrip: 45,
        isActive: true,
      ),
      ScheduleEntity(
        id: '00000000-0000-0000-0000-000000000009',
        routeId: routeId,
        direction: RouteDirection.toUniversity,
        departureTime: '08:00',
        availableDays: const [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ],
        capacity: 15,
        pricePerTrip: 45,
        isActive: true,
      ),
      // Return schedules
      ScheduleEntity(
        id: '00000000-0000-0000-0000-000000000015',
        routeId: routeId,
        direction: RouteDirection.fromUniversity,
        departureTime: '15:00',
        availableDays: const [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ],
        capacity: 15,
        pricePerTrip: 45,
        isActive: true,
      ),
      ScheduleEntity(
        id: '00000000-0000-0000-0000-000000000016',
        routeId: routeId,
        direction: RouteDirection.fromUniversity,
        departureTime: '16:00',
        availableDays: const [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ],
        capacity: 15,
        pricePerTrip: 45,
        isActive: true,
      ),
    ];
  }

  return schedules;
}
@riverpod
Future<List<StationEntity>> allStations(Ref ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final result = await repository.getAllStations();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (stations) => stations,
  );
}

@riverpod
Future<List<UniversityEntity>> allUniversities(Ref ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final result = await repository.getAllUniversities();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (universities) => universities,
  );
}
