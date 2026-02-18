import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../booking/domain/entities/city_entity.dart';
import '../../../booking/domain/entities/university_entity.dart';
import '../../../booking/domain/entities/station_entity.dart';
import '../../../booking/domain/entities/route_entity.dart';
import '../../../booking/domain/entities/schedule_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<CityEntity>>> getCities();
  Future<Either<Failure, List<UniversityEntity>>> getUniversities(
    String cityId,
  );
  Future<Either<Failure, List<StationEntity>>> getStations(
    String cityId,
  ); // Changed from universityId to cityId
  Future<Either<Failure, List<RouteEntity>>> getRoutes(String universityId);
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules(String routeId);
  Future<Either<Failure, List<StationEntity>>> getAllStations();
  Future<Either<Failure, List<UniversityEntity>>> getAllUniversities();
}
