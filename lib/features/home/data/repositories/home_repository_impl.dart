import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../../../booking/domain/entities/city_entity.dart';
import '../../../booking/domain/entities/university_entity.dart';
import '../../../booking/domain/entities/station_entity.dart';
import '../../../booking/domain/entities/route_entity.dart';
import '../../../booking/domain/entities/schedule_entity.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CityEntity>>> getCities() async {
    try {
      final cities = await remoteDataSource.getCities();
      return Right(cities);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UniversityEntity>>> getUniversities(
    String cityId,
  ) async {
    try {
      final universities = await remoteDataSource.getUniversities(cityId);
      return Right(universities);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StationEntity>>> getStations(
    String cityId, // Changed from universityId to cityId
  ) async {
    try {
      final stations = await remoteDataSource.getStations(
        cityId,
      ); // Changed from universityId to cityId
      return Right(stations);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RouteEntity>>> getRoutes(
    String universityId,
  ) async {
    try {
      final routes = await remoteDataSource.getRoutes(universityId);
      return Right(routes);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules(
    String routeId,
  ) async {
    try {
      final schedules = await remoteDataSource.getSchedules(routeId);
      return Right(schedules);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StationEntity>>> getAllStations() async {
    try {
      final stations = await remoteDataSource.getAllStations();
      return Right(stations);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UniversityEntity>>> getAllUniversities() async {
    try {
      final universities = await remoteDataSource.getAllUniversities();
      return Right(universities);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
