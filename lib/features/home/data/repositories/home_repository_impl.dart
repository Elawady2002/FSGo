import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../../../booking/domain/entities/city_entity.dart';
import '../../../booking/domain/entities/university_entity.dart';
import '../../../booking/domain/entities/boarding_station_entity.dart';
import '../../../booking/domain/entities/arrival_station_entity.dart';
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
  Future<Either<Failure, List<BoardingStationEntity>>> getBoardingStations(
    String cityId,
  ) async {
    try {
      final stations = await remoteDataSource.getBoardingStations(
        cityId,
      );
      return Right(stations);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ArrivalStationEntity>>> getArrivalStations(
    String boardingStationId,
  ) async {
    try {
      final stations = await remoteDataSource.getArrivalStations(
        boardingStationId,
      );
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
  Future<Either<Failure, List<BoardingStationEntity>>> getAllBoardingStations() async {
    try {
      final stations = await remoteDataSource.getAllBoardingStations();
      return Right(stations);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ArrivalStationEntity>>> getAllArrivalStations() async {
    try {
      final stations = await remoteDataSource.getAllArrivalStations();
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
